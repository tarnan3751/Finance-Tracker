/// The settings screen's Demo data section (while the demo runs): which persona engine
/// household the demo shows. Choosing another reloads the demo's data from its seed and,
/// in dev and prod, keeps the choice for the next start (`app_mode_store.dart`). In dev
/// and prod it also offers "Leave the demo" (`features/onboarding/presentation/
/// leave_demo.dart`); the demo flavor has nowhere to leave to.
library;

import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/section_header.dart';
import 'package:finance_tracker/features/onboarding/presentation/leave_demo.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

final Logger _log = Logger('app');

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
        SectionHeader(l10n.settingsDemoData),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpendthriftTokens.space16,
          ),
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
              unawaited(_keep(ref, persona));
            }
          },
          child: Column(
            children: [
              for (final PersonaId persona in PersonaId.values)
                RadioListTile<PersonaId>(
                  value: persona,
                  title: Text(demoPersonaName(l10n, persona)),
                  subtitle: Text(demoPersonaDetail(l10n, persona)),
                ),
            ],
          ),
        ),
        if (ref.watch(appConfigProvider).flavor != Flavor.demo)
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.leaveDemo),
            subtitle: Text(l10n.leaveDemoSubtitle),
            onTap: () => confirmAndLeaveDemo(context, ref),
          ),
      ],
    );
  }

  // Keeps [persona] for the next start; a store that refuses is logged by type.
  Future<void> _keep(WidgetRef ref, PersonaId persona) async {
    try {
      await ref.read(appModeStoreProvider).writeDemoPersona(persona);
    } on Object catch (e) {
      _log.warning('the demo household was not kept: ${e.runtimeType}');
    }
  }
}

/// The name of the demo household [persona], as the Welcome screen and this section show
/// it.
String demoPersonaName(AppLocalizations l10n, PersonaId persona) =>
    switch (persona) {
      PersonaId.renter => l10n.demoPersonaRenter,
      PersonaId.family => l10n.demoPersonaFamily,
      PersonaId.student => l10n.demoPersonaStudent,
      PersonaId.smallBusiness => l10n.demoPersonaSmallBusiness,
    };

/// The one line describing the demo household [persona].
String demoPersonaDetail(AppLocalizations l10n, PersonaId persona) =>
    switch (persona) {
      PersonaId.renter => l10n.demoPersonaRenterDetail,
      PersonaId.family => l10n.demoPersonaFamilyDetail,
      PersonaId.student => l10n.demoPersonaStudentDetail,
      PersonaId.smallBusiness => l10n.demoPersonaSmallBusinessDetail,
    };
