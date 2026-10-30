/// The settings screen's Sync section (dev and prod): the status of the last session, the
/// outbox, a clock ahead (changes held back) or behind (changes that may be overridden),
/// changes the server refused for good, records this version cannot show, the conflicts
/// to review (while there are any; they open the Conflicts screen), when the bank data
/// was last pulled (or why it failed), and "Sync now", which runs both. Counts and times
/// only, never a change's content.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:finance_tracker/features/conflicts/application/conflicts_providers.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The Sync section.
class SyncSection extends ConsumerWidget {
  const SyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SyncStatus status = ref.watch(syncControllerProvider);
    final Clock clock = ref.watch(clockProvider);
    String local(DateTime utc) => formatDateTime(utc, clock.location);

    final bool signedIn =
        status.phase == SyncPhase.idle || status.phase == SyncPhase.running;
    final DateTime? lastSyncAt = status.lastSyncAt;
    final String summary = switch (status) {
      SyncStatus(phase: SyncPhase.signedOut || SyncPhase.unavailable) =>
        l10n.syncSignedOut,
      SyncStatus(phase: SyncPhase.running) => l10n.syncRunning,
      SyncStatus(failure: SyncFailure.offline) => l10n.syncFailedOffline,
      SyncStatus(failure: SyncFailure.server) => l10n.syncFailedServer,
      SyncStatus(failure: SyncFailure.other) => l10n.syncFailedOther,
      _ when lastSyncAt != null => l10n.syncLastAt(local(lastSyncAt)),
      _ => l10n.syncNever,
    };
    final ledger = status.ledger;
    final int conflicts = signedIn ? ref.watch(conflictCountProvider) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsSync),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(l10n.syncStatus),
          subtitle: Text(summary),
        ),
        if (signedIn)
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(l10n.syncBankData),
            subtitle: Text(switch (status) {
              SyncStatus(plaidFailure: SyncFailure.offline) =>
                l10n.syncBankDataFailedOffline,
              SyncStatus(plaidFailure: SyncFailure.server) =>
                l10n.syncBankDataFailedServer,
              SyncStatus(plaidFailure: SyncFailure.other) =>
                l10n.syncBankDataFailedOther,
              SyncStatus(:final DateTime plaidPulledAt) =>
                l10n.syncBankDataPulledAt(local(plaidPulledAt)),
              _ => l10n.syncBankDataNever,
            }),
          ),
        if (signedIn && ledger != null) ...[
          ListTile(
            leading: const Icon(Icons.outbox_outlined),
            title: Text(l10n.syncPending(ledger.pending)),
          ),
          if (status.lastSummary?.clockAhead ?? false)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.syncClockDrift),
            ),
          if (status.lastSummary?.clockBehind ?? false)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.syncClockBehind),
            ),
          if (ledger.lastRejected case final Hlc last when ledger.rejected > 0)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.syncRejected(ledger.rejected, local(last.wall))),
            ),
          if (ledger.held > 0)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l10n.syncHeld(ledger.held)),
            ),
        ],
        if (conflicts > 0)
          ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.syncConflicts(conflicts)),
            subtitle: Text(l10n.syncConflictsHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ConflictsRoute().push<void>(context),
          ),
        if (signedIn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: status.phase == SyncPhase.idle
                    ? () => ref.read(syncControllerProvider.notifier).syncNow()
                    : null,
                icon: const Icon(Icons.sync),
                label: Text(l10n.syncNow),
              ),
            ),
          ),
      ],
    );
  }
}
