// The recurring detector on a device, in the demo flavor. Run on the harness's emulator
// with `tools/emulator_tests.sh integration`.
//
// The demo starts as main_demo.dart starts it, with the renter persona's streams served
// by the demo; a manual account with four monthly gym charges is added. Once the
// detector has run (on a background isolate: the persona's ledger is over the
// threshold), the merged list holds every persona stream once, and the only detected
// stream is the gym's, classified a subscription: every stream the detector finds in
// the persona's own rows is one the demo already serves, and is dropped.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:persona_engine/persona_engine.dart' show DemoSeed;
import 'package:shared_models/shared_models.dart';

/// How long the detector may take on a loaded emulator, in wall-clock time.
const Duration _patience = Duration(seconds: 120);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: detected streams merge with the persona\'s', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final DemoSeed seed = container.read(demoSeedProvider);
    final LocalDate today = container.read(todayProvider);
    final DateTime now = container.read(clockProvider).nowUtc();

    await container
        .read(accountRepositoryProvider)
        .upsert(
          const Account(
            id: 'gym-jar',
            type: AccountType.depository,
            name: 'Gym jar',
            currencyCode: 'USD',
            isHidden: false,
            displayOrder: 99,
          ),
        );
    await container.read(transactionRepositoryProvider).upsertAll([
      for (int i = 1; i <= 4; i++)
        Transaction(
          id: 'gym-$i',
          accountId: 'gym-jar',
          amount: Money(-3999, 'USD'),
          date: today.addMonths(-i),
          pending: false,
          name: 'Lakeside Gym',
          source: DataSource.manual,
          createdAt: now,
          updatedAt: now,
          syncVersion: 0,
        ),
    ]);

    final merged = container.listen(mergedStreamsProvider, (_, _) {});
    addTearDown(merged.close);
    List<StreamView> views = const [];
    final Stopwatch waited = Stopwatch()..start();
    while (waited.elapsed < _patience) {
      views = merged.read().value ?? const [];
      if (views.any((v) => v.stream.accountId == 'gym-jar')) break;
      await tester.pump(const Duration(milliseconds: 200));
    }

    final List<StreamView> detected = [
      for (final StreamView v in views)
        if (v.stream.source == RecurringSource.detected) v,
    ];
    expect(detected, hasLength(1), reason: '$detected');
    final StreamView gym = detected.single;
    expect(gym.stream.accountId, 'gym-jar');
    expect(gym.stream.cadence, RecurringCadence.monthly);
    expect(gym.stream.merchantName, 'Lakeside Gym');
    expect(gym.stream.averageAmount, Money(-3999, 'USD'));
    expect(gym.isSubscription, isTrue);
    expect(
      views.where((v) => v.stream.source == RecurringSource.demo),
      hasLength(seed.household.recurring.length),
    );
  });
}
