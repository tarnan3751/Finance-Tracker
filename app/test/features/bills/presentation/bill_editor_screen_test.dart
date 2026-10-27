// The bill editor: what it refuses before saving, a new bill saved with its reminders,
// the permission asked when reminders are on and the sheet when it is refused (Open
// settings, the bill saved first), an edit that keeps the paid marks, and a delete with
// undo, also from an editor pushed on another tab.
import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  late InMemoryBillRepository bills;
  late FakeReminderScheduler scheduler;

  final BillReminder rent = BillReminder(
    id: 'rent',
    name: 'Rent',
    amount: Money(-150000, 'USD'),
    dueDate: LocalDate(2026, 11, 1),
    cadence: RecurringCadence.monthly,
    accountId: checkingId,
    paidOccurrences: [LocalDate(2026, 10, 1)],
  );

  Future<void> open(
    WidgetTester tester,
    String location, {
    List<BillReminder> initial = const [],
    bool granted = true,
  }) async {
    bills = InMemoryBillRepository(
      testClock,
      recorder: const NoChangeRecorder(),
      initial: initial,
    );
    addTearDown(bills.close);
    scheduler = FakeReminderScheduler(granted: granted, grantOnRequest: false);
    await pumpApp(
      tester,
      initialLocation: location,
      overrides: [
        storeOverride(seededStore()),
        billRepositoryProvider.overrideWithValue(bills),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
  }

  Future<List<BillReminder>> live(WidgetTester tester) async =>
      (await tester.runAsync(() => bills.watchAll().first))!;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('refuses to save without a name or a due date', (tester) async {
    await open(tester, '/bills/new');
    await save(tester);
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Choose a due date'), findsNWidgets(2));
    expect(await live(tester), isEmpty);
    await tester.enterText(_field('Expected amount'), '-5');
    await save(tester);
    expect(find.text('Enter the amount without a sign'), findsOneWidget);
  });

  testWidgets('saves a new bill with its reminders', (tester) async {
    await open(tester, '/bills/new');
    await tester.enterText(_field('Name'), 'Electric');
    await tester.enterText(_field('Expected amount'), '84.20');
    await tester.tap(find.text('Choose a due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 day before'));
    await tester.tap(find.text('2 days before'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Paid automatically'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Paid automatically'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(find.widgetWithText(AppBar, 'Bills'), findsOneWidget);
    final BillReminder saved = (await live(tester)).single;
    expect(saved.name, 'Electric');
    expect(saved.amount, Money(-8420, 'USD'));
    expect(saved.dueDate, LocalDate(2026, 10, 28));
    expect(saved.cadence, RecurringCadence.monthly);
    expect(saved.accountId, isNull);
    expect(saved.reminderOffsetDays, [1]);
    expect(saved.reminderMinutes, 540);
    expect(saved.active, isTrue);
    expect(saved.autopay, isTrue);
    expect(scheduler.permissionRequests, 0, reason: 'already granted');
  });

  testWidgets('a refused permission is explained, with Open settings', (
    tester,
  ) async {
    await open(tester, '/bills/rent', initial: [rent], granted: false);
    await tester.enterText(_field('Name'), 'Rent and parking');
    await save(tester);
    expect(scheduler.permissionRequests, 1);
    expect(find.text('Notifications are off'), findsOneWidget);
    // Saved before the sheet says so.
    expect((await live(tester)).single.name, 'Rent and parking');
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(scheduler.settingsOpened, 1);
    final BillReminder saved = (await live(tester)).single;
    expect(saved.name, 'Rent and parking');
    expect(saved.paidOccurrences, [LocalDate(2026, 10, 1)]);
    expect(saved.accountId, checkingId);
  });

  testWidgets('no reminder asks for nothing', (tester) async {
    await open(tester, '/bills/rent', initial: [rent], granted: false);
    await tester.tap(find.text('2 days before'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(scheduler.permissionRequests, 0);
    expect(find.text('Notifications are off'), findsNothing);
    expect((await live(tester)).single.reminderOffsetDays, isEmpty);
  });

  testWidgets('the reminder time comes from the time picker', (tester) async {
    await open(tester, '/bills/rent', initial: [rent]);
    await tester.scrollUntilVisible(
      find.text('Reminder time'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('9:00 AM'), findsOneWidget);
    await tester.tap(find.text('9:00 AM'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to text input mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '7');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('PM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('7:45 PM'), findsOneWidget);
    await save(tester);
    expect((await live(tester)).single.reminderMinutes, 19 * 60 + 45);
  });

  testWidgets('deletes with an undo', (tester) async {
    await open(tester, '/bills/rent', initial: [rent]);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Bills'), findsOneWidget);
    expect(await live(tester), isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(await live(tester), [rent]);
  });

  testWidgets(
    'a delete from a reminder opened on another tab shows its undo there',
    (tester) async {
      await open(tester, '/accounts', initial: [rent]);
      unawaited(
        GoRouter.of(tester.element(find.byType(NavigationBar)))
            .push<void>(const EditBillRoute('rent').location),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Edit bill'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
      expect(find.text('Bill deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(await live(tester), [rent]);
    },
  );

  testWidgets('a deleted bill says so', (tester) async {
    await open(tester, '/bills/missing');
    expect(find.text('This bill no longer exists.'), findsOneWidget);
  });
}
