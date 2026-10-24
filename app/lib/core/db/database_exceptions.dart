/// The failures of the local database and its repositories that callers handle by type.
///
/// The three open failures ([EncryptionUnavailableException], [DatabaseKeyMismatchException],
/// [DatabaseKeyLostException]) stop startup: `bootstrap` logs the type and shows a plain
/// error screen; Phase 7's restore flow handles a lost key. [EntityDeletedException] is a
/// write to a record that was deleted. Pure Dart: these are thrown in the database's
/// background isolate and sent back to the caller.
library;

/// The SQLite library has no encryption: `PRAGMA cipher` returned no row. The app never
/// runs on a plain database in dev or prod (only the dev escape hatch opens one).
final class EncryptionUnavailableException implements Exception {
  /// The exception.
  const EncryptionUnavailableException();

  @override
  String toString() =>
      'EncryptionUnavailableException: the SQLite library has no cipher';
}

/// The database file cannot be read with the key it was opened with: the key is wrong, or
/// the file is not a database encrypted by this app.
final class DatabaseKeyMismatchException implements Exception {
  /// The exception.
  const DatabaseKeyMismatchException();

  @override
  String toString() =>
      'DatabaseKeyMismatchException: the database does not open with this key';
}

/// The database file exists but its key is gone or cannot be read: absent from secure
/// storage, unreadable (secure storage failed to decrypt it), or malformed. The data is
/// unreadable without it; nothing is deleted.
final class DatabaseKeyLostException implements Exception {
  /// The exception, with the storage failure that caused it when there was one.
  const DatabaseKeyLostException([this.cause]);

  /// The secure storage error, or null when the key was simply absent or malformed.
  final Object? cause;

  @override
  String toString() =>
      'DatabaseKeyLostException: the database key is missing or unreadable'
      '${cause == null ? '' : ' (${cause.runtimeType})'}';
}

/// A write named a record that has been deleted. A deleted record comes back only through
/// its repository's `restore`; deletes win over edits, as they will in Phase 2's sync.
final class EntityDeletedException implements Exception {
  /// The exception for the [entity] (such as `account`) with id [id].
  const EntityDeletedException(this.entity, this.id);

  /// The kind of record.
  final String entity;

  /// The record's id.
  final String id;

  @override
  String toString() => 'EntityDeletedException: $entity $id is deleted';
}
