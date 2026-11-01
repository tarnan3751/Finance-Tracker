/// The in-app help (`/settings/help`, `docs/reference/onboarding.md`, **Help**): its
/// sections, each opening on its own page (`/settings/help/<slug>`,
/// `help_section_screen.dart`). Opened from Settings → About; each tab's menu opens its
/// own section directly (`help_menu.dart`).
library;

import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_content.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The help's sections.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        children: [
          for (final HelpSection section in HelpSection.values)
            ListTile(
              title: Text(helpSectionTitle(l10n, section)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  openDetail(context, HelpSectionRoute(section.slug).location),
            ),
        ],
      ),
    );
  }
}
