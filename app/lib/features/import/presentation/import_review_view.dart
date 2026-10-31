/// The import's review step (`docs/reference/import.md`, **The review screen**): what
/// will be written (the count, the date range, the money in and out), the notes on the
/// file (read in the 8-bit fallback, imported before), the rows skipped and why, the
/// likely duplicates' switch, and every row, each read by a screen reader as one summary.
library;

import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/row_conversion.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Why a row was skipped, as the review says it.
String rowProblemLabel(AppLocalizations l10n, RowProblem problem) =>
    switch (problem) {
      RowProblem.badDate => l10n.importProblemBadDate,
      RowProblem.noAmount => l10n.importProblemNoAmount,
      RowProblem.badAmount => l10n.importProblemBadAmount,
      RowProblem.debitAndCredit => l10n.importProblemDebitAndCredit,
      RowProblem.zeroAmount => l10n.importProblemZeroAmount,
      RowProblem.noDescription => l10n.importProblemNoDescription,
    };

/// The review of [review].
class ImportReviewView extends StatelessWidget {
  const ImportReviewView({
    super.key,
    required this.review,
    required this.includeDuplicates,
    required this.busy,
    required this.error,
    required this.onIncludeDuplicates,
    required this.onImport,
  });

  final ImportReview review;
  final bool includeDuplicates;
  final bool busy;

  /// Why the last write failed, or null.
  final String? error;
  final ValueChanged<bool> onIncludeDuplicates;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ImportSummary summary = review.summary(
      includeDuplicates: includeDuplicates,
    );
    final LocalDate? first = summary.first, last = summary.last;
    final int duplicates = review.duplicates.length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Text(
                l10n.importReviewCount(summary.count),
                style: theme.textTheme.titleLarge,
              ),
              if (first != null && last != null)
                Text(
                  l10n.importReviewRange(
                    shortDateLabel(first),
                    shortDateLabel(last),
                  ),
                ),
              const SizedBox(height: 8),
              _Total(label: l10n.importReviewIn, amount: summary.moneyIn),
              _Total(label: l10n.importReviewOut, amount: summary.moneyOut),
              if (review.lossy) _Note(l10n.importLossy),
              if (review.importedBefore) _Note(l10n.importImportedBefore),
              if (review.failures.isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.importSkippedRows(review.failures.length)),
                  children: [
                    for (final RowFailure f in review.failures.take(200))
                      ListTile(
                        dense: true,
                        title: Text(
                          l10n.importFailureRow(
                            f.row,
                            rowProblemLabel(l10n, f.problem),
                          ),
                        ),
                      ),
                  ],
                ),
              if (duplicates > 0)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.importDuplicatesSwitch(duplicates)),
                  subtitle: Text(l10n.importDuplicatesSubtitle),
                  value: includeDuplicates,
                  onChanged: busy ? null : onIncludeDuplicates,
                ),
              if (error case final String message) ...[
                const SizedBox(height: 8),
                Text(message, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: summary.count == 0 || busy ? null : onImport,
                child: Text(l10n.importButton(summary.count)),
              ),
            ],
          ),
        ),
        SliverList.builder(
          itemCount: review.incoming.length,
          itemBuilder: (context, i) {
            final Transaction t = review.incoming[i];
            return _ReviewRow(
              transaction: t,
              duplicate: review.duplicates.contains(t.id),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      AmountText(amount, colored: true),
    ],
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.transaction, required this.duplicate});

  final Transaction transaction;
  final bool duplicate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String date = shortDateLabel(transaction.date);
    final String amount = amountSemanticsLabel(l10n, transaction.amount);
    return Semantics(
      label: duplicate
          ? l10n.importDuplicateRowSemantics(transaction.name, date, amount)
          : l10n.importRowSemantics(transaction.name, date, amount),
      excludeSemantics: true,
      child: ListTile(
        title: Text(transaction.name, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            if (duplicate) Text(l10n.importDuplicateLabel),
          ],
        ),
        trailing: AmountText(transaction.amount, colored: true),
      ),
    );
  }
}
