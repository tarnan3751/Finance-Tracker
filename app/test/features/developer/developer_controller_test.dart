// The developer controller's requests, as the client sends them to the in-app fake
// server: each operation on the Item asked for, with its body, followed by the pull; a
// failed operation pulls nothing, and one answered `item_login_required` marks the
// stored Item; the provisioning request, and a poll skipped while the last is
// unanswered; and Plaid's today.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

/// The requests the client sends, with their bodies, on to the fake.
final class _Recorder implements HttpClientAdapter {
  _Recorder(this._inner);

  final HttpClientAdapter _inner;
  final List<({String request, String body})> requests = [];

  /// When set, the next request waits for it before reaching the fake.
  Completer<void>? holdNext;

  List<String> get paths => [for (final r in requests) r.request];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final List<int> bytes = [
      if (requestStream != null)
        for (final Uint8List chunk in await requestStream.toList()) ...chunk,
    ];
    requests.add((
      request: '${options.method} ${options.uri.path}',
      body: utf8.decode(bytes),
    ));
    final Completer<void>? hold = holdNext;
    holdNext = null;
    if (hold != null) await hold.future;
    return _inner.fetch(
      options,
      requestStream == null ? null : Stream.value(Uint8List.fromList(bytes)),
      cancelFuture,
    );
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

const String _item = 'sample-item-1';

void main() {
  late FakeServer fake;
  late _Recorder recorder;
  late ProviderContainer container;

  setUp(() {
    fake =
        FakeServer(
            dataset: FakeDataset.sample(testClock.today()),
            now: testClock.nowUtc,
          )
          ..seedUser(email: 'dev@example.com', password: 'correct horse')
          ..seedLinkedItems('dev@example.com');
    final Session session = fake.seedSession(
      email: 'dev@example.com',
      password: 'correct horse',
    );
    recorder = _Recorder(fake.adapter);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.dev()),
        clockProvider.overrideWithValue(testClock),
        storeOverride(seededStore()),
        financeApiProvider.overrideWith((ref) {
          final HttpFinanceApi api = HttpFinanceApi(
            buildDio(
              AppConfig.dev(),
              adapter: recorder,
              baseUrl: FakeServer.baseUrl,
              version: () async => '1.0.0',
            ),
            tokens: InMemoryTokenStore(session: session),
            clock: testClock,
          );
          ref.onDispose(api.close);
          return api;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  DeveloperController controller() =>
      container.read(developerControllerProvider.notifier);
  DeveloperState state() => container.read(developerControllerProvider);

  /// [request] was sent, then the pull's first request.
  void expectThenPulled(String request) {
    final int at = recorder.paths.indexOf(request);
    expect(at, isNot(-1), reason: '$request in ${recorder.paths}');
    expect(recorder.paths[at + 1], 'GET /v1/plaid/items');
  }

  test(
    'Refresh transactions and balances ask for the Item, then pull',
    () async {
      await controller().refreshTransactions(_item);
      expectThenPulled('POST /v1/plaid/items/$_item/refresh');
      expect(state().result!.run!.status, SyncRunStatus.started);
      expect(state().result!.pullFailure, isNull);
      expect(state().pull!.pulledAt, testClock.nowUtc());

      await controller().refreshBalances(_item);
      expectThenPulled('POST /v1/plaid/items/$_item/balances');
      expect(state().result!.accounts, 3);
    },
  );

  test('Reset login and Fire webhook ask for the Item, then pull', () async {
    await controller().fireWebhook(_item, SandboxWebhookCode.loginRepaired);
    expectThenPulled('POST /v1/sandbox/items/$_item/fire-webhook');
    expect(
      jsonDecode(
        recorder.requests
            .firstWhere((r) => r.request.endsWith('/fire-webhook'))
            .body,
      ),
      {'webhook_code': 'LOGIN_REPAIRED'},
    );

    await controller().resetLogin(_item);
    expectThenPulled('POST /v1/sandbox/items/$_item/reset-login');
    expect(state().result!.operation, DeveloperOperation.resetLogin);
    expect(state().result!.failure, isNull);
  });

  test(
    'Inject sends the transactions in Plaid\'s sign, dated from its today',
    () async {
      await controller().injectTransactions(
        _item,
        accountId: 'sample-checking',
        count: 2,
        description: 'Coffee',
        amount: Money(-450, 'USD'),
        daysBack: 3,
      );
      expectThenPulled('POST /v1/sandbox/items/$_item/transactions');
      // 24 October 2026, 15:00 UTC: Plaid's today is the 24th.
      Map<String, Object?> one(String name) => {
        'date_transacted': '2026-10-21',
        'date_posted': '2026-10-21',
        'amount': {'minor_units': 450, 'currency': 'USD'},
        'description': name,
        'account_id': 'sample-checking',
      };
      expect(
        jsonDecode(
          recorder.requests
              .firstWhere((r) => r.request.endsWith('/transactions'))
              .body,
        ),
        {
          'transactions': [one('Coffee 1'), one('Coffee 2')],
        },
      );
      expect(state().result!.injected, 2);
    },
  );

  test('a failed operation names the exception and pulls nothing', () async {
    fake.failNext('refreshItem', 409, code: 'item_login_required');
    await controller().refreshTransactions(_item);
    expect(recorder.paths, ['POST /v1/plaid/items/$_item/refresh']);
    expect(
      state().result!.failure,
      'ItemLoginRequired(409 item_login_required)',
    );
    expect(state().running, isNull);
    final banks = await container.read(itemRepositoryProvider).watchAll().first;
    expect(banks, isEmpty, reason: 'nothing pulled yet, so nothing to mark');
  });

  test(
    'an operation answered item_login_required marks the stored Item',
    () async {
      await controller().pullNow();
      final ItemRepository items = container.read(itemRepositoryProvider);
      expect(
        (await items.watchAll().first).single.item.status,
        ItemStatus.healthy,
      );

      fake.failNext('refreshBalances', 409, code: 'item_login_required');
      await controller().refreshBalances(_item);
      expect(
        state().result!.failure,
        'ItemLoginRequired(409 item_login_required)',
      );
      final Item item = (await items.watchAll().first).single.item;
      expect(item.status, ItemStatus.loginRequired);
      expect(item.errorCode, 'ITEM_LOGIN_REQUIRED');
    },
  );

  test('a failed pull after an operation is named beside it', () async {
    fake.failNextNetwork('listItems');
    await controller().resetLogin(_item);
    expect(state().result!.failure, isNull);
    expect(state().result!.pullFailure, startsWith('NetworkError('));
    expect(state().pull!.failure, startsWith('NetworkError('));
  });

  test(
    'provisioning sends the persona, seed and days, then polls the job',
    () async {
      await controller().provision(
        ProvisionPersona.smallBusiness,
        seed: 7,
        days: 90,
      );
      expect(recorder.paths, ['POST /v1/sandbox/provision']);
      expect(jsonDecode(recorder.requests.single.body), {
        'persona': 'small_business',
        'seed': 7,
        'days': 90,
      });
      final String jobId = state().jobId!;
      expect(state().jobActive, isTrue);

      // A second start while it runs sends nothing.
      await controller().provision(ProvisionPersona.renter, seed: 1, days: 730);
      expect(recorder.paths, hasLength(1));

      // While a poll is unanswered, the next tick sends nothing.
      final Completer<void> hold = Completer<void>();
      recorder.holdNext = hold;
      int polls() => recorder.paths
          .where((p) => p.startsWith('GET /v1/sandbox/provision/'))
          .length;
      final Future<void> first = controller().pollJob();
      while (polls() == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await controller().pollJob();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(polls(), 1);
      hold.complete();
      await first;
      expect(state().job!.status, ProvisionJobStatus.queued);

      fake.advanceClock(const Duration(seconds: 5));
      await controller().pollJob();
      expect(recorder.paths.last, 'GET /v1/sandbox/provision/$jobId');
      expect(state().job!.status, ProvisionJobStatus.completed);
      expect(state().jobActive, isFalse);

      // Finished, it is not asked for again.
      await controller().pollJob();
      expect(recorder.paths, hasLength(3));
    },
  );

  test('Plaid\'s today is the calendar date at UTC−12', () {
    expect(
      plaidToday(DateTime.utc(2026, 10, 24, 11, 59)),
      LocalDate(2026, 10, 23),
    );
    expect(plaidToday(DateTime.utc(2026, 10, 24, 12)), LocalDate(2026, 10, 24));
    expect(
      plaidToday(DateTime.utc(2026, 10, 24, 23, 59)),
      LocalDate(2026, 10, 24),
    );
  });
}
