/// The confirmation before this device is erased (Settings' "Sign out and erase this
/// device", and the sign-in screen's "Erase this device's data"): what is lost (changes
/// not yet synced, with their count, and receipt photos) and what comes back on the next
/// sign-in; then the erase (`account_actions.dart`). The count is the sync controller's
/// ledger while signed in, else the Drift sync store's outbox read directly (signed out
/// after a restart, the ledger is not kept); the demo and the tests have no outbox.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/features/auth/application/account_actions.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('auth');

/// Asks before erasing this device, then erases it.
Future<void> confirmAndEraseDevice(BuildContext context, WidgetRef ref) async {
  final AccountActions actions = ref.read(accountActionsProvider);
  final int? pending =
      ref.read(syncControllerProvider).ledger?.pending ??
      await _outboxCount(ref);
  if (!context.mounted) return;
  final bool confirmed =
      await showDialog<bool>(
        context: context,
        builder: (context) => EraseDeviceDialog(pending: pending),
      ) ??
      false;
  // On success the app is stopped under the caller: nothing follows.
  if (confirmed) await actions.eraseDevice();
}

// The outbox's count in the Drift sync store, or null where there is none or it cannot be
// read (only its type is logged).
Future<int?> _outboxCount(WidgetRef ref) async {
  if (!ref.read(localDataSyncsProvider)) return null;
  try {
    return (await ref.read(driftSyncStoreProvider).watchLedger().first).pending;
  } on Object catch (e) {
    _log.warning('the outbox could not be counted: ${e.runtimeType}');
    return null;
  }
}

/// The erase's confirmation, with [pending] changes not yet synced (null: not known).
class EraseDeviceDialog extends StatelessWidget {
  const EraseDeviceDialog({required this.pending, super.key});

  final int? pending;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final int? pending = this.pending;
    return AlertDialog(
      title: Text(l10n.eraseDeviceTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.eraseDeviceBody),
            if (pending != null && pending > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.eraseDevicePending(pending),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.eraseDeviceConfirm),
        ),
      ],
    );
  }
}
