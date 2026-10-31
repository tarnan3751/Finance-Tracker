// The messenger of a snack bar raised after an await (core/widgets/visible_messenger.dart):
// on an expanded window, a refused save's message shows in the pane of the editor that
// stays, and a delete's Undo in the tab's screen beside the list once the editor has
// closed, each where the user can reach it; a delete's Undo raised after the user chose
// another tab during the awaited write shows on that tab, through the shell; and on a
// bare two-tab stack, the message of a screen that closed while another tab was chosen
// shows on that tab, the pane's staying with its own.
import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/widgets/visible_messenger.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/bills/presentation/bills_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

Finder _inEnd(Finder finder) => find.descendant(
  of: find.byWidgetPredicate((w) => w is PaneScope && w.role == PaneRole.end),
  matching: finder,
);

/// Bills whose saves are refused as of a bill deleted on another device.
final class _RefusingBills extends InMemoryBillRepository {
  _RefusingBills(super.clock, {required super.recorder, super.initial});

  @override
  Future<void> upsert(BillReminder bill) async =>
      throw EntityDeletedException('bill', bill.id);
}

/// Bills whose deletes wait for [release].
final class _SlowBills extends InMemoryBillRepository {
  _SlowBills(super.clock, {required super.recorder, super.initial});

  final Completer<void> release = Completer<void>();

  @override
  Future<void> delete(String id) async {
    await release.future;
    await super.delete(id);
  }
}

void main() {
  final BillReminder rent = BillReminder(
    id: 'rent',
    name: 'Rent',
    amount: Money(-150000, 'USD'),
    dueDate: LocalDate(2026, 11, 1),
    cadence: RecurringCadence.monthly,
    accountId: checkingId,
  );

  late InMemoryBillRepository bills;

  Future<void> open(
    WidgetTester tester,
    String location, {
    bool refusing = false,
  }) async {
    bills = (refusing ? _RefusingBills.new : InMemoryBillRepository.new)(
      testClock,
      recorder: const NoChangeRecorder(),
      initial: [rent],
    );
    addTearDown(bills.close);
    await pumpApp(
      tester,
      initialLocation: location,
      size: expandedSize,
      overrides: [
        storeOverride(seededStore()),
        billRepositoryProvider.overrideWithValue(bills),
        reminderSchedulerProvider.overrideWithValue(
          FakeReminderScheduler(granted: true),
        ),
      ],
    );
  }

  testWidgets('a refused save shows in the pane of the editor that stays', (
    tester,
  ) async {
    await open(tester, '/bills/rent', refusing: true);
    expect(find.byType(BillsScreen), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Edit bill'), findsOneWidget);
    expect(
      _inEnd(find.text('This bill no longer exists.')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets("a delete's undo shows beside the list once the editor closed", (
    tester,
  ) async {
    await open(tester, '/bills/rent');
    await tester.tap(_inEnd(find.byTooltip('Delete')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Edit bill'), findsNothing);
    expect(_inEnd(find.text('Bill deleted')).hitTestable(), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(
      (await tester.runAsync(() => bills.watchAll().first))!.map((b) => b.id),
      ['rent'],
    );
  });

  testWidgets(
    'a delete whose write lands on another tab shows its undo there',
    (tester) async {
      final _SlowBills slow = _SlowBills(
        testClock,
        recorder: const NoChangeRecorder(),
        initial: [rent],
      );
      addTearDown(slow.close);
      await pumpApp(
        tester,
        initialLocation: '/bills/rent',
        overrides: [
          storeOverride(seededStore()),
          billRepositoryProvider.overrideWithValue(slow),
          reminderSchedulerProvider.overrideWithValue(
            FakeReminderScheduler(granted: true),
          ),
        ],
      );
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Accounts'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);

      slow.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('Bill deleted').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('after a close the message goes to the tab chosen meanwhile', (
    tester,
  ) async {
    final List<GlobalKey<ScaffoldMessengerState>> tabs = [
      GlobalKey<ScaffoldMessengerState>(),
      GlobalKey<ScaffoldMessengerState>(),
    ];
    int selected = 0;
    late StateSetter select;
    await tester.pumpWidget(
      MaterialApp(
        home: SelectedTabMessenger(
          current: () => tabs[selected].currentState,
          child: StatefulBuilder(
            builder: (context, setState) {
              select = setState;
              return IndexedStack(
                index: selected,
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    ScaffoldMessenger(
                      key: tabs[i],
                      child: Scaffold(body: Text('Tab $i')),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    final VisibleMessenger messenger = VisibleMessenger.of(
      tester.element(find.text('Tab 0')),
    );

    select(() => selected = 1);
    await tester.pumpAndSettle();
    messenger.afterClose.showSnackBar(const SnackBar(content: Text('Closed')));
    messenger.pane.showSnackBar(const SnackBar(content: Text('Stayed')));
    await tester.pumpAndSettle();
    expect(find.text('Closed').hitTestable(), findsOneWidget);
    expect(find.text('Stayed').hitTestable(), findsNothing);
    expect(identical(messenger.pane, tabs[0].currentState), isTrue);
  });
}
