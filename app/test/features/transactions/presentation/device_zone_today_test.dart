// "Today" is the device zone's, not UTC's: at 04:30 UTC on 8 March 2026 it is still
// 7 March in New York, so the list's "Today" is the 7th, "Yesterday" the 6th, and a new
// transaction is dated the 7th.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late Clock clock;
  late InMemoryStore store;

  setUp(() {
    clock = FixedClock(
      DateTime.utc(2026, 3, 8, 4, 30),
      tz.getLocation('America/New_York'),
    );
    store = seededStore(seed: const DemoSeed.empty(), clock: clock);
    final DemoSeed seed = buildDemoSeed(testClock.today());
    store.upsertAccount(seed.accounts.first);
    for (final (String id, LocalDate date) in [
      ('on-7th', LocalDate(2026, 3, 7)),
      ('on-6th', LocalDate(2026, 3, 6)),
    ]) {
      store.upsertTransaction(
        testTransaction(id, name: id).copyWith(date: date),
      );
    }
  });

  testWidgets("the list's Today and Yesterday are the device zone's", (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(store)],
      clock: clock,
    );

    expect(
      tester.getTopLeft(find.text('Today')).dy,
      lessThan(tester.getTopLeft(find.text('on-7th')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Yesterday')).dy,
      lessThan(tester.getTopLeft(find.text('on-6th')).dy),
    );
    expect(
      tester.getTopLeft(find.text('on-7th')).dy,
      lessThan(tester.getTopLeft(find.text('Yesterday')).dy),
    );
  });

  testWidgets("a new transaction is dated the device zone's today", (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/transactions/new',
      overrides: [storeOverride(store)],
      clock: clock,
      size: const Size(412, 1600),
    );

    expect(find.text('Mar 7, 2026'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '1');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Late snack',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      store.transactions(TransactionQuery(text: 'Late snack')).single.date,
      LocalDate(2026, 3, 7),
    );
  });
}
