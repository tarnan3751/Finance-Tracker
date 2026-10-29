// Investments and balance snapshots on a device, in the demo flavor. Run on the
// harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does, on the renter persona as of the device's
// today: after the first frame there is one balance snapshot per live account for
// today, `demo` for the persona's linked accounts, and no holdings. Choosing the family
// persona brings its brokerage through the providers (three ETFs held in its 401k, its
// contributions and buys newest first) and today's snapshots of the family's accounts,
// the 401k valued at the total it reports.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/investments/application/investments_providers.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: today\'s snapshots, and the family\'s brokerage', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final LocalDate today = container.read(todayProvider);

    Future<List<BalanceSnapshot>> snapshotsWritten() async {
      await tester.runAsync(
        () => container.read(snapshotWriterRunnerProvider.notifier).settled(),
      );
      return (await tester.runAsync(
        () =>
            container.read(balanceSnapshotRepositoryProvider).watchAll().first,
      ))!;
    }

    Future<List<Account>> accounts() async => (await tester.runAsync(
      () => container.read(accountRepositoryProvider).watchAll().first,
    ))!;

    List<BalanceSnapshot> written = await snapshotsWritten();
    expect(
      written.map((s) => s.accountId).toSet(),
      (await accounts()).map((a) => a.id).toSet(),
    );
    expect(written.every((s) => s.date == today), isTrue);
    expect(
      written.every(
        (s) => s.source == DataSource.demo || s.source == DataSource.manual,
      ),
      isTrue,
    );
    expect(written.any((s) => s.source == DataSource.demo), isTrue);
    expect(
      (await tester.runAsync(
        () => container.read(holdingRepositoryProvider).watchAll().first,
      ))!,
      isEmpty,
    );

    container.read(demoPersonaProvider.notifier).select(PersonaId.family);
    await tester.pumpAndSettle();
    final ProviderSubscription<AsyncValue<List<HoldingView>>> holdings =
        container.listen(holdingsProvider, (_, _) {});
    addTearDown(holdings.close);
    await tester.pumpAndSettle();
    final List<HoldingView> held = holdings.read().requireValue;
    expect(held.map((v) => v.security!.tickerSymbol).toSet(), {
      'VTI',
      'VXUS',
      'BND',
    });
    expect(held.every((v) => v.holding.source == DataSource.demo), isTrue);
    final String ira = held.first.holding.accountId;
    final ProviderSubscription<AsyncValue<List<InvestmentTransaction>>> rows =
        container.listen(investmentTransactionsProvider(ira), (_, _) {});
    addTearDown(rows.close);
    await tester.pumpAndSettle();
    final List<InvestmentTransaction> history = rows.read().requireValue;
    expect(history, isNotEmpty);
    expect(history.first.date.isAfter(history.last.date), isTrue);

    written = await snapshotsWritten();
    final List<Account> family = await accounts();
    expect(
      written.map((s) => s.accountId).toSet(),
      family.map((a) => a.id).toSet(),
    );
    final Account retirement = family.singleWhere((a) => a.id == ira);
    expect(
      written.singleWhere((s) => s.accountId == ira).current,
      retirement.currentBalance,
    );
  });
}
