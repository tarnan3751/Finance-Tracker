/// A section's heading (`docs/reference/design.md`, **Section headers**): Syne at the
/// theme's `titleSmall` size, in capitals tracked at 0.08 em (read by screen readers as
/// written), `space24` above and `space8` below, announced as a header. A list's group
/// heading (the transactions' dates) takes [SectionHeader.underline]: an ink line under it
/// on paper, and tighter space above, since the rows follow at once.
library;

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// [title] as a section heading.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.underline = false,
    this.trailing,
  });

  final String title;

  /// Whether an ink line runs under the heading, as a list's group heading.
  final bool underline;

  /// A widget at the heading's end (an action), or null.
  final Widget? trailing;

  /// The heading's text style in [theme].
  static TextStyle? style(ThemeData theme) {
    final TextStyle? base = theme.textTheme.titleSmall;
    return base?.copyWith(
      fontFamily: AppTheme.headingFont,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08 * (base.fontSize ?? 14),
      color: theme.colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget? trailing = this.trailing;
    Widget heading = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          semanticsLabel: title,
          style: style(theme),
        ),
      ),
    );
    if (trailing != null) {
      heading = Row(
        children: [
          Expanded(child: heading),
          trailing,
        ],
      );
    }
    if (underline) {
      heading = DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline,
              width: SpendthriftTokens.inkLine,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: SpendthriftTokens.space4),
          child: heading,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpendthriftTokens.space16,
        underline ? SpendthriftTokens.space16 : SpendthriftTokens.space24,
        SpendthriftTokens.space16,
        SpendthriftTokens.space8,
      ),
      child: heading,
    );
  }
}
