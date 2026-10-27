/// Which [ReminderScheduler] schedules the bill reminders: the fake by default (the demo
/// flavor and the tests), `flutter_local_notifications` in dev and prod (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_scheduler_provider.g.dart';

/// The reminder scheduler.
@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) {
  final FakeReminderScheduler scheduler = FakeReminderScheduler();
  ref.onDispose(scheduler.close);
  return scheduler;
}
