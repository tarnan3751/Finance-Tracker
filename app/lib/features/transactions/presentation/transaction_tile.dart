/// One transaction as a list row: the merchant's avatar and name
/// (`EnrichedMerchant.resolve`: Plaid's merchant and logo, else the enrichment fallback),
/// a caption, the amount colored by direction, a "Pending" label while it is pending, a
/// "Hidden" label when the user hid it, and optionally the running balance after it (the
/// account detail's ledger), captioned as worked back from the reported balance when it
/// is. In the list's selection mode a checkbox takes the avatar's place. Built from plain
/// values so a list of thousands builds only the rows on screen and subscribes to nothing.
library;

import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/core/widgets/merchant_avatar.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// A transaction row.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.merchant,
    required this.caption,
    required this.amount,
    this.pending = false,
    this.hidden = false,
    this.runningBalance,
    this.runningBalanceFromReported = false,
    this.selected,
    this.onTap,
    this.onLongPress,
  });

  /// The merchant as shown: its name and its avatar.
  final EnrichedMerchant merchant;

  /// The line under the title (the account and the category, or the date).
  final String caption;

  final Money amount;

  final bool pending;

  /// Whether the user hid the transaction; shown as a "Hidden" label.
  final bool hidden;

  /// The account's balance after this transaction, derived from its transactions; shown
  /// labelled as a running balance when given.
  final Money? runningBalance;

  /// Whether [runningBalance] is worked back from the balance the institution reported
  /// rather than summed from the transactions; the caption says which.
  final bool runningBalanceFromReported;

  /// Whether the row is selected, in the list's selection mode; null outside it.
  final bool? selected;

  final VoidCallback? onTap;

  /// Enters the list's selection mode with this row; announced as "Select".
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Money? balance = runningBalance;
    final bool? isSelected = selected;
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        onLongPressHint: onLongPress == null ? null : l10n.transactionSelect,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (isSelected == null)
                  MerchantAvatar(
                    name: merchant.displayName,
                    color: merchant.color,
                    logoUrl: merchant.logoUrl,
                  )
                else
                  SizedBox.square(
                    dimension: 40,
                    child: Checkbox(
                      // The row is the tap target; the box keeps the avatar's size.
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: isSelected,
                      onChanged: onTap == null ? null : (_) => onTap!(),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant.displayName,
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(caption, style: captionStyle),
                      if (balance != null)
                        Text(
                          runningBalanceFromReported
                              ? l10n.runningBalanceFromReported(
                                  balance.format(),
                                )
                              : l10n.runningBalance(balance.format()),
                          style: captionStyle,
                          semanticsLabel: runningBalanceFromReported
                              ? l10n.runningBalanceFromReported(
                                  amountSemanticsLabel(l10n, balance),
                                )
                              : l10n.runningBalance(
                                  amountSemanticsLabel(l10n, balance),
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(
                      amount,
                      colored: true,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (pending) ...[
                      const SizedBox(height: 4),
                      _Label(l10n.transactionPending),
                    ],
                    if (hidden) ...[
                      const SizedBox(height: 4),
                      _Label(l10n.transactionHidden),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(text, style: theme.textTheme.labelSmall),
      ),
    );
  }
}
