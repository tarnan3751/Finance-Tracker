/// The root widget: `MaterialApp.router` with the router, the light and dark themes (from
/// the device's dynamic colors when it has them and the setting is on), the theme mode
/// from settings, the localizations, and the flavor banner in dev and demo.
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/widgets/flavor_banner.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
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

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final bool useDynamic =
            settings.useDynamicColor &&
            lightDynamic != null &&
            darkDynamic != null;
        return MaterialApp.router(
          title: config.appName,
          // The debug banner sits in the same corner and would hide the flavor banner.
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
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: config.showsFlavorBanner
              ? (context, child) => FlavorBanner(
                  // The flavor's identifier, not prose, so it is not localized.
                  message: config.flavor.name.toUpperCase(),
                  child: child ?? const SizedBox.shrink(),
                )
              : null,
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
