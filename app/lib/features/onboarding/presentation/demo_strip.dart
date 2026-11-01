/// The strip that marks the demo while it runs in dev and prod
/// (`docs/reference/onboarding.md`): one line above the shell's content on every tab and
/// at every window size, "Demo data" with a Leave button (`leave_demo.dart`), laid out
/// between the status bar and the shell as the flavor banner is, so it never covers an
/// app bar. Both are read by screen readers, before the screen. The demo flavor is marked
/// by its DEMO banner instead and draws no strip.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/onboarding/presentation/leave_demo.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [child] under the demo's strip, when the demo runs in dev or prod.
class DemoStrip extends ConsumerWidget {
  const DemoStrip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);
    if (!config.isDemo || config.flavor == Flavor.demo) return child;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Color foreground = theme.colorScheme.onTertiaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.tertiaryContainer,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: MediaQuery.paddingOf(context).top,
              start: 16,
              end: 4,
            ),
            child: Row(
              children: [
                Icon(Icons.science_outlined, size: 18, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.demoStripLabel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  onPressed: () => confirmAndLeaveDemo(context, ref),
                  child: Text(
                    l10n.demoStripLeave,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          // The strip takes the status bar's place; the shell below has no top inset.
          // A container of its own: the routes' modal barriers in the shell block the
          // semantics painted before them up to the nearest container, the strip's too.
          child: Semantics(
            container: true,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
