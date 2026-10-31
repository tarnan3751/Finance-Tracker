/// The platform boundary for the app's notification channels and its permission to
/// notify (`docs/reference/background.md`, **Notifications**): the four channels with
/// fixed ids, created (or renamed into the current locale) at every start; whether the
/// app and each channel may show anything; and the system's settings for the app and for one channel. `flutter_local_notifications`
/// and the app's own channel to `MainActivity` are behind it in dev and prod
/// (`local_notification_channels.dart`); a fake whose state a test sets stands in for the
/// demo flavor and the tests (`fake_notification_channels.dart`). Pure Dart, no Flutter
/// import.
library;

/// How loudly a channel's notifications come.
enum ChannelImportance {
  /// In the tray, no sound.
  low,

  /// In the tray, with the default sound.
  standard,
}

/// The app's channels. Android never changes a created channel's importance, so an id
/// keeps its importance for good (`bill_reminders` was created at the default in Phase 5).
enum AppChannel {
  /// A budget reached a threshold.
  budgetAlerts('budget_alerts', ChannelImportance.standard),

  /// A bill is due.
  billReminders('bill_reminders', ChannelImportance.standard),

  /// The week's summary is ready.
  weeklySummary('weekly_summary', ChannelImportance.low),

  /// Sync has failed for a day, the session ended, or a bank needs attention.
  syncProblems('sync_problems', ChannelImportance.standard);

  const AppChannel(this.id, this.importance);

  /// The platform's id.
  final String id;

  /// Its importance.
  final ChannelImportance importance;
}

/// A channel's name and description in the system's settings, localized.
typedef ChannelText = ({String name, String description});

/// What the app may show.
final class NotificationsState {
  const NotificationsState({required this.appEnabled, required this.blocked});

  /// Whether the app may notify at all (the permission, or the app's switch).
  final bool appEnabled;

  /// The channels the user turned off.
  final Set<AppChannel> blocked;

  /// Whether [channel]'s notifications are shown.
  bool shows(AppChannel channel) => appEnabled && !blocked.contains(channel);
}

/// The channels and the permission.
abstract interface class NotificationChannels {
  /// Creates each channel with [texts]' name and description, or renames it: idempotent.
  Future<void> ensure(Map<AppChannel, ChannelText> texts);

  /// What the app and each channel may show now.
  Future<NotificationsState> state();

  /// Opens the system's notification settings of [channel].
  Future<void> openChannelSettings(AppChannel channel);

  /// Opens the system's notification settings of the app.
  Future<void> openAppSettings();
}
