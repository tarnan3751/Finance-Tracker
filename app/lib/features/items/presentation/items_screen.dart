/// The linked banks (`/accounts/linked-banks`): one card per Item with its institution, a
/// status chip, when it last synced in the device's zone, and Sync now, Fix connection
/// (only when its login must be repaired) and Unlink (a dialog: keep its history or
/// delete it, each consequence spelled out); a bank unlinked with its history kept shows
/// as Unlinked, with only Delete history (after a confirmation), while its accounts are on
/// the device; each button's semantics label names its bank; "Link a bank" as the floating
/// button and in the empty state. Each action's progress and failure show on its card, the new link's
/// above the list (`application/link_controller.dart`). In the demo flavor and on the
/// fake server, Link is the fake launcher and shows no Plaid UI.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/merchant_avatar.dart';
import 'package:finance_tracker/features/items/application/items_providers.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The linked banks screen.
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<LinkedBank>> banks = ref.watch(linkedBanksProvider);
    final LinkState actions = ref.watch(linkControllerProvider);
    final VoidCallback? link = actions.linkBusy
        ? null
        : () => ref.read(linkControllerProvider.notifier).link();
    final bool hasBanks = banks.value?.isNotEmpty ?? false;
    final ItemAction? newLink = actions.newLink;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.itemsTitle)),
      floatingActionButton: hasBanks
          ? FloatingActionButton.extended(
              onPressed: link,
              icon: const Icon(Icons.add_link),
              label: Text(l10n.itemsLink),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (newLink != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ActionLine(action: newLink),
            ),
          Expanded(
            child: switch (banks) {
              AsyncValue(value: final List<LinkedBank> list)
                  when list.isEmpty =>
                EmptyState(
                  icon: Icons.account_balance_outlined,
                  headline: l10n.itemsEmptyHeadline,
                  body: l10n.itemsEmptyBody,
                  action: FilledButton.icon(
                    onPressed: link,
                    icon: const Icon(Icons.add_link),
                    label: Text(l10n.itemsLink),
                  ),
                ),
              AsyncValue(value: final List<LinkedBank> list) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  for (final LinkedBank bank in list)
                    _BankCard(bank: bank, action: actions.byItem[bank.id]),
                ],
              ),
              AsyncError() => Center(child: Text(l10n.loadFailed)),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _BankCard extends ConsumerWidget {
  const _BankCard({required this.bank, required this.action});

  final LinkedBank bank;
  final ItemAction? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Clock clock = ref.watch(clockProvider);
    final LinkController controller = ref.read(linkControllerProvider.notifier);
    final bool linkBusy = ref.watch(
      linkControllerProvider.select((s) => s.linkBusy),
    );
    final bool running = action?.isRunning ?? false;
    final ItemStatus status = bank.item.status;
    final DateTime? lastSync = bank.item.lastSuccessfulSyncAt;
    final String name = bank.institution.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(bank: bank),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      Text(
                        lastSync == null
                            ? l10n.itemsNeverSynced
                            : l10n.itemsLastSynced(
                                formatDateTime(lastSync, clock.location),
                              ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: status),
                    ],
                  ),
                ),
              ],
            ),
            if (action case final ItemAction current)
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 8),
                child: _ActionLine(
                  action: current,
                  unlinked: status == ItemStatus.removed,
                ),
              ),
            // An unlinked bank keeps only its history, which it can delete.
            if (status == ItemStatus.removed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: running
                      ? null
                      : () => _deleteHistory(context, controller, name),
                  child: Text(
                    l10n.itemsDeleteHistory,
                    semanticsLabel: l10n.itemsDeleteHistoryLabel(name),
                  ),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: running ? null : () => controller.sync(bank.id),
                    child: Text(
                      l10n.itemsSyncNow,
                      semanticsLabel: l10n.itemsSyncNowLabel(name),
                    ),
                  ),
                  if (status == ItemStatus.loginRequired)
                    TextButton(
                      onPressed: running || linkBusy
                          ? null
                          : () => controller.repair(bank.id),
                      child: Text(
                        l10n.itemsFix,
                        semanticsLabel: l10n.itemsFixLabel(name),
                      ),
                    ),
                  TextButton(
                    onPressed: running
                        ? null
                        : () => _unlink(context, controller, name),
                    child: Text(
                      l10n.itemsUnlink,
                      semanticsLabel: l10n.itemsUnlinkLabel(name),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlink(
    BuildContext context,
    LinkController controller,
    String name,
  ) async {
    final bool? keep = await showDialog<bool>(
      context: context,
      builder: (context) => _UnlinkDialog(institution: name),
    );
    if (keep == null) return;
    await controller.unlink(bank.id, keepHistory: keep);
  }

  Future<void> _deleteHistory(
    BuildContext context,
    LinkController controller,
    String name,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itemsDeleteHistoryTitle(name)),
        content: Text(l10n.itemsDeleteHistoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.itemsDeleteHistoryConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.unlink(bank.id, keepHistory: false);
  }
}

/// The institution's logo when the server gave one, else its initial on Plaid's primary
/// color or a palette color; decorative, its name being beside it.
class _Logo extends StatelessWidget {
  const _Logo({required this.bank});

  final LinkedBank bank;

  @override
  Widget build(BuildContext context) => MerchantAvatar(
    name: bank.institution.name,
    color: institutionColor(bank.institution),
    logoBytes: bank.logo,
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (
      String label,
      IconData icon,
      Color background,
      Color foreground,
    ) = switch (status) {
      ItemStatus.healthy => (
        l10n.itemsStatusConnected,
        Icons.check_circle_outline,
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ItemStatus.loginRequired || ItemStatus.pendingExpiration => (
        l10n.itemsStatusNeedsAttention,
        Icons.warning_amber_outlined,
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      ItemStatus.error || ItemStatus.unknown => (
        l10n.itemsStatusError,
        Icons.error_outline,
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      ItemStatus.removed => (
        l10n.itemsStatusUnlinked,
        Icons.link_off,
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    // A chip drawn by hand so a long label wraps at large text sizes.
    return Semantics(
      container: true,
      label: l10n.itemsStatusLabel(label),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An action's progress, or its failure in the error color (announced when it appears).
class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.action, this.unlinked = false});

  final ItemAction action;

  /// Whether the action is on a bank unlinked with its history kept (unlinking it again
  /// deletes that history).
  final bool unlinked;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    if (action.step case final ItemStep step) {
      return Semantics(
        liveRegion: true,
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(switch (step) {
                ItemStep.linking => l10n.itemsStepLinking,
                ItemStep.exchanging => l10n.itemsStepExchanging,
                ItemStep.syncing => l10n.itemsStepSyncing,
                ItemStep.pulling => l10n.itemsStepPulling,
                ItemStep.unlinking when unlinked =>
                  l10n.itemsStepDeletingHistory,
                ItemStep.unlinking => l10n.itemsStepUnlinking,
              }),
            ),
          ],
        ),
      );
    }
    final String message = switch (action.failure!) {
      ItemApiFailure(:final ItemApiFailureKind kind) => switch (kind) {
        ItemApiFailureKind.offline => l10n.itemsFailedOffline,
        ItemApiFailureKind.loginRequired => l10n.itemsFailedLoginRequired,
        ItemApiFailureKind.rateLimited => l10n.itemsFailedRateLimited,
        ItemApiFailureKind.notFound => l10n.itemsFailedNotFound,
        ItemApiFailureKind.plaid => l10n.itemsFailedPlaid,
        ItemApiFailureKind.server => l10n.itemsFailedServer,
        ItemApiFailureKind.other => l10n.itemsFailedOther,
      },
      ItemLinkFailure(:final error) =>
        error.displayMessage ?? l10n.itemsFailedLink,
      ItemStillPreparing() => l10n.itemsStillPreparing,
    };
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Asks what happens to the bank's accounts and transactions: true keeps them, false
/// deletes them; null when cancelled.
class _UnlinkDialog extends StatefulWidget {
  const _UnlinkDialog({required this.institution});

  final String institution;

  @override
  State<_UnlinkDialog> createState() => _UnlinkDialogState();
}

class _UnlinkDialogState extends State<_UnlinkDialog> {
  bool _keep = true;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.itemsUnlinkTitle(widget.institution)),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      content: SingleChildScrollView(
        child: RadioGroup<bool>(
          groupValue: _keep,
          onChanged: (value) => setState(() => _keep = value ?? _keep),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                value: true,
                title: Text(l10n.itemsUnlinkKeep),
                subtitle: Text(l10n.itemsUnlinkKeepDetail),
              ),
              RadioListTile<bool>(
                value: false,
                title: Text(l10n.itemsUnlinkDelete),
                subtitle: Text(l10n.itemsUnlinkDeleteDetail),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_keep),
          child: Text(l10n.itemsUnlinkConfirm),
        ),
      ],
    );
  }
}
