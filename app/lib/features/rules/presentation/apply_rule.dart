/// "Apply to existing transactions", from the rule editor and the rules list: a
/// confirmation, then `RuleActions.applyToHistory` with a progress bar under the app bar
/// and the Apply entries disabled until it finishes (`ruleApplyingProvider`; one
/// application at a time), then a snack bar with what changed.
library;

import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

final Logger _log = Logger('rules');

/// The progress bar a rules screen shows under its app bar while [applying].
PreferredSizeWidget? ruleApplyProgress(AppLocalizations l10n, bool applying) =>
    applying
    ? PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(semanticsLabel: l10n.ruleApplying),
      )
    : null;

/// Asks to apply [rule] to the existing transactions and, when the user agrees, applies
/// it and says what changed. Does nothing while another application runs.
Future<void> confirmAndApplyRule(
  BuildContext context,
  WidgetRef ref,
  Rule rule,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final RuleActions actions = ref.read(ruleActionsProvider);
  // Read before any await: the screen may be gone by the time the application ends.
  final RuleApplying applying = ref.read(ruleApplyingProvider.notifier);
  if (ref.read(ruleApplyingProvider)) return;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.ruleApplyTitle(rule.name)),
      content: Text(l10n.ruleApplyBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.ruleApplyConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !applying.start()) return;
  final String message;
  try {
    final RulePreview applied = await actions.applyToHistory(rule);
    message = applied.changes.isEmpty
        ? l10n.ruleAppliedNone
        : l10n.ruleApplied(
            applied.changes.length,
            applied.filed,
            applied.tagged,
            applied.renamed,
            applied.hidden,
          );
  } on Object catch (e) {
    _log.warning('rule ${rule.id} not applied to history: ${e.runtimeType}');
    messenger.showSnackBar(SnackBar(content: Text(l10n.ruleApplyFailed)));
    return;
  } finally {
    applying.finish();
  }
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
