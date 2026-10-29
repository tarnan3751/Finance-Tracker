// The Link controller over the in-app fake server and the fake launcher, on the
// in-memory repositories: linking (the exchange, the sync through not_ready, the pull),
// Link closed with and without an error, repairing with no exchange, syncing, unlinking,
// an Item the server says needs its login repaired, a sync that never completes, a rate
// limit, and one Link session at a time.
import 'dart:async';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/application/link_launcher_provider.dart';
import 'package:finance_tracker/features/items/data/fake_link_launcher.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:finance_tracker/features/items/domain/link_launcher.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';

FakeItemData _item(String id, String institution) => FakeItemData(
  id: id,
  institution: Institution(id: 'ins-$id', name: institution),
  accounts: [
    Account(
      id: '$id-checking',
      itemId: id,
      type: AccountType.depository,
      name: 'Checking',
      currencyCode: 'USD',
      isHidden: false,
      displayOrder: 0,
    ),
  ],
  transactions: [
    Transaction(
      id: '$id-t1',
      accountId: '$id-checking',
      amount: Money(-1250, 'USD'),
      date: LocalDate(2026, 10, 20),
      pending: false,
      name: 'Coffee',
      source: DataSource.demo,
      createdAt: DateTime.utc(2026, 10, 20, 12),
      updatedAt: DateTime.utc(2026, 10, 20, 12),
      syncVersion: 0,
    ),
  ],
);

void main() {
  late FakeServer server;
  late FakeLinkLauncher launcher;
  late ProviderContainer c;

  setUp(() {
    server = FakeServer(
      dataset: FakeDataset(
        items: [_item('item-a', 'Bank A'), _item('item-b', 'Bank B')],
      ),
      now: testClock.nowUtc,
    )..seedUser(email: demoEmail, password: demoPassword);
    launcher = FakeLinkLauncher(server);
    final Session session = server.seedSession(
      email: demoEmail,
      password: demoPassword,
    );
    c = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.prod()),
        clockProvider.overrideWithValue(testClock),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(
          InMemoryTokenStore(session: session),
        ),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        fakeFinanceApiOverride,
        linkLauncherProvider.overrideWithValue(launcher),
        packageInfoProvider.overrideWith((ref) async => testPackageInfo),
        linkPollIntervalProvider.overrideWithValue(Duration.zero),
      ],
      retry: (_, _) => null,
    );
  });

  LinkController controller() => c.read(linkControllerProvider.notifier);
  LinkState state() => c.read(linkControllerProvider);
  InMemoryStore store() => c.read(inMemoryStoreProvider);
  List<String> banks() => [for (final LinkedBank b in store().items()) b.id];

  test('link: exchange, sync through not_ready, pull', () async {
    final List<LinkState> seen = [];
    c.listen(linkControllerProvider, (_, next) => seen.add(next));
    await controller().link();

    expect(state(), const LinkState());
    expect(banks(), ['item-a']);
    expect(store().item('item-a')!.institution.name, 'Bank A');
    expect(store().accounts().map((a) => a.id), ['item-a-checking']);
    expect(store().count(TransactionQuery.all), 1);
    expect(server.calls, [
      'createLinkToken',
      'exchangePublicToken',
      'syncItem',
      'syncItem',
      'listItems',
      'listAccounts',
      'listTransactions',
      'listRecurringStreams',
      'getLiabilities',
      'listHoldings',
      'listInvestmentTransactions',
    ]);
    expect(seen.map((s) => s.newLink?.step ?? s.byItem['item-a']?.step), [
      ItemStep.linking,
      ItemStep.exchanging,
      null,
      ItemStep.syncing,
      ItemStep.pulling,
      null,
    ]);

    await controller().link();
    expect(banks(), ['item-a', 'item-b'], reason: 'the next Item');
  });

  test(
    'Link closed by the user is no failure; closed with an error is',
    () async {
      launcher.exitNext();
      await controller().link();
      expect(state(), const LinkState());
      const LinkExitError error = LinkExitError(
        code: 'INSTITUTION_DOWN',
        type: 'INSTITUTION_ERROR',
        displayMessage: 'The bank is down.',
      );
      launcher.exitNext(error);
      await controller().link();
      expect(state().newLink, const ItemAction.failed(ItemLinkFailure(error)));
      expect(server.calls, isNot(contains('exchangePublicToken')));
      expect(banks(), isEmpty);
    },
  );

  test(
    'repair: update-mode Link, no exchange, then the sync and the pull',
    () async {
      await controller().link();
      server.calls.clear();
      await controller().repair('item-a');
      expect(state(), const LinkState());
      expect(server.calls, [
        'createUpdateLinkToken',
        'syncItem',
        'listItems',
        'listAccounts',
        'listTransactions',
        'listRecurringStreams',
        'getLiabilities',
        'listHoldings',
        'listInvestmentTransactions',
      ]);
    },
  );

  test('sync, and the server saying the login must be repaired', () async {
    await controller().link();
    server.calls.clear();
    await controller().sync('item-a');
    expect(server.calls.first, 'syncItem');
    expect(state().byItem, isEmpty);

    server.failNext('syncItem', 409, code: 'item_login_required');
    await controller().sync('item-a');
    expect(
      state().byItem['item-a'],
      const ItemAction.failed(ItemApiFailure(ItemApiFailureKind.loginRequired)),
    );
    expect(store().item('item-a')!.item.status, ItemStatus.loginRequired);
  });

  test('unlink removes the Item, then the pull takes its data away', () async {
    await controller().link();
    await controller().unlink('item-a', keepHistory: false);
    expect(state(), const LinkState());
    expect(banks(), isEmpty);
    expect(store().accounts(), isEmpty);
    expect(store().count(TransactionQuery.all), 0);
    // Already gone at the server: still no failure.
    await controller().unlink('item-a', keepHistory: false);
    expect(state(), const LinkState());
  });

  test('unlink keeping the history: the Item stays removed with its data, until its '
      'history is deleted', () async {
    await controller().link();
    await controller().unlink('item-a', keepHistory: true);
    expect(state(), const LinkState());
    expect(banks(), ['item-a']);
    expect(store().item('item-a')!.item.status, ItemStatus.removed);
    expect(store().accounts().map((a) => a.id), ['item-a-checking']);
    expect(store().count(TransactionQuery.all), 1);

    // Deleting the kept history later: the server drops the Item and tombstones its
    // rows, and the pull takes them away.
    await controller().unlink('item-a', keepHistory: false);
    expect(state(), const LinkState());
    expect(banks(), isEmpty);
    expect(store().accounts(), isEmpty);
    expect(store().count(TransactionQuery.all), 0);
  });

  test('a server error has its own class', () async {
    await controller().link();
    server.failNext('syncItem', 500);
    await controller().sync('item-a');
    expect(
      state().byItem['item-a'],
      const ItemAction.failed(ItemApiFailure(ItemApiFailureKind.server)),
    );
  });

  test('a reset login: the sync says so, and repair through update-mode Link '
      'makes the Item healthy again, with no exchange', () async {
    await controller().link();
    await c.read(financeApiProvider).sandboxResetLogin('item-a');
    await controller().sync('item-a');
    expect(
      store().item('item-a')!.item,
      isA<Item>()
          .having((i) => i.status, 'status', ItemStatus.loginRequired)
          .having((i) => i.errorCode, 'errorCode', 'ITEM_LOGIN_REQUIRED'),
    );
    server.calls.clear();
    await controller().repair('item-a');
    expect(state(), const LinkState());
    expect(server.calls, isNot(contains('exchangePublicToken')));
    expect(store().item('item-a')!.item.status, ItemStatus.healthy);
    expect(store().item('item-a')!.item.errorCode, isNull);
  });

  test('a sync that never completes pulls anyway and says the bank is still '
      'preparing', () async {
    server.notReadyItems.add('item-a');
    await controller().link();
    expect(
      server.calls.where((call) => call == 'syncItem'),
      hasLength(syncTries),
    );
    expect(banks(), ['item-a']);
    expect(
      state().byItem['item-a'],
      const ItemAction.failed(ItemStillPreparing()),
    );
  });

  test('a sync failure after the exchange shows on the new Item', () async {
    server.failNextNetwork('syncItem');
    await controller().link();
    expect(state().newLink, isNull);
    expect(
      state().byItem['item-a'],
      const ItemAction.failed(ItemApiFailure(ItemApiFailureKind.offline)),
    );
    expect(banks(), ['item-a'], reason: 'stored at the exchange');
  });

  test('a rate limit fails the link with its class', () async {
    server.failNext('createLinkToken', 429);
    await controller().link();
    expect(
      state().newLink?.failure,
      isA<ItemApiFailure>().having(
        (f) => f.kind,
        'kind',
        ItemApiFailureKind.rateLimited,
      ),
    );
  });

  test('one Link session at a time', () async {
    await controller().link();
    launcher.hold = Completer<void>();
    final Future<void> linking = controller().link();
    await pumpEventQueue();
    expect(state().linkBusy, isTrue);
    await controller().repair('item-a');
    await controller().link();
    expect(launcher.opened, 2);
    launcher.hold!.complete();
    await linking;
    expect(banks(), ['item-a', 'item-b']);
  });
}
