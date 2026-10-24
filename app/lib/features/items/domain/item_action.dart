/// Where an action on a linked bank stands (`docs/reference/items.md`, **The Link
/// controller**): a step running, or why it failed. Pure Dart, no Flutter import.
library;

import 'package:finance_tracker/features/items/domain/link_launcher.dart';

/// A step of an Item action.
enum ItemStep {
  /// Getting a link token and running Plaid Link.
  linking,

  /// Exchanging Link's public token for the new Item.
  exchanging,

  /// Asking the server to sync the Item with Plaid, until it has.
  syncing,

  /// Pulling the server's Items, accounts and transactions.
  pulling,

  /// Removing the Item at the server.
  unlinking,
}

/// Why an Item action failed.
sealed class ItemActionFailure {
  const ItemActionFailure();
}

/// The server, or the way to it, refused: [kind] names the class of `ApiException`.
final class ItemApiFailure extends ItemActionFailure {
  /// A failure of [kind]; [retryAfter] when the server was rate limiting and said.
  const ItemApiFailure(this.kind, {this.retryAfter});

  final ItemApiFailureKind kind;
  final Duration? retryAfter;

  @override
  bool operator ==(Object other) =>
      other is ItemApiFailure &&
      other.kind == kind &&
      other.retryAfter == retryAfter;

  @override
  int get hashCode => Object.hash(kind, retryAfter);

  @override
  String toString() => 'ItemApiFailure(${kind.name})';
}

/// The classes of server failure the screen tells apart.
enum ItemApiFailureKind {
  /// No answer: offline, timed out, not configured.
  offline,

  /// The bank needs the user to sign in again (`item_login_required`).
  loginRequired,

  /// Too many requests (`rate_limited`).
  rateLimited,

  /// The Item is not the user's, or is gone (`not_found`).
  notFound,

  /// Plaid failed (`plaid_error`).
  plaid,

  /// The server answered with another error (`internal`, a code this build does not
  /// know, an answer it cannot read, a conflict).
  server,

  /// Something else went wrong, not an answer from the server.
  other,
}

/// Plaid Link closed with an error.
final class ItemLinkFailure extends ItemActionFailure {
  /// A failure with Link's [error].
  const ItemLinkFailure(this.error);

  final LinkExitError error;

  @override
  bool operator ==(Object other) =>
      other is ItemLinkFailure && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// The bank is still preparing the Item's data: the sync was not done after every try.
/// The Item is linked; a later Sync now brings its data.
final class ItemStillPreparing extends ItemActionFailure {
  /// The failure.
  const ItemStillPreparing();

  @override
  bool operator ==(Object other) => other is ItemStillPreparing;

  @override
  int get hashCode => 0;
}

/// An action's state: running [step], or failed with [failure].
final class ItemAction {
  /// A running step.
  const ItemAction.running(ItemStep this.step) : failure = null;

  /// A failure.
  const ItemAction.failed(ItemActionFailure this.failure) : step = null;

  final ItemStep? step;
  final ItemActionFailure? failure;

  /// Whether a step is running.
  bool get isRunning => step != null;

  @override
  bool operator ==(Object other) =>
      other is ItemAction && other.step == step && other.failure == failure;

  @override
  int get hashCode => Object.hash(step, failure);

  @override
  String toString() => 'ItemAction(${step?.name ?? failure})';
}

/// Every action's state: [newLink] for linking a new bank (before its Item exists), and
/// one per Item in [byItem]. A missing entry is idle.
final class LinkState {
  /// A state.
  const LinkState({this.newLink, this.byItem = const {}});

  final ItemAction? newLink;
  final Map<String, ItemAction> byItem;

  /// Whether Plaid Link is open or about to be (no second session may start).
  bool get linkBusy =>
      newLink?.step == ItemStep.linking ||
      byItem.values.any((a) => a.step == ItemStep.linking);

  @override
  bool operator ==(Object other) =>
      other is LinkState &&
      other.newLink == newLink &&
      other.byItem.length == byItem.length &&
      other.byItem.entries.every((e) => byItem[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    newLink,
    Object.hashAllUnordered(
      byItem.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
