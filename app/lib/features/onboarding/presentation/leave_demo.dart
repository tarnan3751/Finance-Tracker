/// Leaving the demo (`docs/reference/onboarding.md`): a confirmation, then the local wipe
/// for [WipeReason.demoLeft] (`core/db/local_wipe.dart`), which erases what the demo left
/// on the device (its home screen widgets' snapshot among it) and the stored app mode,
/// and restarts the app on the Welcome screen. Offered in dev and prod while the demo
/// runs; the demo flavor has nowhere to leave to.
library;

import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks whether to leave the demo and, on yes, leaves it.
Future<void> confirmAndLeaveDemo(BuildContext context, WidgetRef ref) async {
  // Read before the dialog: the wipe outlives this screen.
  final WipeLocalData wipe = ref.read(wipeLocalDataProvider);
  final AppLocalizations l10n = AppLocalizations.of(context);
  final bool? leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.leaveDemoTitle),
      content: Text(l10n.leaveDemoBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.leaveDemoConfirm),
        ),
      ],
    ),
  );
  if (leave ?? false) await wipe(WipeReason.demoLeft);
}
