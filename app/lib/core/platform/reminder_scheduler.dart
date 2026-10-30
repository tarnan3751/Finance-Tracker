/// The platform boundary for bill reminders (`docs/reference/app-core.md`, **Reminders**;
/// `docs/reference/bills.md`): the app hands a [ReminderScheduler] the whole set of
/// reminders it wants pending and the scheduler makes the platform's set match.
/// `flutter_local_notifications` is behind it in dev and prod
/// (`local_notifications_scheduler.dart`); a fake stands in for the demo flavor and the
/// tests (`fake_reminder_scheduler.dart`). The instants are computed by the app
/// (`features/bills/domain/reminder_times.dart`); the platform keeps the instant it was
/// given and does not follow a zone change, which the planner corrects by scheduling
/// again. Pure Dart, no Flutter import.
library;

import 'dart:convert';

import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules the bill reminders on the device.
abstract interface class ReminderScheduler {
  /// Whether reminders can be shown; when they cannot and [request] is true, asks the
  /// user first (Android 13's notification permission). Asked only from the user's own
  /// action of turning a reminder on, never at startup.
  Future<bool> ensurePermission({required bool request});

  /// Makes [reminders] the pending set: those pending and not among them are cancelled,
  /// the rest scheduled (or rescheduled, by id). A notification already shown stays.
  Future<void> replaceAll(List<ScheduledReminder> reminders);

  /// The reminders pending now, by id; their [ScheduledReminder.at] is in UTC.
  Future<List<ScheduledReminder>> pending();

  /// Cancels every pending reminder; a notification already shown stays.
  Future<void> cancelAll();

  /// Cancels every pending reminder and removes every notification the app has shown,
  /// whatever its kind: the local wipe's, since a bill's name in the tray is data.
  Future<void> clearAll();

  /// Opens the system's notification settings for the app.
  Future<void> openSettings();

  /// The bills whose reminder the user tapped, the one that launched the app first.
  Stream<String> get openedBillIds;
}

/// One reminder: bill [billId]'s occurrence due [dueDate], shown at [at] with [title] and
/// [body] (already localized). [id] is the platform's notification id ([reminderId]).
final class ScheduledReminder {
  /// The reminder.
  const ScheduledReminder({
    required this.id,
    required this.billId,
    required this.dueDate,
    required this.at,
    required this.title,
    required this.body,
  });

  /// The reminder a [payload] (and the platform's [id], [title] and [body]) describe, or
  /// null when the payload is not one of [ReminderScheduler]'s.
  static ScheduledReminder? fromPayload(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    if (payload == null) return null;
    try {
      final Object? json = jsonDecode(payload);
      if (json case {
        'bill': final String bill,
        'due': final String due,
        'at': final String at,
      }) {
        return ScheduledReminder(
          id: id,
          billId: bill,
          dueDate: LocalDate.parse(due),
          at: tz.TZDateTime.from(
            const UtcInstantConverter().fromJson(at),
            tz.UTC,
          ),
          title: title ?? '',
          body: body ?? '',
        );
      }
    } on FormatException {
      // Not ours.
    }
    return null;
  }

  /// The platform's notification id.
  final int id;

  /// The bill.
  final String billId;

  /// The occurrence it reminds of.
  final LocalDate dueDate;

  /// When it goes off.
  final tz.TZDateTime at;

  /// The notification's title.
  final String title;

  /// The notification's text.
  final String body;

  /// What the notification carries: `{"bill", "due", "at"}` as JSON, `at` a UTC
  /// instant.
  String get payload => jsonEncode({
    'bill': billId,
    'due': dueDate.toIso(),
    'at': const UtcInstantConverter().toJson(
      DateTime.fromMillisecondsSinceEpoch(
        at.millisecondsSinceEpoch,
        isUtc: true,
      ),
    ),
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.billId == billId &&
      other.dueDate == dueDate &&
      other.at.isAtSameMomentAs(at) &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode =>
      Object.hash(id, billId, dueDate, at.millisecondsSinceEpoch, title, body);

  @override
  String toString() =>
      'ScheduledReminder($id, $billId, $dueDate, ${at.toIso8601String()})';
}

/// The notification id of bill [billId]'s reminder [offset] days before its occurrence
/// due [due]: a 32-bit FNV-1a hash of the three, masked to 31 bits, so it is stable
/// across runs and devices and always a valid platform id.
int reminderId(String billId, LocalDate due, int offset) {
  int hash = 0x811c9dc5;
  for (final int unit in utf8.encode('$billId|${due.toIso()}|$offset')) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
