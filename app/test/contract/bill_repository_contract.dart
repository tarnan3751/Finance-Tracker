// The contract every BillRepository implementation passes: the in-memory, demo and Drift
// ones, each from its own test file under test/features/bills/data/.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A bill [id] due first on [dueDate], every field set.
BillReminder testBill(
  String id, {
  LocalDate? dueDate,
  int? amount = -150000,
  String currency = 'USD',
  String? name = 'Rent',
  List<LocalDate> paid = const [],
}) => BillReminder(
  id: id,
  name: name,
  amount: amount == null ? null : Money(amount, currency),
  dueDate: dueDate ?? LocalDate(2026, 11, 1),
  cadence: RecurringCadence.monthly,
  accountId: 'checking',
  streamId: 'stream-1',
  liabilityAccountId: 'card',
  reminderOffsetDays: const [0, 3],
  reminderMinutes: 1020,
  autopay: true,
  paidOccurrences: paid,
);

/// Registers the contract tests for the fixtures [create] builds.
void runBillRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('BillRepository contract', () {
    late BillRepository bills;

    setUp(() async => bills = (await create()).bills);
    if (dispose != null) tearDown(dispose);

    List<String> ids(List<BillReminder> list) => [
      for (final BillReminder b in list) b.id,
    ];

    test('a fresh repository has no bills', () async {
      expect(await bills.watchAll().first, isEmpty);
      expect(await bills.watchById('b1').first, isNull);
    });

    test('upsert stores the bill as given, and replaces it', () async {
      final BillReminder bill = testBill(
        'b1',
        amount: 12345,
        currency: 'EUR',
        paid: [LocalDate(2026, 9, 1), LocalDate(2026, 10, 1)],
      );
      await bills.upsert(bill);
      expect(await bills.watchAll().first, [bill]);
      expect(await bills.watchById('b1').first, bill);
      final BillReminder bare = BillReminder(
        id: 'b1',
        dueDate: LocalDate(2024, 2, 29),
        reminderOffsetDays: const [],
        active: false,
      );
      await bills.upsert(bare);
      expect(await bills.watchAll().first, [bare]);
      expect(await bills.watchById('b1').first, bare);
    });

    test('bills are ordered by first due date, then by id', () async {
      await bills.upsert(testBill('b3', dueDate: LocalDate(2026, 11, 2)));
      await bills.upsert(testBill('b2'));
      await bills.upsert(testBill('b1', dueDate: LocalDate(2026, 11, 2)));
      await bills.upsert(testBill('b0', dueDate: LocalDate(2027, 1, 1)));
      expect(ids(await bills.watchAll().first), ['b2', 'b1', 'b3', 'b0']);
    });

    test('a watcher gets the current bills, then each change', () async {
      final Future<List<List<String>>> seen = bills
          .watchAll()
          .map(ids)
          .take(3)
          .toList();
      final Future<List<String?>> one = bills
          .watchById('b1')
          .map((b) => b?.name)
          .take(4)
          .toList();
      await pumpEventQueue();
      await bills.upsert(testBill('b1'));
      await pumpEventQueue();
      await bills.upsert(testBill('b2'));
      await pumpEventQueue();
      await bills.upsert(testBill('b1', name: 'Mortgage'));
      await pumpEventQueue();
      await bills.delete('b1');
      expect(await seen, [
        <String>[],
        ['b1'],
        ['b1', 'b2'],
      ]);
      expect(await one, [null, 'Rent', 'Mortgage', null]);
    });

    test('delete hides the bill; restore brings it back as it was', () async {
      await bills.upsert(testBill('b1', paid: [LocalDate(2026, 10, 1)]));
      await bills.upsert(testBill('b2'));
      await bills.delete('b1');
      expect(ids(await bills.watchAll().first), ['b2']);
      expect(await bills.watchById('b1').first, isNull);
      await bills.restore('b1');
      expect(
        await bills.watchById('b1').first,
        testBill('b1', paid: [LocalDate(2026, 10, 1)]),
      );
      expect(ids(await bills.watchAll().first), ['b1', 'b2']);
    });

    test('deleting or restoring what is not there does nothing', () async {
      await bills.delete('missing');
      await bills.restore('missing');
      await bills.upsert(testBill('b1'));
      await bills.restore('b1');
      await bills.delete('b1');
      await bills.delete('b1');
      expect(await bills.watchAll().first, isEmpty);
    });

    test('an upsert of a deleted bill throws and changes nothing', () async {
      await bills.upsert(testBill('b1'));
      await bills.delete('b1');
      await expectLater(
        bills.upsert(testBill('b1', name: 'Other')),
        throwsA(isA<EntityDeletedException>()),
      );
      await bills.restore('b1');
      expect(await bills.watchAll().first, [testBill('b1')]);
    });
  });
}
