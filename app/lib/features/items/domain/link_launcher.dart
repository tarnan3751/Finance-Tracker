/// The platform boundary for Plaid Link (`docs/reference/items.md`, **The launcher**):
/// the app hands a link token to a [LinkLauncher] and gets back what the user did.
/// `plaid_flutter` is behind it in dev and prod; a fake stands in for the tests, the demo
/// flavor and `FT_FAKE_SERVER`, since Link's UI cannot be driven there. Pure Dart, no
/// Flutter import.
library;

/// Opens Plaid Link.
abstract interface class LinkLauncher {
  /// Opens Link with [linkToken] (a new Item's, or an Item's in update mode) and
  /// completes when the user finishes or leaves. One session at a time: opening another
  /// while one is open is a [StateError].
  Future<LinkResult> open(String linkToken);
}

/// What the user did in Link.
sealed class LinkResult {
  const LinkResult();
}

/// The user linked (or, in update mode, repaired) an Item. [publicToken] is exchanged for
/// a new Item and never for an update; it is never logged.
final class LinkSucceeded extends LinkResult {
  /// A success at [institution], when Link named one.
  const LinkSucceeded(this.publicToken, {this.institution});

  final String publicToken;
  final LinkInstitution? institution;

  @override
  String toString() => 'LinkSucceeded(${institution?.id})';
}

/// The user left Link: on their own when [error] is null, else because of [error].
final class LinkExited extends LinkResult {
  /// An exit.
  const LinkExited([this.error]);

  final LinkExitError? error;

  @override
  String toString() => 'LinkExited(${error?.code})';
}

/// The institution Link reports.
typedef LinkInstitution = ({String id, String name});

/// Why Link closed: Plaid's error code and type, and the message Plaid meant for the user
/// when it gave one (`platform_error` when Link could not open at all).
final class LinkExitError {
  /// An error.
  const LinkExitError({
    required this.code,
    required this.type,
    this.displayMessage,
  });

  final String code;
  final String type;
  final String? displayMessage;

  @override
  bool operator ==(Object other) =>
      other is LinkExitError &&
      other.code == code &&
      other.type == type &&
      other.displayMessage == displayMessage;

  @override
  int get hashCode => Object.hash(code, type, displayMessage);
}
