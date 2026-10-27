/// What the app shows when it may not post notifications and the user turned a reminder
/// on (`docs/reference/bills.md`, **Screens**): why reminders need the permission, and
/// "Open settings", which opens the system's notification settings for the app.
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows the explanation over [context] until the user closes it or opens the settings
/// through [scheduler].
Future<void> showNotificationPermissionSheet(
  BuildContext context,
  ReminderScheduler scheduler,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final AppLocalizations l10n = AppLocalizations.of(sheetContext);
    final ThemeData theme = Theme.of(sheetContext);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.billPermissionTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.billPermissionBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.billPermissionNotNow),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(scheduler.openSettings());
                },
                child: Text(l10n.billPermissionOpenSettings),
              ),
            ],
          ),
        ],
      ),
    );
  },
);
