/// The root widget: `MaterialApp.router` with the router, the light and dark themes (from
/// the device's dynamic colors when it has them and the setting is on), the theme mode
/// from settings, the localizations in the language chosen on this device (the device's
/// own unless English or, in dev and demo only, the pseudo-locale is chosen), the flavor
/// banner in dev and demo, and above them all the app lock's gate
/// (`features/lock/presentation/lock_gate.dart`).
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/widgets/flavor_banner.dart';
import 'package:finance_tracker/features/lock/presentation/lock_gate.dart';
import 'package:finance_tracker/features/settings/application/app_language_controller.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
import 'package:finance_tracker/features/settings/domain/app_language.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app. Needs a `ProviderScope` with `appConfigProvider` overridden.
class FinanceTrackerApp extends ConsumerWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);
    final Settings settings =
        ref.watch(settingsControllerProvider).value ??
        const Settings.defaults();
    final router = ref.watch(goRouterProvider);
    // The pseudo-locale is a developer's check, never offered in prod.
    final bool pseudoAllowed = config.flavor != Flavor.prod;
    final AppLanguage language = pseudoAllowed
        ? ref.watch(appLanguageControllerProvider).value ?? AppLanguage.system
        : AppLanguage.system;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final bool useDynamic =
            settings.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null;
        return MaterialApp.router(
          title: config.appName,
          // In dev and demo the flavor strip marks the build; the debug banner would cover
          // the top-end app bar action the strip keeps clear.
          debugShowCheckedModeBanner: !config.showsFlavorBanner,
          theme: AppTheme.light(useDynamic ? lightDynamic : null),
          darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
          themeMode: _themeMode(settings.themeMode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            for (final Locale locale in AppLocalizations.supportedLocales)
              if (pseudoAllowed || locale != pseudoLocale) locale,
          ],
          locale: switch (language) {
            AppLanguage.system => null,
            AppLanguage.english => const Locale('en'),
            AppLanguage.pseudo => pseudoLocale,
          },
          routerConfig: router,
          // The lock's gate sits above the router, so the lock screen covers every
          // route and dialog.
          builder: (context, child) => LockGate(
            child: config.showsFlavorBanner
                ? FlavorBanner(
                    // The flavor's identifier, not prose, so it is not localized.
                    message: config.flavor.name.toUpperCase(),
                    child: child ?? const SizedBox.shrink(),
                  )
                : child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

ThemeMode _themeMode(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => ThemeMode.system,
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};

/// The pseudo-locale (`tools/pseudo_locale.dart`): Android's own name for it.
const Locale pseudoLocale = Locale('en', 'XA');
