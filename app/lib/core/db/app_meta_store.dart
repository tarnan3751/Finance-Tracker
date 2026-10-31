/// Facts about this install, kept in the `app_meta` table: whether the original app's data
/// was imported (`legacy_import_done`), the install date (`install_date`), the zone and
/// time the bill reminders were last planned in (`reminders_zone`,
/// `reminders_scheduled_at`), the bill suggestions dismissed on this device
/// (`bill_suggestions_dismissed`), the forecast's account selection
/// (`forecast_selection`), the last day the balance snapshots were written
/// (`snapshots_written_on`), the anomaly flags dismissed on this device
/// (`dismissed_anomalies`), the last week whose summary was announced
/// (`weekly_summary_raised`), the payoff projections' entries (`payoff_entries`), when
/// the restore offer was answered (`restore_offer_answered`), the app lock's settings
/// (`lock_enabled`, `lock_timeout_seconds`, `secure_screen`), the language the app is shown
/// in (`app_language`), the background sync's switch, last run and remote sign-out
/// (`background_sync_enabled`, `background_last_run`, `session_ended_in_background`), and
/// whether the permission to notify was asked (`notification_permission_asked`) and which
/// sync problems were told (`sync_problems_told`).
library;

import 'package:finance_tracker/core/db/app_database.dart';

/// Reads and writes install facts by key.
abstract interface class AppMetaStore {
  /// The value under [key], or null.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any value there.
  Future<void> write(String key, String value);
}

/// The keys of [AppMetaStore].
abstract final class AppMetaKeys {
  /// Set once the legacy importer has run (`legacy_import/`).
  static const String legacyImportDone = 'legacy_import_done';

  /// The local date of the first launch, `yyyy-MM-dd`.
  static const String installDate = 'install_date';

  /// The IANA zone the bill reminders were last planned in (`features/bills/`).
  static const String remindersZone = 'reminders_zone';

  /// When the bill reminders were last planned, a UTC instant.
  static const String remindersScheduledAt = 'reminders_scheduled_at';

  /// The keys of the bill suggestions dismissed on this device, a JSON array of strings
  /// (`features/bills/`).
  static const String dismissedBillSuggestions = 'bill_suggestions_dismissed';

  /// The forecast's account selection on this device, as the JSON of its changes from
  /// the default (`features/forecast/`).
  static const String forecastSelection = 'forecast_selection';

  /// The last local date the balance snapshots were written, `yyyy-MM-dd`
  /// (`features/net_worth/`).
  static const String snapshotsWrittenOn = 'snapshots_written_on';

  /// The ids of the transactions whose anomaly flags were dismissed on this device, a
  /// JSON array of strings (`features/reports/`).
  static const String dismissedAnomalies = 'dismissed_anomalies';

  /// The Monday of the last week whose summary was announced, `yyyy-MM-dd`
  /// (`features/reports/`).
  static const String weeklySummaryRaised = 'weekly_summary_raised';

  /// The payments, rates and extras entered for the payoff projections on this device,
  /// a JSON object keyed by account id (`features/net_worth/`).
  static const String payoffEntries = 'payoff_entries';

  /// When this install answered the restore offer, a UTC instant
  /// (`features/backup/`).
  static const String restoreOfferAnswered = 'restore_offer_answered';

  /// Whether the app lock is enabled on this device, `true` or `false`
  /// (`features/lock/`).
  static const String lockEnabled = 'lock_enabled';

  /// How long the app may stay in the background before it locks, in seconds, or `off`
  /// (`features/lock/`).
  static const String lockTimeoutSeconds = 'lock_timeout_seconds';

  /// Whether "Block screenshots" is on, `true` or `false`; absent until the user chooses,
  /// when the flavor's default holds (`features/lock/`).
  static const String secureScreen = 'secure_screen';

  /// The language the app is shown in on this device, an `AppLanguage` name; absent
  /// until chosen, when the device's language holds (`features/settings/`).
  static const String appLanguage = 'app_language';

  /// Whether the background sync is on, `true` or `false`; absent means on
  /// (`core/background/`).
  static const String backgroundSyncEnabled = 'background_sync_enabled';

  /// The background sync's last run, a JSON object `{at, result, delegated}`: the UTC
  /// instant, a `BackgroundResult` name, and whether the app ran it (`core/background/`).
  static const String backgroundLastRun = 'background_last_run';

  /// When the background sync found the session ended on the server, a UTC instant, or
  /// empty once the app has told the user (`core/background/`).
  static const String sessionEndedInBackground = 'session_ended_in_background';

  /// When this device asked for the permission to notify, a UTC instant; it is asked
  /// once (`core/platform/notification_providers.dart`).
  static const String notificationPermissionAsked =
      'notification_permission_asked';

  /// The sync problems this device has told the user, a JSON list of their
  /// notification keys, each dropped once its problem clears (`core/sync/`).
  static const String syncProblemsTold = 'sync_problems_told';
}

/// The store over the database's `app_meta` table.
final class DriftAppMetaStore implements AppMetaStore {
  /// The store over [database].
  DriftAppMetaStore(this._database);

  final AppDatabase _database;

  @override
  Future<String?> read(String key) async {
    final AppMetaRow? row = await (_database.select(
      _database.appMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> write(String key, String value) => _database
      .into(_database.appMeta)
      .insertOnConflictUpdate(AppMetaCompanion.insert(key: key, value: value));
}

/// The store in memory, for tests and the demo flavor.
final class InMemoryAppMetaStore implements AppMetaStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
