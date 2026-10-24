/// The settings screen's Demo data section (demo flavor only): which persona engine
/// household the demo shows. Choosing another reloads the demo's data from its seed.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

/// The Demo data section.
class DemoDataSection extends ConsumerWidget {
  const DemoDataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PersonaId selected = ref.watch(demoPersonaProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsDemoData),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.demoDataNote,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        RadioGroup<PersonaId>(
          groupValue: selected,
          onChanged: (persona) {
            if (persona != null) {
              ref.read(demoPersonaProvider.notifier).select(persona);
            }
          },
          child: Column(
            children: [
              for (final PersonaId persona in PersonaId.values)
                RadioListTile<PersonaId>(
                  value: persona,
                  title: Text(switch (persona) {
                    PersonaId.renter => l10n.demoPersonaRenter,
                    PersonaId.family => l10n.demoPersonaFamily,
                    PersonaId.student => l10n.demoPersonaStudent,
                    PersonaId.smallBusiness => l10n.demoPersonaSmallBusiness,
                  }),
                  subtitle: Text(switch (persona) {
                    PersonaId.renter => l10n.demoPersonaRenterDetail,
                    PersonaId.family => l10n.demoPersonaFamilyDetail,
                    PersonaId.student => l10n.demoPersonaStudentDetail,
                    PersonaId.smallBusiness =>
                      l10n.demoPersonaSmallBusinessDetail,
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
