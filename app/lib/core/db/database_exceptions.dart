/// The failures of the local database and its repositories that callers handle by type.
///
/// The three open failures ([EncryptionUnavailableException], [DatabaseKeyMismatchException],
/// [DatabaseKeyLostException]) stop startup: `bootstrap` logs the type and shows a plain
/// error screen; Phase 7's restore flow handles a lost key. [EntityDeletedException] is a
/// write to a record that was deleted; [BankDataNotDeletableException] a delete of a
/// linked account or a Plaid transaction; [TransactionBatchException] a batch write that
/// one of its transactions refused. Two argument errors are typed so a batch can tell
/// them from any other: [AuditInstantError] and [PlaidOverridesOnlyError]. Pure Dart: these are thrown in the database's
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

/// Whether [error] is one of the three failures to open the database.
bool isDatabaseOpenFailure(Object error) =>
    error is EncryptionUnavailableException ||
    error is DatabaseKeyMismatchException ||
    error is DatabaseKeyLostException;

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

/// A delete named a linked account (one with an Item) or a Plaid transaction. Bank data
/// is the server's (`PLAN.md` §6.4): a linked account goes only when its Item is
/// unlinked, and a Plaid transaction only when the bank removes it.
final class BankDataNotDeletableException implements Exception {
  /// The exception for the [entity] (`account` or `transaction`) with id [id].
  const BankDataNotDeletableException(this.entity, this.id);

  /// The kind of record.
  final String entity;

  /// The record's id.
  final String id;

  @override
  String toString() =>
      'BankDataNotDeletableException: $entity $id comes from the bank';
}

/// A transaction's `createdAt` or `updatedAt` ([name]) is not a UTC instant with
/// millisecond precision, the only audit instants stored (`PLAN.md` §12).
final class AuditInstantError extends ArgumentError {
  /// The error for audit instant [value], named [name], and why.
  AuditInstantError(
    DateTime super.value,
    String super.name,
    String super.message,
  ) : super.value();
}

/// A batch write changed something on `plaid` transaction [transactionId] besides the
/// fields the user owns: Plaid's [field], or, when [field] is null, the transaction is
/// not stored (only the Plaid pull creates one).
final class PlaidOverridesOnlyError extends ArgumentError {
  /// The error for [transactionId], naming the Plaid [field] it changed, if any.
  PlaidOverridesOnlyError(this.transactionId, {this.field})
    : super.value(
        field ?? transactionId,
        field == null ? 'transaction' : 'field',
        field == null
            ? 'a plaid transaction is created only by the Plaid pull'
            : "is Plaid's on plaid transaction $transactionId",
      );

  /// The `plaid` transaction.
  final String transactionId;

  /// The record field of Plaid's it changed, or null when it is not stored.
  final String? field;
}

/// A batch write of transactions (`TransactionRepository.upsertAll` or `deleteAll`)
/// refused transaction [transactionId], so nothing in the batch was written. [cause] is
/// the failure that transaction alone would have raised: `AccountNotFoundException`,
/// `CurrencyMismatchException`, [EntityDeletedException],
/// [BankDataNotDeletableException], [AuditInstantError], or [PlaidOverridesOnlyError]
/// (a changed Plaid field on a `plaid` row, which it names). Any other error propagates
/// as itself.
final class TransactionBatchException implements Exception {
  /// The exception for transaction [transactionId], refused for [cause].
  const TransactionBatchException(this.transactionId, this.cause);

  /// The id of the transaction that was refused.
  final String transactionId;

  /// Why it was refused.
  final Object cause;

  @override
  String toString() =>
      'TransactionBatchException: transaction $transactionId refused '
      '(${cause.runtimeType})';
}
