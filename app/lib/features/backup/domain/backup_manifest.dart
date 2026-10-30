/// The manifest that opens a backup's plaintext (`docs/reference/backup.md`, **The
/// content**): what made it and what it holds. Pure Dart, no Flutter import.
library;

import 'package:finance_tracker/features/backup/domain/backup_format.dart';

/// A backup's manifest.
final class BackupManifest {
  /// The manifest.
  const BackupManifest({
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.userId,
    required this.deviceId,
    required this.tables,
    required this.receipts,
    required this.dumpSha256,
    this.formatVersion = backupFormatVersion,
  });

  /// Reads [json]; throws [BackupDamagedException] when it is not a manifest.
  factory BackupManifest.fromJson(Object? json) {
    try {
      final Map<String, Object?> m = json! as Map<String, Object?>;
      if (m['format'] != 'FTBK') throw const BackupDamagedException();
      final DateTime createdAt = DateTime.parse(m['created_at']! as String);
      if (!createdAt.isUtc) throw const BackupDamagedException();
      return BackupManifest(
        formatVersion: m['format_version']! as int,
        schemaVersion: m['schema_version']! as int,
        appVersion: m['app_version']! as String,
        createdAt: createdAt,
        userId: m['user_id'] as String?,
        deviceId: m['device_id'] as String?,
        tables: {
          for (final MapEntry<String, Object?> e
              in (m['tables']! as Map<String, Object?>).entries)
            e.key: e.value! as int,
        },
        receipts: m['receipts']! as int,
        dumpSha256: m['dump_sha256']! as String,
      );
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupDamagedException();
    }
  }

  /// The archive's format version.
  final int formatVersion;

  /// The database schema version the tables were dumped at.
  final int schemaVersion;

  /// The app's version and build that made the backup (`1.0.0+1`).
  final String appVersion;

  /// When the backup was made, UTC.
  final DateTime createdAt;

  /// The install's user (the first account signed in on it), null for an install that
  /// never signed in.
  final String? userId;

  /// The source device's sync node (`sync_meta.device_id`), null when it had none.
  final String? deviceId;

  /// Each table's row count, in dump order.
  final Map<String, int> tables;

  /// How many receipt files follow the tables.
  final int receipts;

  /// The SHA-256 of the dump (the table lines), lowercase hex.
  final String dumpSha256;

  /// The rows in every table.
  int get rowCount => tables.values.fold(0, (a, b) => a + b);

  /// The JSON form, keys in this fixed order.
  Map<String, Object?> toJson() => {
    'format': 'FTBK',
    'format_version': formatVersion,
    'schema_version': schemaVersion,
    'app_version': appVersion,
    'created_at': createdAt.toIso8601String(),
    'user_id': userId,
    'device_id': deviceId,
    'tables': tables,
    'receipts': receipts,
    'dump_sha256': dumpSha256,
  };
}
