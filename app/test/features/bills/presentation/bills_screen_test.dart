// The Bills segment on testClock's today, 24 October 2026: the Overdue, Due soon and
// Later groups and the folded Paused group, Mark paid on the occurrence that is due or
// missed (with Undo), the missed-bill badge on the Plan tab, the calendar's month
// navigation and day selection in America/New_York across a month end, the suggestions'
// Add and Dismiss (remembered on the device) and their Show all after three, and the
// empty state.
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/bill_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/stream_seed.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late InMemoryBillRepository bills;
  late InMemoryAppMetaStore meta;

  Future<void> open(
    WidgetTester tester, {
    List<BillReminder>? initial,
    String location = '/bills',
    Clock? clock,
    bool streams = false,
    List<RecurringStream>? streamList,
    bool keepMeta = false,
  }) async {
    final Clock at = clock ?? testClock;
    bills = InMemoryBillRepository(
      at,
      recorder: const NoChangeRecorder(),
      initial: initial ?? testBills(),
    );
    addTearDown(bills.close);
    if (!keepMeta) meta = InMemoryAppMetaStore();
    await pumpApp(
      tester,
      initialLocation: location,
      clock: at,
      overrides: <Override>[
        storeOverride(seededStore(clock: at)),
        billRepositoryProvider.overrideWithValue(bills),
        appMetaStoreProvider.overrideWithValue(meta),
        if (streams || streamList != null)
          streamsOverride(seededStreams(streamList)),
      ],
    );
  }

  Future<BillReminder> stored(WidgetTester tester, String id) async =>
      (await tester.runAsync(() => bills.watchAll().first))!
          .singleWhere((b) => b.id == id);

  Finder inTile(String name, Finder matching) => find.descendant(
    of: find.widgetWithText(ListTile, name),
    matching: matching,
  );

  testWidgets('groups the bills by when they are due', (tester) async {
    double top(Finder finder) => tester.getTopLeft(finder).dy;
    await open(tester);

    // Overdue, then Due soon, then Later, each by date.
    final List<double> order = [
      top(find.text('Overdue')),
      top(find.text('Rent')),
      top(find.text('Due soon')),
      top(find.text('Water')),
      top(find.text('Phone')),
      top(find.text('Later')),
      top(find.text('Netflix')),
    ];
    expect(order, [...order]..sort());
    expect(inTile('Rent', find.text('Due Oct 1, 2026')), findsOneWidget);
    expect(inTile('Rent', find.text('Missed')), findsOneWidget);
    expect(inTile('Rent', find.text(r'$1,234.57')), findsOneWidget);
    expect(inTile('Phone', find.text('Due in 3 days')), findsOneWidget);
    expect(inTile('Phone', find.text('Mark paid')), findsOneWidget);
    expect(inTile('Water', find.text('Due in 2 days')), findsOneWidget);
    expect(inTile('Water', find.text('Paid')), findsOneWidget);
    expect(inTile('Water', find.text('Mark paid')), findsNothing);
    expect(inTile('Netflix', find.text('Autopay')), findsOneWidget);
    expect(inTile('Netflix', find.text('Due Nov 10, 2026')), findsOneWidget);

    // The paused bill is folded, with no chip and no action.
    expect(find.text('Gym'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Paused (1)'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    // A bill due beyond the 60 days is at the end of Later.
    expect(top(find.text('Insurance')), greaterThan(top(find.text('Netflix'))));
    await tester.tap(find.text('Paused (1)'));
    await tester.pumpAndSettle();
    expect(inTile('Gym', find.text('Paused')), findsOneWidget);
    expect(inTile('Gym', find.text('Missed')), findsNothing);
    expect(inTile('Gym', find.text('Mark paid')), findsNothing);
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Edit bill'), findsOneWidget);
  });

  testWidgets('Mark paid marks the missed occurrence, and Undo unmarks it', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(inTile('Rent', find.text('Mark paid')));
    await tester.pumpAndSettle();
    expect(find.text('Rent marked paid'), findsOneWidget);
    expect((await stored(tester, 'rent')).paidOccurrences, [
      LocalDate(2026, 9, 1),
      LocalDate(2026, 10, 1),
    ]);
    // Paid, its next date is more than a week away.
    expect(find.text('Overdue'), findsNothing);
    expect(inTile('Rent', find.text('Due Nov 1, 2026')), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await stored(tester, 'rent')).paidOccurrences, [
      LocalDate(2026, 9, 1),
    ]);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('Mark paid on a due bill marks the occurrence it shows', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(inTile('Phone', find.text('Mark paid')));
    await tester.pumpAndSettle();
    expect((await stored(tester, 'phone')).paidOccurrences, [
      LocalDate(2026, 10, 27),
    ]);
    expect(inTile('Phone', find.text('Paid')), findsOneWidget);
  });

  testWidgets('a bill due in 7 days is due soon, relatively dated', (
    tester,
  ) async {
    await open(
      tester,
      initial: [testBill('cable', 'Cable', 6543, LocalDate(2026, 10, 31))],
    );

    expect(inTile('Cable', find.text('Due in 7 days')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Cable')).dy,
      greaterThan(tester.getTopLeft(find.text('Due soon')).dy),
    );
    expect(find.text('Later'), findsNothing);
  });

  testWidgets('the Plan tab counts the missed bills, the paused one left out', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await open(tester, location: '/accounts');

    // Read by screen readers with the tab, since the destination's tooltip is not.
    final SemanticsNode tab = tester.getSemantics(
      find.widgetWithText(NavigationDestination, 'Plan'),
    );
    expect(tab.label, contains('1 missed bill'));
    expect(tab.label, contains('Plan'));
    semantics.dispose();
    final Badge badge = tester.widget(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Badge),
      ),
    );
    expect(badge.isLabelVisible, isTrue);
  });

  testWidgets('the calendar moves across a month end in New York', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    // 23:30 on Saturday 31 October in New York, already 1 November in UTC.
    final Clock clock = FixedClock(
      DateTime.utc(2026, 11, 1, 3, 30),
      tz.getLocation('America/New_York'),
    );
    await open(
      tester,
      clock: clock,
      initial: [
        testBill('rent', 'Rent', 123457, LocalDate(2026, 11, 1)),
        testBill('netflix', 'Netflix', 1999, LocalDate(2026, 11, 1)),
        testBill('gym', 'Gym', 3456, LocalDate(2026, 10, 5), active: false),
      ],
    );
    try {
      await tester.tap(find.byTooltip('Calendar'));
      await tester.pumpAndSettle();
      // Today is the 31st, in October, and chosen.
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('No bills due Oct 31, 2026'), findsOneWidget);
      expect(find.bySemanticsLabel('Oct 31, no bills due'), findsOneWidget);
      // The paused gym gets no dot.
      expect(find.bySemanticsLabel('Oct 5, no bills due'), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);
      await tester.tap(
        find.bySemanticsLabel('Nov 1, 2 bills due: Netflix, Rent'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.bySemanticsLabel('Nov 2, no bills due'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);

      await tester.tap(find.byTooltip('List'));
      await tester.pumpAndSettle();
      expect(inTile('Rent', find.text('Due tomorrow')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a suggestion opens the editor prefilled', (tester) async {
    await open(tester, initial: const [], streams: true);

    expect(find.text('Suggested'), findsOneWidget);
    expect(find.text('Every month, next due Nov 3, 2026'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'New bill'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Netflix'), findsOneWidget);
    expect((await tester.runAsync(() => bills.watchAll().first))!, isEmpty);
  });

  testWidgets('shows three suggestions until Show all', (tester) async {
    await open(
      tester,
      initial: const [],
      streamList: [
        for (int i = 1; i <= 5; i++)
          testStream(
            'stream-$i',
            'Service $i',
            1000 + i,
            nextExpected: LocalDate(2026, 11, i),
          ),
      ],
    );

    expect(find.text('Add'), findsNWidgets(3));
    expect(find.text('Service 3'), findsOneWidget);
    expect(find.text('Service 4'), findsNothing);
    await tester.tap(find.text('Show all (5)'));
    await tester.pumpAndSettle();
    expect(find.text('Show all (5)'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Service 5'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Service 4'), findsOneWidget);
    expect(find.text('Service 5'), findsOneWidget);
  });

  testWidgets('a dismissed suggestion stays dismissed on this device', (
    tester,
  ) async {
    await open(tester, initial: const [], streams: true);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Suggested'), findsNothing);
    expect(find.text('No bills yet'), findsOneWidget);
    expect(
      await tester.runAsync(
        () => meta.read(AppMetaKeys.dismissedBillSuggestions),
      ),
      '["stream/stream-netflix"]',
    );

    await open(tester, initial: const [], streams: true, keepMeta: true);
    expect(find.text('Suggested'), findsNothing);
  });

  testWidgets('says when there are no bills', (tester) async {
    await open(tester, initial: const []);

    expect(find.text('No bills yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'New bill'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'New bill'), findsOneWidget);
  });
}
