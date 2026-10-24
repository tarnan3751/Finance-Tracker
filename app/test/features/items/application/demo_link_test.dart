// The demo flavor's wiring: its first Plaid pull starts after the seed it already holds,
// so the demo's own edits of its `demo` rows survive it, and linking a bank brings that
// bank's rows and only those (Houndstooth Bank, which no persona uses), whether or not
// anything pulled before the Link.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';

ProviderContainer _demo() => ProviderContainer.test(
  overrides: [
    ...overridesFor(AppConfig.demo()),
    clockProvider.overrideWithValue(testClock),
    packageInfoProvider.overrideWith((ref) async => testPackageInfo),
    appVersionProvider.overrideWith((ref) async => '1.0.0'),
    linkPollIntervalProvider.overrideWithValue(Duration.zero),
  ],
  retry: (_, _) => null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a Link with nothing pulled before it brings the new bank\'s rows',
    () async {
      // In the demo nothing reads the pull before a Link, so its store is first built
      // during the Link, after the fake has applied the new bank.
      final ProviderContainer c = _demo();
      final TransactionRepository transactions = c.read(
        transactionRepositoryProvider,
      );
      final int before = await transactions.count(TransactionQuery.all);
      await c.read(linkControllerProvider.notifier).link();
      final int houndstooth = demoLinkableBank(testClock.today())
          .transactions
          .length;
      expect(houndstooth, 12);
      expect(
        await transactions.count(TransactionQuery.all),
        before + houndstooth,
      );
      expect(await transactions.watchById('sample-txn-01').first, isNotNull);
    },
  );

  test('edits survive the pull, and a Link brings only the new bank', () async {
    final ProviderContainer c = _demo();
    final TransactionRepository transactions = c.read(
      transactionRepositoryProvider,
    );
    final List<Transaction> seeded =
        (await transactions.watch(TransactionQuery.all).first)
            .where((t) => !t.id.endsWith('-opening'))
            .toList();
    final Transaction gone = seeded[0];
    final Transaction renamed = seeded[1].copyWith(name: 'Renamed in the demo');
    await transactions.delete(gone.id);
    await transactions.upsert(renamed);
    final int before = await transactions.count(TransactionQuery.all);

    await c.read(plaidPullProvider).run();
    expect(await transactions.watchById(gone.id).first, isNull);
    expect(
      (await transactions.watchById(renamed.id).first)!.name,
      'Renamed in the demo',
    );
    expect(await transactions.count(TransactionQuery.all), before);

    await c.read(linkControllerProvider.notifier).link();
    final List<LinkedBank> banks = await c
        .read(itemRepositoryProvider)
        .watchAll()
        .first;
    expect(banks.map((b) => b.institution.name), contains('Houndstooth Bank'));
    final int houndstooth = demoLinkableBank(testClock.today())
        .transactions
        .length;
    expect(
      await transactions.count(TransactionQuery.all),
      before + houndstooth,
    );
    expect(await transactions.watchById(gone.id).first, isNull);
    expect(
      (await transactions.watchById(renamed.id).first)!.name,
      'Renamed in the demo',
    );
  });
}
