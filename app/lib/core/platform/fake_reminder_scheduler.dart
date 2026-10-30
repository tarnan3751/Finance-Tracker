/// The [ReminderScheduler] of the demo flavor and the tests: the pending set kept in
/// memory, the permission set by the test (granted in the demo), and taps and firings
/// a test plays.
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/reminder_scheduler.dart';

/// Reminders without a platform.
final class FakeReminderScheduler implements ReminderScheduler {
  /// A scheduler whose permission is [granted]; a request grants it when
  /// [grantOnRequest].
  FakeReminderScheduler({this.granted = true, this.grantOnRequest = true});

  /// Whether reminders can be shown.
  bool granted;

  /// Whether asking the user grants the permission.
  bool grantOnRequest;

  /// How many times the user was asked.
  int permissionRequests = 0;

  /// How many times the settings were opened.
  int settingsOpened = 0;

  /// Every set [replaceAll] was given, in order.
  final List<List<ScheduledReminder>> replaced = [];

  /// The reminders [fire] showed, in order.
  final List<ScheduledReminder> fired = [];

  /// How many times [clearAll] ran.
  int cleared = 0;

  final Map<int, ScheduledReminder> _pending = {};
  final StreamController<String> _opened = StreamController<String>.broadcast();

  @override
  Future<bool> ensurePermission({required bool request}) async {
    if (!granted && request) {
      permissionRequests++;
      granted = grantOnRequest;
    }
    return granted;
  }

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {
    replaced.add(List.unmodifiable(reminders));
    _pending
      ..clear()
      ..addEntries([for (final r in reminders) MapEntry(r.id, r)]);
  }

  @override
  Future<List<ScheduledReminder>> pending() async =>
      [..._pending.values]..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<void> cancelAll() async => _pending.clear();

  @override
  Future<void> clearAll() async {
    _pending.clear();
    cleared++;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Stream<String> get openedBillIds => _opened.stream;

  /// Shows pending reminder [id] as the platform would at its time: it stops being
  /// pending. Returns it, or null when none is pending with that id.
  ScheduledReminder? fire(int id) {
    final ScheduledReminder? reminder = _pending.remove(id);
    if (reminder != null) fired.add(reminder);
    return reminder;
  }

  /// Plays the user tapping a reminder of bill [billId].
  void tap(String billId) => _opened.add(billId);

  /// Ends [openedBillIds].
  Future<void> close() => _opened.close();
}
