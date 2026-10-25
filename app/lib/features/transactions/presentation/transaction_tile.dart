/// One transaction as a list row: the merchant's avatar and name
/// (`EnrichedMerchant.resolve`: Plaid's merchant and logo, else the enrichment fallback),
/// a caption, the amount colored by direction, a "Pending" label while it is pending, and
/// optionally the running balance after it (the account detail's ledger). Built from plain
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
    this.runningBalance,
    this.onTap,
  });

  /// The merchant as shown: its name and its avatar.
  final EnrichedMerchant merchant;

  /// The line under the title (the account and the category, or the date).
  final String caption;

  final Money amount;

  final bool pending;

  /// The account's balance after this transaction, derived from its transactions; shown
  /// labelled as a running balance when given.
  final Money? runningBalance;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Money? balance = runningBalance;
    return MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              MerchantAvatar(
                name: merchant.displayName,
                color: merchant.color,
                logoUrl: merchant.logoUrl,
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
                        l10n.runningBalance(balance.format()),
                        style: captionStyle,
                        semanticsLabel: l10n.runningBalance(
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
                    _PendingLabel(l10n.transactionPending),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingLabel extends StatelessWidget {
  const _PendingLabel(this.text);

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
