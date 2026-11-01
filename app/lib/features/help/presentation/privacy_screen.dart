/// The privacy page (`/settings/privacy`, `docs/reference/onboarding.md`, **Privacy**),
/// from Settings → About: what leaves the device in the live mode and what never does,
/// and the demo, which sends nothing (`privacy_content.dart`, the same text as
/// `PRIVACY.md`).
library;

import 'package:finance_tracker/features/help/presentation/privacy_content.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The privacy page.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: privacyBody(l10n),
      ),
    );
  }
}
