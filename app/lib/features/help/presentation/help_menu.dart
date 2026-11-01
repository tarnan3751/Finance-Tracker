/// The menu a tab's app bar carries for its help (`docs/reference/onboarding.md`,
/// **Help**): "More options" holding "Help", which opens [HelpMenuButton.section] beside
/// the tab (`openDetail`), on top of the tab's own stack. It is the app bar's one menu: a
/// segment's own entries ([HelpMenuButton.entries]) come first, above a divider. The transaction list's menu
/// carries the same item among its own ([helpMenuItem]).
library;

import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The "Help" item of a menu, opening [section].
PopupMenuItem<void> helpMenuItem(BuildContext context, HelpSection section) =>
    PopupMenuItem<void>(
      onTap: () => openDetail(context, HelpSectionRoute(section.slug).location),
      child: Text(AppLocalizations.of(context).helpMenuItem),
    );

/// A tab's menu, holding Help for [section].
class HelpMenuButton extends StatelessWidget {
  const HelpMenuButton({
    super.key,
    required this.section,
    this.entries = const [],
  });

  final HelpSection section;

  /// The screen's own entries, shown above the help.
  final List<PopupMenuEntry<void>> entries;

  @override
  Widget build(BuildContext context) => PopupMenuButton<void>(
    tooltip: AppLocalizations.of(context).helpMoreOptions,
    itemBuilder: (_) => [
      ...entries,
      if (entries.isNotEmpty) const PopupMenuDivider(),
      helpMenuItem(context, section),
    ],
  );
}
