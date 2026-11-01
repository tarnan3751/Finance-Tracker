/// The configuration of one flavor: which flavor it is, the server it talks to, the name it
/// shows, and how it runs on this device (the app mode).
///
/// Each entry point (`main_dev.dart`, `main_demo.dart`, `main_prod.dart`) builds one of
/// these and hands it to `bootstrap`. The server URL comes from the `FT_SERVER_URL`
/// dart-define: `dev` defaults to the development server as seen from the Android emulator,
/// `prod` has no default, and `demo` never talks to a server. The app mode
/// (`docs/reference/onboarding.md`) is the demo flavor's always; dev and prod are built
/// `live`, and `startApp` replaces that with what the device stores ([withChoices], from
/// `app_mode_store.dart`): the mode chosen on the Welcome screen or none yet, the demo's
/// household and the server URL entered on the sign-in screen. Pure Dart, no Flutter
/// import.
library;

import 'package:persona_engine/persona_engine.dart' show PersonaId;

/// The three flavors, matching the Android product flavors of the same names.
enum Flavor { dev, demo, prod }

/// How the app runs: on the persona engine's demo seed through the in-process fake
/// server, as the demo flavor does, or against the user's own server.
enum AppMode { demo, live }

const String _devServerUrl = String.fromEnvironment(
  'FT_SERVER_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
const String _prodServerUrl = String.fromEnvironment('FT_SERVER_URL');

/// Immutable configuration for one flavor.
final class AppConfig {
  /// The dev flavor: the development server, debug tools.
  AppConfig.dev()
    : flavor = Flavor.dev,
      serverBaseUrl = Uri.parse(_devServerUrl),
      appName = 'Spendthrift Dev',
      mode = AppMode.live,
      demoPersona = null,
      enteredServerUrl = null,
      choosesMode = false;

  /// The demo flavor: fakes and seed data, no network.
  AppConfig.demo()
    : flavor = Flavor.demo,
      serverBaseUrl = null,
      appName = 'Spendthrift Demo',
      mode = AppMode.demo,
      demoPersona = null,
      enteredServerUrl = null,
      choosesMode = false;

  /// The prod flavor: the configured server, if any, which must be HTTPS.
  AppConfig.prod()
    : flavor = Flavor.prod,
      serverBaseUrl = _prodServerUrl.isEmpty ? null : Uri.parse(_prodServerUrl),
      appName = 'Spendthrift',
      mode = AppMode.live,
      demoPersona = null,
      enteredServerUrl = null,
      choosesMode = false;

  AppConfig._(
    AppConfig base, {
    required this.mode,
    required this.demoPersona,
    required this.enteredServerUrl,
  }) : flavor = base.flavor,
       serverBaseUrl = base.serverBaseUrl,
       appName = base.appName,
       choosesMode = true;

  final Flavor flavor;

  /// The API server's base URL compiled into the build, or null when the flavor has none.
  final Uri? serverBaseUrl;

  /// The name shown as the app's title; the Android launcher label matches it.
  final String appName;

  /// How the app runs, or null before one is chosen (the Welcome screen).
  final AppMode? mode;

  /// The demo's household as the device stores it, or null for the default.
  final PersonaId? demoPersona;

  /// The server URL entered on the sign-in screen, or null.
  final Uri? enteredServerUrl;

  /// Whether the mode is the device's choice, which it can change ([withChoices]); a
  /// configuration built directly (the demo flavor's, a test's) keeps its own.
  final bool choosesMode;

  /// Whether the app runs as the demo.
  bool get isDemo => mode == AppMode.demo;

  /// Whether the app runs against the user's server.
  bool get isLive => mode == AppMode.live;

  /// This configuration with the device's choices: [mode] (null: not chosen), the demo's
  /// household and the entered server URL.
  AppConfig withChoices({
    required AppMode? mode,
    PersonaId? demoPersona,
    Uri? enteredServerUrl,
  }) => AppConfig._(
    this,
    mode: mode,
    demoPersona: demoPersona,
    enteredServerUrl: enteredServerUrl,
  );

  /// Whether the UI draws a strip naming the flavor above the app (dev and demo).
  bool get showsFlavorBanner => flavor != Flavor.prod;

  /// Whether "Block screenshots" is on before the user has chosen (`features/lock/`): on
  /// in prod's live mode only. The flavor is the build's part (dev is the developer's
  /// tool, whose screens the acceptance reads), the mode the data's (the demo's made-up
  /// data needs no protection, and nothing is shown before a mode is chosen). The
  /// setting and its behaviour are the same in every flavor and mode.
  bool get secureScreenDefault => isLive && flavor == Flavor.prod;
}
