/// The menu a tab's app bar carries for its help (`docs/reference/onboarding.md`,
/// **Help**): "More options" holding "Help", which opens [HelpMenuButton.section] beside
/// the tab (`openDetail`), on top of the tab's own stack. The transaction list's menu
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
  const HelpMenuButton({super.key, required this.section});

  final HelpSection section;

  @override
  Widget build(BuildContext context) => PopupMenuButton<void>(
    tooltip: AppLocalizations.of(context).helpMoreOptions,
    itemBuilder: (_) => [helpMenuItem(context, section)],
  );
}
