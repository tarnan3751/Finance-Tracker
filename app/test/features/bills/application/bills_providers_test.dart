// The bills providers over the in-memory repositories: a one-off paid more than the
// usual lookback ago still shows paid, because the payment window reaches back to it.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a one-off paid two years ago still shows paid', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.demo()),
        clockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2027, 3, 10, 12), tz.UTC),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(accountRepositoryProvider).upsert(testAccount('acc'));
    await container
        .read(transactionRepositoryProvider)
        .upsert(
          testTransaction('t', 'acc', -25000, date: LocalDate(2025, 3, 1)),
        );
    await container
        .read(billRepositoryProvider)
        .upsert(
          BillReminder(
            id: 'deposit',
            name: 'Deposit',
            amount: Money(-25000, 'USD'),
            dueDate: LocalDate(2025, 3, 1),
          ),
        );
    final ProviderSubscription<AsyncValue<List<BillStatus>>> sub = container
        .listen(billStatusesProvider, (_, _) {});
    addTearDown(sub.close);
    final List<BillStatus> statuses = await container.read(
      billStatusesProvider.future,
    );
    expect(statuses.single.lastOccurrence, LocalDate(2025, 3, 1));
    expect(statuses.single.state, BillState.paid);
    expect(statuses.single.matchedTransactionId, 't');
  });
}
