// Builds and pumps the real app for widget and golden tests: the real ProviderScope,
// FinanceTrackerApp (router, themes, localizations, flavor banner), with the dependencies
// a test must pin overridden: the flavor, the clock, the package info and the settings.
// The flavor's own wiring (overridesFor: the Drift or demo repositories) is not applied,
// so every test runs on the in-memory repositories whatever its flavor. The API is the
// real client on the in-app fake server (fakeServerProvider), and the app starts signed
// in as the demo user unless `signedIn: false`; the router is the flavor's, so dev and
// prod tests go through the session gate.
//
//   await pumpApp(tester, initialLocation: '/settings', brightness: Brightness.dark);
//
// A test's own `overrides` come after the defaults, so they win; a screen with no route
// of its own (the forecast) is given its own `router`. Riverpod's automatic retry is off,
// so a failing provider fails the test at once.
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  Clock? clock,
  bool signedIn = true,
  GoRouter Function(Ref ref)? router,
}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: testOverrides(
      overrides: overrides,
      config: config,
      initialLocation: initialLocation,
      brightness: brightness,
      clock: clock,
      signedIn: signedIn,
      router: router,
    ),
    child: const FinanceTrackerApp(),
  );
}

/// The overrides of a test app: [config] (prod, which draws no flavor banner, by
/// default) as `appConfigProvider` only, [clock] ([testClock] by default),
/// [testPackageInfo], settings whose theme mode gives
/// [brightness], the fake server with the demo user signed in when [signedIn] (the
/// device named "Pixel 6"), and the flavor's router opening at [initialLocation] ([router]
/// instead when given); then [overrides], which win.
/// A test that overrides `settingsRepositoryProvider` itself sets the theme mode there.
List<Override> testOverrides({
  List<Override> overrides = const [],
  AppConfig? config,
  String initialLocation = '/accounts',
  Brightness brightness = Brightness.light,
  Clock? clock,
  bool signedIn = true,
  GoRouter Function(Ref ref)? router,
}) => [
  appConfigProvider.overrideWithValue(config ?? AppConfig.prod()),
  clockProvider.overrideWithValue(clock ?? testClock),
  packageInfoProvider.overrideWith((ref) async => testPackageInfo),
  settingsRepositoryProvider.overrideWith((ref) {
    final InMemorySettingsRepository repository = InMemorySettingsRepository(
      recorder: const NoChangeRecorder(),
      initial: const Settings.defaults().copyWith(
        themeMode: brightness == Brightness.dark
            ? AppThemeMode.dark
            : AppThemeMode.light,
      ),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  ...fakeApiOverrides(signedIn: signedIn),
  deviceNameProvider.overrideWith((ref) async => 'Pixel 6'),
  appVersionProvider.overrideWith((ref) async => testPackageInfo.version),
  goRouterProvider.overrideWith(
    (ref) =>
        router?.call(ref) ?? routerFor(ref, initialLocation: initialLocation),
  ),
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
  Clock? clock,
  bool signedIn = true,
  GoRouter Function(Ref ref)? router,
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
      clock: clock,
      signedIn: signedIn,
      router: router,
    ),
  );
  await tester.pumpAndSettle();
}
