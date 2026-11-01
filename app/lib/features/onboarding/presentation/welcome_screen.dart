/// The Welcome screen (`/welcome`, `docs/reference/onboarding.md`): where dev and prod
/// open while no app mode is chosen (the router sends every location here). The brand's
/// mark over the wordmark (`brand_mark.dart`), one sentence, and the two ways in: "Try the demo", which opens the demo's
/// households (`demo_persona_screen.dart`), and "Use my own server", which stores the
/// live mode and restarts the app on it, at sign-in.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/brand_mark.dart';
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
            padding: const EdgeInsets.all(SpendthriftTokens.space24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandMark()),
                  const SizedBox(height: SpendthriftTokens.space24),
                  Center(child: Wordmark(ref.watch(appConfigProvider).appName)),
                  const SizedBox(height: SpendthriftTokens.space12),
                  Text(
                    l10n.welcomeBody,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: SpendthriftTokens.space32),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => const WelcomeDemoRoute().push<void>(context),
                    child: Text(l10n.welcomeTryDemo),
                  ),
                  const SizedBox(height: SpendthriftTokens.space12),
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
