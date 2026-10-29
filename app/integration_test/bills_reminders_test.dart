// Bills and their reminders on a device, in the demo flavor. Run on the harness's
// emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does, with the persona's two bills; a monthly bill
// due tomorrow is added with a reminder on the day, and the demo's fake scheduler holds
// it at 09:00 tomorrow in the device's zone (and next month's), with the in-app list
// saying it is due. Then
// the real plugin, which every flavor's APK links: one reminder scheduled a minute
// ahead, inexact with idle allowed, is in the platform's pending set and is cancelled
// again. Whether it then fires is not awaited: an inexact alarm may come late, so a
// test cannot wait for it reliably.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/local_notifications_scheduler.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: a bill due tomorrow is reminded at 09:00 on the day', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final List<BillReminder> seeded = await container
        .read(billRepositoryProvider)
        .watchAll()
        .first;
    expect(seeded, hasLength(2));

    container.read(goRouterProvider).go(const BillsRoute().location);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
    await _tap(tester, find.text('New bill'));

    final tz.Location zone = tz.local;
    final tz.TZDateTime now = tz.TZDateTime.now(zone);
    final LocalDate tomorrow = LocalDate(
      now.year,
      now.month,
      now.day,
    ).addDays(1);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Water');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expected amount'),
      // An amount no transaction of the persona's comes near, so none pays tomorrow's
      // occurrence early and drops its reminder (any-account matching, 10 % band).
      '9876.54',
    );
    await _tap(tester, find.text('Choose a due date'));
    await _tap(tester, find.byTooltip('Switch to input'));
    await tester.enterText(
      find.byType(TextField).last,
      DateFormat.yMd().format(tomorrow.toDateTime()),
    );
    await _tap(tester, find.text('OK'));
    await _tap(tester, find.text('On the day'));
    await _tap(tester, find.text('2 days before'));
    await _tap(tester, find.text('Save'));
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);

    // The watcher plans a second after the change.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    final BillReminder water =
        (await container.read(billRepositoryProvider).watchAll().first)
            .singleWhere((b) => b.name == 'Water');
    final List<ScheduledReminder> pending = await container
        .read(reminderSchedulerProvider)
        .pending();
    // Monthly by default: tomorrow's, and next month's, inside the 60 days.
    final List<ScheduledReminder> mine = [
      for (final ScheduledReminder r in pending)
        if (r.billId == water.id) r,
    ]..sort((a, b) => a.at.compareTo(b.at));
    expect(mine.map((r) => r.dueDate), [tomorrow, tomorrow.addMonths(1)]);
    final ScheduledReminder reminder = mine.first;
    expect(
      reminder.at.isAtSameMomentAs(
        tz.TZDateTime(zone, tomorrow.year, tomorrow.month, tomorrow.day, 9),
      ),
      isTrue,
    );
    expect(reminder.title, 'Water is due today');
    expect(reminder.body, r'Expected $9,876.54');
    expect(
      container
          .read(inAppNotificationsProvider)
          .map((n) => n.notification)
          .whereType<BillDueNotification>()
          .map((n) => n.key),
      contains('bill/${water.id}/$tomorrow'),
    );
  });

  testWidgets(
    'the plugin holds a reminder a minute ahead until it is cancelled',
    (tester) async {
      final LocalNotificationsScheduler scheduler = LocalNotificationsScheduler(
        FlutterLocalNotificationsPlugin(),
        channelName: 'Bill reminders',
        channelDescription: 'Reminders before your bills are due',
      );
      final tz.TZDateTime at = tz.TZDateTime.now(tz.local)
          .add(const Duration(minutes: 1));
      final ScheduledReminder reminder = ScheduledReminder(
        id: reminderId('harness', LocalDate(at.year, at.month, at.day), 0),
        billId: 'harness',
        dueDate: LocalDate(at.year, at.month, at.day),
        at: at,
        title: 'Harness bill is due today',
        body: 'Expected nothing',
      );
      await scheduler.replaceAll([reminder]);
      final List<ScheduledReminder> pending = await scheduler.pending();
      expect(pending.map((r) => r.id), contains(reminder.id));
      final ScheduledReminder back = pending.singleWhere(
        (r) => r.id == reminder.id,
      );
      expect(back.billId, 'harness');
      expect(back.at.millisecondsSinceEpoch, at.millisecondsSinceEpoch);
      await scheduler.cancelAll();
      expect(await scheduler.pending(), isEmpty);
    },
  );
}
