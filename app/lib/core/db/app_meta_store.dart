/// Facts about this install, kept in the `app_meta` table: whether the original app's data
/// was imported (`legacy_import_done`), the install date (`install_date`), the zone and
/// time the bill reminders were last planned in (`reminders_zone`,
/// `reminders_scheduled_at`), the bill suggestions dismissed on this device
/// (`bill_suggestions_dismissed`), the forecast's account selection
/// (`forecast_selection`), and the last day the balance snapshots were written
/// (`snapshots_written_on`).
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
