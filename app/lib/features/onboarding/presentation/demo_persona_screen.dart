/// The demo's households (`/welcome/demo`, `docs/reference/onboarding.md`): the persona
/// engine's four, each a card with its one line (the names Settings → Demo data shows). Choosing
/// one stores it and the demo mode and restarts the app on them, on the Accounts tab.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/brand_card.dart';
import 'package:finance_tracker/features/onboarding/presentation/mode_choice.dart';
import 'package:finance_tracker/features/settings/presentation/demo_data_section.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

/// The demo's households.
class DemoPersonaScreen extends ConsumerStatefulWidget {
  const DemoPersonaScreen({super.key});

  @override
  ConsumerState<DemoPersonaScreen> createState() => _DemoPersonaScreenState();
}

class _DemoPersonaScreenState extends ConsumerState<DemoPersonaScreen> {
  bool _busy = false;

  Future<void> _choose(PersonaId persona) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool stored = await storeChoiceAndRestart(context, ref, (
      modes,
    ) async {
      await modes.writeDemoPersona(persona);
      await modes.writeMode(AppMode.demo);
    });
    if (!stored && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.welcomeDemoTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendthriftTokens.space16,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: SpendthriftTokens.space8,
            ),
            child: Text(
              l10n.welcomeDemoNote,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          for (final PersonaId persona in PersonaId.values)
            Padding(
              padding: const EdgeInsets.only(bottom: SpendthriftTokens.space12),
              child: BrandCard(
                title: demoPersonaName(l10n, persona),
                trailing: const Icon(Icons.chevron_right),
                // Off while a choice is being stored: dimmed and read as disabled.
                enabled: !_busy,
                onTap: () => _choose(persona),
                child: Text(
                  demoPersonaDetail(l10n, persona),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
