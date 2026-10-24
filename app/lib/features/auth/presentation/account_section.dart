/// The Settings screen's Account section: who is signed in, the linked banks, Sign out
/// (not in demo, which is always the demo user), and in dev the server the app talks to. Nothing while signed
/// out, which outside demo the router never shows.
library;

import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Account section.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppConfig config = ref.watch(appConfigProvider);
    final SessionState session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();
    final Uri? server = config.serverBaseUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionHeader(l10n.settingsAccount),
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(l10n.settingsSignedInAs(session.user.email)),
          subtitle: Text(session.user.displayName),
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_outlined),
          title: Text(l10n.itemsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => const ItemsRoute().push<void>(context),
        ),
        if (config.flavor != Flavor.demo)
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.settingsSignOut),
            onTap: () => ref.read(sessionControllerProvider.notifier).signOut(),
          ),
        if (config.flavor == Flavor.dev)
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.settingsServer),
            subtitle: Text(
              fakeServerInDev || server == null
                  ? l10n.settingsServerFake
                  : apiBaseUrl(server),
            ),
          ),
      ],
    );
  }
}
