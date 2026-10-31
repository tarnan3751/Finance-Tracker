// The developer menu's screens over the in-app fake server: the Developer section only
// in the dev flavor, its diagnostics, Pull now and Copy diagnostics; every Sandbox
// control answered for the Item and followed by the pull; a failure named on its line;
// injected transactions dated from Plaid's today (UTC−12) on the chosen account; and the
// provisioning job polled to completion, the polling stopping with the screen and
// resuming on its return; and the background worker scheduled 20 seconds out. The
// requests themselves are developer_controller_test.dart's.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:finance_tracker/features/developer/presentation/developer_screen.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

const String _item = 'sample-item-1';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).last));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The dev flavor's settings over [store], the bank data pulled with Pull now, then the
/// Sandbox controls opened.
Future<FakeServer> _openControls(
  WidgetTester tester,
  InMemoryStore store, {
  Clock? clock,
}) async {
  await pumpApp(
    tester,
    config: AppConfig.dev(),
    initialLocation: '/settings',
    size: const Size(412, 2400),
    clock: clock,
    overrides: [storeOverride(store)],
  );
  await _tap(tester, find.text('Pull now'));
  await _tap(tester, find.text('Sandbox controls'));
  expect(find.widgetWithText(AppBar, 'Sandbox controls'), findsOneWidget);
  final FakeServer fake = _container(tester).read(fakeServerProvider);
  fake.calls.clear();
  return fake;
}

/// [operation] was answered, and the pull followed it.
void _expectCalledThenPulled(FakeServer fake, String operation) {
  final int at = fake.calls.indexOf(operation);
  expect(at, isNot(-1), reason: '$operation in ${fake.calls}');
  expect(fake.calls.skip(at + 1), contains('listItems'));
}

void main() {
  testWidgets('the dev flavor alone has the Developer section', (tester) async {
    for (final AppConfig config in [AppConfig.demo(), AppConfig.prod()]) {
      await pumpApp(
        tester,
        config: config,
        initialLocation: '/settings',
        size: const Size(412, 2400),
      );
      expect(find.text('Developer'), findsNothing);
      expect(find.text('Sandbox controls'), findsNothing);
    }
    await pumpApp(
      tester,
      config: AppConfig.dev(),
      initialLocation: '/settings',
      size: const Size(412, 2400),
    );
    expect(find.text('Developer'), findsOneWidget);
    expect(find.text('Sandbox controls'), findsOneWidget);
  });

  testWidgets(
    'the section shows the diagnostics, pulls, and copies them as text',
    (tester) async {
      final InMemoryStore store = seededStore();
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpApp(
        tester,
        config: AppConfig.dev(),
        initialLocation: '/settings',
        size: const Size(412, 2400),
        overrides: [storeOverride(store)],
      );
      final ProviderContainer c = _container(tester);
      final String deviceId = c.read(syncDeviceIdProvider)!;
      expect(find.text('http://10.0.2.2:8080/v1'), findsWidgets);
      expect(find.text(deviceId), findsOneWidget);
      expect(find.text('Never'), findsNWidgets(2));
      expect(find.text('Not read yet'), findsOneWidget);

      await _tap(tester, find.text('Pull now'));
      expect(c.read(fakeServerProvider).calls, contains('listItems'));
      expect(
        find.text('Pulled; bank data updated Oct 24, 2026 3:00\u00a0PM'),
        findsOneWidget,
      );
      expect(store.accounts().where((a) => a.itemId == _item), isNotEmpty);

      await _tap(tester, find.text('Copy diagnostics'));
      expect(find.text('Diagnostics copied'), findsOneWidget);
      expect(
        copied,
        'Server: http://10.0.2.2:8080/v1\n'
        'Device: $deviceId\n'
        'Last sync: Never\n'
        'Bank data pulled: Oct 24, 2026 3:00\u00a0PM\n'
        'Outbox: Not read yet',
      );
    },
  );

  testWidgets('Refresh transactions refreshes the Item, then pulls', (
    tester,
  ) async {
    final FakeServer fake = await _openControls(tester, seededStore());
    expect(find.text('First Platypus Bank (sample-item-1)'), findsOneWidget);
    await _tap(tester, find.text('Refresh transactions'));
    _expectCalledThenPulled(fake, 'refreshItem');
    expect(
      find.text('Refresh started: 0 added, 0 modified, 0 removed'),
      findsOneWidget,
    );
  });

  testWidgets('Refresh balances answers the Item\'s accounts, then pulls', (
    tester,
  ) async {
    final FakeServer fake = await _openControls(tester, seededStore());
    await _tap(tester, find.text('Refresh balances'));
    _expectCalledThenPulled(fake, 'refreshBalances');
    expect(find.text('Balances refreshed for 3 accounts'), findsOneWidget);
  });

  testWidgets('Reset login resets the Item, and the pull shows it', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    final FakeServer fake = await _openControls(tester, store);
    await _tap(tester, find.text('Reset login'));
    _expectCalledThenPulled(fake, 'sandboxResetLogin');
    expect(
      find.text('Login reset; the Item needs its connection fixed'),
      findsOneWidget,
    );
    expect(store.items().single.item.status, ItemStatus.loginRequired);

    // A refresh now fails, the exception named, and nothing is pulled.
    fake.calls.clear();
    await _tap(tester, find.text('Refresh transactions'));
    expect(
      find.text('Failed: ItemLoginRequired(409 item_login_required)'),
      findsOneWidget,
    );
    expect(fake.calls, ['refreshItem']);
  });

  testWidgets('Fire webhook fires the chosen code, then pulls', (tester) async {
    final FakeServer fake = await _openControls(tester, seededStore());
    await _tap(tester, find.text('SYNC_UPDATES_AVAILABLE'));
    await _tap(tester, find.text('LOGIN_REPAIRED').last);
    await _tap(tester, find.text('Fire webhook'));
    _expectCalledThenPulled(fake, 'sandboxFireWebhook');
    expect(find.text('Webhook fired'), findsOneWidget);
  });

  testWidgets('Inject adds the transactions dated from Plaid\'s today', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    // 08:00 UTC: Plaid's today, at UTC−12, is still the 23rd.
    final Clock clock = FixedClock(DateTime.utc(2026, 10, 24, 8), tz.UTC);
    final FakeServer fake = await _openControls(tester, store, clock: clock);
    final String savings = store
        .accounts()
        .firstWhere((a) => a.itemId == _item && a.name == 'Platypus Savings')
        .id;

    await _tap(tester, find.text('Platypus Checking'));
    await _tap(tester, find.text('Platypus Savings').last);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'How many (1 to 10)'),
      '3',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Coffee',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '-4.5',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        "Days before Plaid's today (0 to 728)",
      ),
      '2',
    );
    await tester.pumpAndSettle();
    expect(find.text('Dated Oct 21, 2026'), findsOneWidget);
    await _tap(tester, find.text('Inject'));

    _expectCalledThenPulled(fake, 'sandboxCreateTransactions');
    expect(find.text('Injected 3 transactions'), findsOneWidget);
    final List<Transaction> injected = [
      for (final Transaction t in store.transactions(
        TransactionQuery(text: 'Coffee'),
      ))
        if (t.source == DataSource.demo && t.id.startsWith('$_item-sandbox-'))
          t,
    ];
    expect(
      injected.map((t) => t.name),
      unorderedEquals(['Coffee 1', 'Coffee 2', 'Coffee 3']),
    );
    for (final Transaction t in injected) {
      expect(t.accountId, savings);
      expect(t.amount, Money(-450, 'USD'));
      expect(t.date, LocalDate(2026, 10, 21));
    }
  });

  testWidgets('the injection form refuses a count out of range', (
    tester,
  ) async {
    final FakeServer fake = await _openControls(tester, seededStore());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'How many (1 to 10)'),
      '11',
    );
    await _tap(tester, find.text('Inject'));
    expect(find.text('Enter a whole number from 1 to 10'), findsOneWidget);
    expect(fake.calls, isEmpty);
  });

  testWidgets('the injection form refuses more than 728 days back', (
    tester,
  ) async {
    final FakeServer fake = await _openControls(tester, seededStore());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Coffee',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '-4.5',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        "Days before Plaid's today (0 to 728)",
      ),
      '729',
    );
    await _tap(tester, find.text('Inject'));
    expect(find.text('Enter a whole number from 0 to 728'), findsOneWidget);
    expect(fake.calls, isEmpty);
  });

  testWidgets(
    'provisioning is polled until it completes, and only while the screen is open',
    (tester) async {
      final InMemoryStore store = seededStore();
      final FakeServer fake = await _openControls(tester, store);
      int polls() => fake.calls.where((c) => c == 'getProvisionJob').length;

      await _tap(tester, find.text('Renter'));
      await _tap(tester, find.text('Family').last);
      await _tap(tester, find.text('Start'));
      expect(fake.calls, ['provisionPersona']);
      expect(find.text('Job queued'), findsOneWidget);

      // The fake's clock has not moved, so the job stays queued.
      await tester.pump(provisionPollInterval);
      await tester.pumpAndSettle();
      expect(polls(), 1);
      expect(find.text('Job queued'), findsOneWidget);

      // Closed, the screen asks no more; opened again, it resumes.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(provisionPollInterval * 3);
      await tester.pumpAndSettle();
      expect(polls(), 1);
      await _tap(tester, find.text('Sandbox controls'));
      expect(find.text('Job queued'), findsOneWidget);

      fake.advanceClock(const Duration(minutes: 1));
      await tester.pump(provisionPollInterval);
      await tester.pumpAndSettle();
      expect(polls(), 2);
      final DeveloperState state = _container(tester)
          .read(developerControllerProvider);
      final int items = state.job!.itemIds.length;
      expect(items, greaterThan(0));
      expect(find.text('Job completed'), findsOneWidget);
      expect(find.text('Items linked: $items of $items'), findsOneWidget);
      expect(find.text('Batches sent: 0 of 0'), findsOneWidget);
      expect(find.text('Transactions skipped: 0'), findsOneWidget);

      // Finished, it is not asked for again; Pull now brings the persona's banks.
      await tester.pump(provisionPollInterval * 2);
      await tester.pumpAndSettle();
      expect(polls(), 2);
      await tester.ensureVisible(find.text('Pull now'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pull now'));
      // The persona's pages are large, and Dio decodes a large answer on another
      // isolate, which takes real time.
      final ProviderContainer c = _container(tester);
      for (
        int i = 0;
        i < 200 && c.read(developerControllerProvider).running != null;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('Pulled; bank data updated'), findsOneWidget);
      final Set<String> linked = {for (final a in store.accounts()) ?a.itemId};
      expect(linked, containsAll(state.job!.itemIds));
    },
  );

  testWidgets('Run the background worker schedules one sync 20 seconds out', (
    tester,
  ) async {
    await _openControls(tester, seededStore());
    await _tap(tester, find.text('Run the background worker in 20 seconds'));
    final FakeBackgroundWork work =
        _container(tester).read(backgroundWorkProvider) as FakeBackgroundWork;
    expect(work.calls.last, (method: 'runLater', every: developerWorkerDelay));
    expect(developerWorkerDelay, const Duration(seconds: 20));
    expect(find.textContaining('Scheduled to run after'), findsOneWidget);
  });
}
