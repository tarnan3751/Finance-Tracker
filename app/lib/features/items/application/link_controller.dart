/// Linking a bank, repairing its login, syncing it and unlinking it
/// (`docs/reference/items.md`, **The Link controller**).
///
/// - [LinkController.link]: a link token (`createLinkToken` with the app's package
///   name), Plaid Link through the launcher, the public token exchanged for the new Item
///   (stored at once), then the Item synced and the data pulled;
/// - [LinkController.repair]: an update-mode link token, Link, and on success **no**
///   exchange (Plaid repaired the Item itself), then the sync and the pull;
/// - [LinkController.sync]: the sync and the pull;
/// - [LinkController.unlink]: the Item removed at the server with the user's choice for
///   its history (`keep` lists it as `removed` with its rows; `delete` drops it and
///   tombstones them for every device), then the pull, which applies what the server now
///   lists.
///
/// The sync asks the server every [linkPollInterval] (5 s) until it answers `completed`,
/// at most [syncTries] times: `not_ready` (and `started`) mean Plaid is still extracting,
/// never "no transactions" (`PLAN.md` §4). If it never completes, the data is pulled
/// anyway (the Item and what it already has show) and the action ends
/// [ItemStillPreparing]. A user who closes Link is no failure; Link's error is. Any
/// `ItemLoginRequired` marks the Item for repair. Failures stay in the state, never
/// thrown, until that Item's next action. One action per Item at a time, and one Link
/// session at a time.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/application/link_launcher_provider.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:finance_tracker/features/items/domain/link_launcher.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'link_controller.g.dart';

final Logger _log = Logger('items');

/// How many times the sync is asked before the action ends [ItemStillPreparing].
const int syncTries = 24;

/// The wait between two sync requests.
@Riverpod(keepAlive: true)
Duration linkPollInterval(Ref ref) => const Duration(seconds: 5);

/// The state of every action on linked banks, and the actions.
@Riverpod(keepAlive: true)
class LinkController extends _$LinkController {
  @override
  LinkState build() => const LinkState();

  FinanceApi get _api => ref.read(financeApiProvider);

  /// Links a new bank. Does nothing while Link is open or a link is running.
  Future<void> link() async {
    if (state.linkBusy || (state.newLink?.isRunning ?? false)) return;
    _setNew(const ItemAction.running(ItemStep.linking));
    final LinkedItem linked;
    try {
      final LinkToken token = await _api.createLinkToken(
        androidPackageName: await _packageName(),
      );
      final LinkResult result = await ref
          .read(linkLauncherProvider)
          .open(token.linkToken);
      final LinkSucceeded success;
      switch (result) {
        case LinkExited(error: null):
          _setNew(null);
          return;
        case LinkExited(:final LinkExitError error):
          _setNew(ItemAction.failed(ItemLinkFailure(error)));
          return;
        case final LinkSucceeded s:
          success = s;
      }
      _setNew(const ItemAction.running(ItemStep.exchanging));
      linked = await _api.exchangePublicToken(success.publicToken);
      await ref
          .read(itemRepositoryProvider)
          .applyPlaidItem(linked, pulledAt: ref.read(clockProvider).nowUtc());
      _setNew(null);
    } on Object catch (e) {
      _log.warning('link failed: ${e.runtimeType}');
      _setNew(ItemAction.failed(_failureOf(e)));
      return;
    }
    // From here the new Item's own action: its failures show on its card.
    await _run(linked.item.id, () => _syncAndPull(linked.item.id));
  }

  /// Repairs Item [itemId]'s login through Link in update mode.
  Future<void> repair(String itemId) => _run(itemId, () async {
    if (state.linkBusy) return;
    _setItem(itemId, const ItemAction.running(ItemStep.linking));
    final LinkToken token = await _api.createUpdateLinkToken(
      itemId,
      androidPackageName: await _packageName(),
    );
    final LinkResult result = await ref
        .read(linkLauncherProvider)
        .open(token.linkToken);
    switch (result) {
      case LinkExited(error: null):
        _setItem(itemId, null);
      case LinkExited(:final LinkExitError error):
        _setItem(itemId, ItemAction.failed(ItemLinkFailure(error)));
      case LinkSucceeded():
        // Update mode: Plaid repaired the Item; its public token is never exchanged.
        await _syncAndPull(itemId);
    }
  });

  /// Syncs Item [itemId] with Plaid and pulls its data.
  Future<void> sync(String itemId) => _run(itemId, () => _syncAndPull(itemId));

  /// Unlinks Item [itemId], keeping its history on every device when [keepHistory].
  Future<void> unlink(String itemId, {required bool keepHistory}) =>
      _run(itemId, () async {
        _setItem(itemId, const ItemAction.running(ItemStep.unlinking));
        try {
          await _api.deleteItem(
            itemId,
            history: keepHistory ? UnlinkHistory.keep : UnlinkHistory.delete,
          );
        } on NotFound {
          // Already removed, from another device: the pull shows what is left.
        }
        _setItem(itemId, const ItemAction.running(ItemStep.pulling));
        await ref.read(plaidPullProvider).run();
        _setItem(itemId, null);
      });

  // Runs [action] on Item [itemId] unless one is running; a failure goes into its state.
  Future<void> _run(String itemId, Future<void> Function() action) async {
    if (state.byItem[itemId]?.isRunning ?? false) return;
    try {
      await action();
    } on Object catch (e) {
      _log.warning('item action failed: ${e.runtimeType}');
      if (e is ItemLoginRequired) {
        await ref.read(itemRepositoryProvider).markLoginRequired(itemId);
      }
      _setItem(itemId, ItemAction.failed(_failureOf(e)));
    }
  }

  Future<void> _syncAndPull(String itemId) async {
    _setItem(itemId, const ItemAction.running(ItemStep.syncing));
    bool completed = false;
    try {
      for (int attempt = 1; attempt <= syncTries; attempt++) {
        final SyncRun run = await _api.syncItem(itemId);
        if (run.status == SyncRunStatus.completed) {
          completed = true;
          break;
        }
        if (attempt < syncTries) {
          await Future<void>.delayed(ref.read(linkPollIntervalProvider));
        }
      }
    } on ItemLoginRequired {
      await ref.read(itemRepositoryProvider).markLoginRequired(itemId);
      rethrow;
    }
    _setItem(itemId, const ItemAction.running(ItemStep.pulling));
    await ref.read(plaidPullProvider).run();
    _setItem(
      itemId,
      completed ? null : const ItemAction.failed(ItemStillPreparing()),
    );
  }

  Future<String> _packageName() async =>
      (await ref.read(packageInfoProvider.future)).packageName;

  void _setNew(ItemAction? action) {
    if (!ref.mounted) return;
    state = LinkState(newLink: action, byItem: state.byItem);
  }

  void _setItem(String itemId, ItemAction? action) {
    if (!ref.mounted) return;
    state = LinkState(
      newLink: state.newLink,
      byItem: {
        for (final MapEntry<String, ItemAction> e in state.byItem.entries)
          if (e.key != itemId) e.key: e.value,
        itemId: ?action,
      },
    );
  }
}

ItemActionFailure _failureOf(Object error) => ItemApiFailure(switch (error) {
  NetworkError() => ItemApiFailureKind.offline,
  ItemLoginRequired() => ItemApiFailureKind.loginRequired,
  RateLimited() => ItemApiFailureKind.rateLimited,
  NotFound() => ItemApiFailureKind.notFound,
  PlaidError() => ItemApiFailureKind.plaid,
  ApiException() => ItemApiFailureKind.server,
  _ => ItemApiFailureKind.other,
}, retryAfter: error is RateLimited ? error.retryAfter : null);
