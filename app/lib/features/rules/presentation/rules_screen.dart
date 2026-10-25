/// The rules (Settings, Data, Rules; and the categories screen's menu): the live rules
/// in the order they are tried, reordered by dragging a rule's handle (or by the list's
/// move actions for assistive technology), each deleted with an undo, and "Add rule".
/// Tapping a rule opens its editor.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The rule list.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  // The order just dropped, shown until the repository's next list arrives.
  List<Rule>? _dropped;

  // Moves the rule at [from] to [to], an index in the list without it.
  Future<void> _move(List<Rule> rules, int from, int to) async {
    final List<Rule> order = [...rules];
    final Rule moved = order.removeAt(from);
    order.insert(to, moved);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _dropped = order);
    try {
      await ref.read(ruleActionsProvider).reorder([
        for (final Rule r in order) r.id,
      ]);
    } on Object {
      // The list goes back to the stored order.
      if (mounted) setState(() => _dropped = null);
      messenger.showSnackBar(SnackBar(content: Text(l10n.ruleReorderFailed)));
    }
  }

  Future<void> _delete(Rule rule) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final RuleActions actions = ref.read(ruleActionsProvider);
    await actions.delete(rule.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.ruleDeleted),
        duration: undoDuration,
        // A snack bar with an action stays until dismissed unless told otherwise.
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.restore(rule.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    ref.listen(rulesProvider, (_, _) => setState(() => _dropped = null));
    final List<Rule>? live = ref.watch(rulesProvider).value;
    final List<Rule>? rules = _dropped ?? live;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => const NewRuleRoute().push<void>(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.ruleAdd),
      ),
      body: switch (rules) {
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(
          icon: Icons.rule,
          headline: l10n.rulesEmptyHeadline,
          body: l10n.rulesEmptyBody,
        ),
        final List<Rule> rules => ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.only(bottom: 88),
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.rulesOrderNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          itemCount: rules.length,
          onReorderItem: (from, to) => _move(rules, from, to),
          itemBuilder: (context, index) {
            final Rule rule = rules[index];
            return ListTile(
              key: ValueKey(rule.id),
              contentPadding: const EdgeInsetsDirectional.only(
                start: 4,
                end: 4,
              ),
              leading: ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: l10n.ruleReorderNamed(rule.name),
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ),
              title: Text(rule.name),
              subtitle: Text(
                l10n.ruleSummary(
                  l10n.ruleConditionCount(rule.conditions.length),
                  l10n.ruleActionCount(rule.actions.length),
                ),
              ),
              trailing: IconButton(
                tooltip: l10n.ruleDeleteNamed(rule.name),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(rule),
              ),
              onTap: () => EditRuleRoute(rule.id).push<void>(context),
            );
          },
        ),
      },
    );
  }
}
