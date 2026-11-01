/// The body of a screen with nothing to show yet: an icon, a headline, a line of
/// supporting text and optionally an action button, centred, scrolling when large text
/// makes it taller than the screen. The icon is printed in blue over its pink copy,
/// offset down and to the end as a two-ink print slips (`docs/reference/design.md`); the
/// headline is the theme's Syne `titleLarge`.
library;

import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A centred empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String headline;
  final String body;

  /// The button under the text (such as "Add account"), or null for none.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SpendthriftTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              // Room for the copy, so the pair stays centred.
              padding: const EdgeInsetsDirectional.only(
                start: SpendthriftTokens.iconMisregistration,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: SpendthriftTokens.iconMisregistration,
                      top: SpendthriftTokens.iconMisregistration,
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: FinanceColors.of(context).accent,
                    ),
                  ),
                  Icon(icon, size: 48, color: theme.colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: SpendthriftTokens.space16),
            Text(
              headline,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpendthriftTokens.space8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action case final Widget action) ...[
              const SizedBox(height: SpendthriftTokens.space24),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
