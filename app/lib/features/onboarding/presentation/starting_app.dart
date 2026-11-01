/// What the app shows while it restarts on the app mode the Welcome screen stored
/// (`bootstrap`'s mode restart, `docs/reference/onboarding.md`): a plain screen with a
/// progress indicator, while the running app stops and the new one, the demo's seed
/// generated or the local database opened, starts.
library;

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The starting screen's app.
class StartingApp extends StatelessWidget {
  const StartingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            semanticsLabel: AppLocalizations.of(context).startingApp,
          ),
        ),
      ),
    ),
  );
}
