/// The rule editor's preview sheet: the first fifty existing transactions the rule as
/// edited would change, newest first, each with what changes (the category, before and
/// after; the tag added; the description, before and after; hidden), and how many more
/// are not listed. Read-only: nothing is written until the rule is applied.
library;

import 'package:finance_tracker/features/rules/application/rule_preview.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// How many changed transactions the sheet lists.
const int rulePreviewListed = 50;

/// Shows the sheet of [preview].
Future<void> showRulePreviewSheet(BuildContext context, RulePreview preview) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => RulePreviewSheet(preview: preview),
    );

/// The list of what a rule would change.
class RulePreviewSheet extends ConsumerWidget {
  const RulePreviewSheet({super.key, required this.preview});

  final RulePreview preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final List<RuleChange> listed = preview.changes
        .take(rulePreviewListed)
        .toList();
    final int more = preview.changes.length - listed.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 1,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Semantics(
              header: true,
              child: Text(
                l10n.rulePreviewTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.rulePreviewCount(preview.changes.length, preview.total),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final RuleChange change in listed)
            TransactionTile(
              key: ValueKey(change.before.id),
              merchant: EnrichedMerchant.resolve(change.before),
              caption: [
                shortDateLabel(change.before.date),
                ..._changeLines(l10n, categories, change),
              ].join('\n'),
              amount: change.before.amount,
              pending: change.before.pending,
            ),
          if (more > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.rulePreviewMore(more),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// What [change] changes, one line per field.
List<String> _changeLines(
  AppLocalizations l10n,
  CategoryLookup categories,
  RuleChange change,
) {
  final Transaction before = change.before;
  final Transaction after = change.after;
  return [
    if (after.userCategoryId != before.userCategoryId)
      l10n.rulePreviewCategory(
        effectiveCategory(before, categories)?.name ?? l10n.uncategorized,
        effectiveCategory(after, categories)?.name ?? l10n.uncategorized,
      ),
    for (final String tag in after.tags)
      if (!before.tags.contains(tag)) l10n.rulePreviewTag(tag),
    if (after.name != before.name)
      l10n.rulePreviewName(before.name, after.name),
    if (after.hidden && !before.hidden) l10n.rulePreviewHidden,
  ];
}
