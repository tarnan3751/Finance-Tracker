// Recurring streams for screen tests, on the test seed's accounts (test_seed.dart) and
// testClock's today, 24 October 2026: five subscriptions (Netflix $15.49 and the gym
// $25.00 monthly from the bank, iCloud $2.99 monthly detected from the transactions, the
// newspaper $99.00 a year, Patreon at an unknown cadence), Hulu muted, the electric bill
// (not a subscription), the payroll (an inflow), and an ended magazine. The known yearly costs add up to
// $620.76 across 4 subscriptions; Netflix has a next date, so a bill can be made from it.
//
//   await pumpApp(tester, overrides: [storeOverride(seededStore()), streamsOverride(seededStreams())]);
import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';

/// A stream [id] on the checking account of [cents] USD at [cadence], an outflow (an
/// inflow when [cents] is negative).
RecurringStream testStream(
  String id,
  String merchant,
  int cents, {
  RecurringCadence cadence = RecurringCadence.monthly,
  bool subscription = true,
  RecurringSource source = RecurringSource.plaid,
  RecurringStatus status = RecurringStatus.active,
  LocalDate? nextExpected,
}) => RecurringStream(
  id: id,
  accountId: checkingId,
  merchantName: merchant,
  cadence: cadence,
  averageAmount: Money(-cents, 'USD'),
  nextExpected: nextExpected,
  status: status,
  isSubscription: subscription,
  source: source,
);

/// The streams of the header.
List<RecurringStream> testStreams() => [
  testStream(
    'stream-netflix',
    'Netflix',
    1549,
    nextExpected: LocalDate(2026, 11, 3),
  ),
  testStream('stream-gym', 'Gym', 2500),
  testStream('stream-icloud', 'iCloud', 299, source: RecurringSource.detected),
  testStream(
    'stream-paper',
    'Newspaper',
    9900,
    cadence: RecurringCadence.annually,
  ),
  testStream(
    'stream-patreon',
    'Patreon',
    500,
    cadence: RecurringCadence.unknown,
  ),
  testStream('stream-hulu', 'Hulu', 799),
  testStream('stream-electric', 'Electric', 8420, subscription: false),
  // An inflow: negative cents.
  testStream('stream-payroll', 'Payroll', -300000, subscription: false),
  testStream(
    'stream-magazine',
    'Magazine',
    1200,
    status: RecurringStatus.ended,
  ),
];

/// An in-memory stream repository holding [streams] ([testStreams] by default), Hulu
/// muted when it is among them.
InMemoryRecurringStreamRepository seededStreams([
  List<RecurringStream>? streams,
]) {
  final List<RecurringStream> initial = streams ?? testStreams();
  final InMemoryRecurringStreamRepository repository =
      InMemoryRecurringStreamRepository(
        testClock,
        recorder: const NoChangeRecorder(),
        initial: initial,
      );
  if (initial.any((s) => s.id == 'stream-hulu')) {
    // In memory the change is made before the call returns.
    unawaited(repository.setOverride('stream-hulu', (o) => o.withMuted(true)));
  }
  return repository;
}

/// The override that makes [streams] the app's stream repository.
Override streamsOverride(InMemoryRecurringStreamRepository streams) =>
    recurringStreamRepositoryProvider.overrideWithValue(streams);
