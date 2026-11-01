/// The Welcome screen (`/welcome`, `docs/reference/onboarding.md`): where dev and prod
/// open while no app mode is chosen (the router sends every location here). The app's
/// name, one sentence, and the two ways in: "Try the demo", which opens the demo's
/// households (`demo_persona_screen.dart`), and "Use my own server", which stores the
/// live mode and restarts the app on it, at sign-in.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/onboarding/presentation/mode_choice.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Welcome screen.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _useServer() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool stored = await storeChoiceAndRestart(
      context,
      ref,
      (modes) => modes.writeMode(AppMode.live),
    );
    if (!stored && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      ref.watch(appConfigProvider).appName,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.welcomeBody,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => const WelcomeDemoRoute().push<void>(context),
                    child: Text(l10n.welcomeTryDemo),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _useServer,
                    child: Text(l10n.welcomeUseServer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
