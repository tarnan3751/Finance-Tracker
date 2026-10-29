// Bills for screen tests on testClock's today, 24 October 2026, with amounts no test
// seed transaction comes near: Rent missed on Oct 1, the phone due Oct 27, water paid
// early for Oct 26, Netflix on autopay from Nov 10, insurance a year from March 2027 (past
// the 60 days), and the gym paused (it would be missed).
//
//   InMemoryBillRepository(testClock, recorder: const NoChangeRecorder(), initial: testBills())
import 'package:shared_models/shared_models.dart';

/// A bill [id] of [cents] USD (an outflow) first due [first], monthly unless [cadence]
/// says otherwise.
BillReminder testBill(
  String id,
  String name,
  int cents,
  LocalDate first, {
  RecurringCadence? cadence = RecurringCadence.monthly,
  bool active = true,
  bool autopay = false,
  List<LocalDate> paid = const [],
}) => BillReminder(
  id: id,
  name: name,
  amount: Money(-cents, 'USD'),
  dueDate: first,
  cadence: cadence,
  active: active,
  autopay: autopay,
  paidOccurrences: paid,
);

/// The bills of the header.
List<BillReminder> testBills() => [
  testBill(
    'rent',
    'Rent',
    123457,
    LocalDate(2026, 9, 1),
    paid: [LocalDate(2026, 9, 1)],
  ),
  testBill('phone', 'Phone', 8765, LocalDate(2026, 10, 27)),
  testBill(
    'water',
    'Water',
    4321,
    LocalDate(2026, 10, 26),
    paid: [LocalDate(2026, 10, 26)],
  ),
  testBill('netflix', 'Netflix', 1999, LocalDate(2026, 11, 10), autopay: true),
  testBill(
    'insurance',
    'Insurance',
    65432,
    LocalDate(2027, 3, 1),
    cadence: RecurringCadence.annually,
  ),
  testBill('gym', 'Gym', 3456, LocalDate(2026, 9, 5), active: false),
];
