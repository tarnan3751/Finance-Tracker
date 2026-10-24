/// A write that needs a live account named one that does not exist or is deleted.
library;

/// No live account [accountId].
final class AccountNotFoundException implements Exception {
  /// The exception for [accountId].
  const AccountNotFoundException(this.accountId);

  /// The id that was looked up.
  final String accountId;

  @override
  String toString() => 'AccountNotFoundException: no live account $accountId';
}
