// The demo bills of every persona: two, deterministic, linked to their demo streams, the
// housing bill's last occurrence paid, and each one a real outflow of the seed.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/bills/data/demo_bills.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  final LocalDate today = LocalDate(2026, 10, 27);

  for (final PersonaId persona in PersonaId.values) {
    test('${persona.slug}: two bills from its expectations', () {
      final DemoSeed seed = demoSeedFor(persona, today);
      final List<BillReminder> bills = demoBills(seed, today);
      expect(bills, hasLength(2));
      expect(demoBills(demoSeedFor(persona, today), today), bills);
      final Map<String, RecurringExpectation> byKey = {
        for (final RecurringExpectation r in seed.household.recurring) r.key: r,
      };
      final BillReminder housing = bills.first;
      final BillReminder subscription = bills.last;
      for (final BillReminder bill in bills) {
        final String key = bill.id.substring('demo-bill-'.length);
        final RecurringExpectation r = byKey[key]!;
        expect(r.isInflow, isFalse);
        expect(bill.streamId, 'demo-stream-$key');
        expect(bill.accountId, r.accountId);
        expect(bill.cadence, r.cadence);
        expect(bill.amount!.isNegative, isTrue);
        expect(bill.reminderOffsetDays, [2]);
        // The first nominal date from two months back: a monthly bill has history, an
        // annual one may fall due later this year.
        expect(bill.dueDate.isBefore(today.addMonths(-2)), isFalse);
        expect(r.schedule.isNominal(bill.dueDate), isTrue);
      }
      expect(byKey[subscription.id.substring(10)]!.isSubscription, isTrue);
      expect(housing.cadence, RecurringCadence.monthly);
      expect(housing.dueDate.isBefore(today), isTrue);
      final LocalDate last = BillSchedule.of(housing).previousBefore(today)!;
      expect(housing.paidOccurrences, [last]);
      expect(subscription.paidOccurrences, isEmpty);
    });
  }
}
