// Builds and pumps the real app for widget and golden tests: the real ProviderScope,
// FinanceTrackerApp (router, themes, localizations, flavor banner), with the dependencies
// a test must pin overridden: the flavor, the clock, the package info and the settings.
//
//   await pumpApp(tester, initialLocation: '/settings', brightness: Brightness.dark);
//
// A test's own `overrides` come after the defaults, so they win. Riverpod's automatic
// retry is off, so a failing provider fails the test at once.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;

/// The phone size goldens and screen tests use, in logical pixels.
const Size phoneSize = Size(412, 915);

/// The tablet size of the tablet golden, in logical pixels.
const Size tabletSize = Size(1024, 768);

/// The package metadata tests see.
final PackageInfo testPackageInfo = PackageInfo(
  appName: 'Finance Tracker',
  packageName: 'dev.tarnan.financetracker',
  version: '1.0.0',
  buildNumber: '1',
);

/// The instant and zone tests run at: 24 October 2026, 15:00 UTC.
final Clock testClock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

/// The app as a widget, for goldens (which pump it themselves) and for [pumpApp]: the
/// real `ProviderScope` with [testOverrides] around `FinanceTrackerApp`.
Widget buildTestApp({
  List<Override> overrides = const [],
  AppConfig? config,
  String initialLocation = '/accounts',
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: testOverrides(
      overrides: overrides,
      config: config,
      initialLocation: initialLocation,
      brightness: brightness,
    ),
    child: const FinanceTrackerApp(),
  );
}

/// The overrides of a test app: [config] (prod, which draws no flavor banner, by
/// default), [testClock], [testPackageInfo], settings whose theme mode gives
/// [brightness], and a router opening at [initialLocation]; then [overrides], which win.
/// A test that overrides `settingsRepositoryProvider` itself sets the theme mode there.
List<Override> testOverrides({
  List<Override> overrides = const [],
  AppConfig? config,
  String initialLocation = '/accounts',
  Brightness brightness = Brightness.light,
}) => [
  ...overridesFor(config ?? AppConfig.prod()),
  clockProvider.overrideWithValue(testClock),
  packageInfoProvider.overrideWith((ref) async => testPackageInfo),
  settingsRepositoryProvider.overrideWith((ref) {
    final InMemorySettingsRepository repository = InMemorySettingsRepository(
      const Settings.defaults().copyWith(
        themeMode: brightness == Brightness.dark
            ? AppThemeMode.dark
            : AppThemeMode.light,
      ),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  goRouterProvider.overrideWith((ref) {
    final router = createRouter(initialLocation: initialLocation);
    ref.onDispose(router.dispose);
    return router;
  }),
  ...overrides,
];

/// Pumps [buildTestApp] at [phoneSize] (or [size]) and [textScale], and settles.
Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  AppConfig? config,
  String initialLocation = '/accounts',
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  Size size = phoneSize,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    buildTestApp(
      overrides: overrides,
      config: config,
      initialLocation: initialLocation,
      brightness: brightness,
    ),
  );
  await tester.pumpAndSettle();
}
