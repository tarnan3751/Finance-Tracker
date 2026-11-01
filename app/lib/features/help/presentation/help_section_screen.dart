/// One section of the in-app help (`/settings/help/<slug>`,
/// `docs/reference/onboarding.md`, **Help**): its title and its text. A slug no section
/// has shows the list of sections instead.
library;

import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_content.dart';
import 'package:finance_tracker/features/help/presentation/help_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The help section named by [slug].
class HelpSectionScreen extends StatelessWidget {
  const HelpSectionScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final HelpSection? section = HelpSection.fromSlug(slug);
    if (section == null) return const HelpScreen();
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(helpSectionTitle(l10n, section))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: helpSectionBody(l10n, section),
      ),
    );
  }
}
