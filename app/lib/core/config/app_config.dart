/// The build-time configuration of one flavor: which flavor it is, the server it talks to,
/// and the name it shows.
///
/// Each entry point (`main_dev.dart`, `main_demo.dart`, `main_prod.dart`) builds one of
/// these and hands it to `bootstrap`. The server URL comes from the `FT_SERVER_URL`
/// dart-define: `dev` defaults to the development server as seen from the Android emulator,
/// `prod` has no default, and `demo` never talks to a server. Pure Dart, no Flutter import.
library;

/// The three flavors, matching the Android product flavors of the same names.
enum Flavor { dev, demo, prod }

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
      appName = 'Finance Tracker Dev';

  /// The demo flavor: fakes and seed data, no network.
  AppConfig.demo()
    : flavor = Flavor.demo,
      serverBaseUrl = null,
      appName = 'Finance Tracker Demo';

  /// The prod flavor: the configured server, if any, which must be HTTPS.
  AppConfig.prod()
    : flavor = Flavor.prod,
      serverBaseUrl = _prodServerUrl.isEmpty ? null : Uri.parse(_prodServerUrl),
      appName = 'Finance Tracker';

  final Flavor flavor;

  /// The API server's base URL, or null when the flavor has none.
  final Uri? serverBaseUrl;

  /// The name shown as the app's title; the Android launcher label matches it.
  final String appName;

  /// Whether the UI draws a corner banner naming the flavor (dev and demo).
  bool get showsFlavorBanner => flavor != Flavor.prod;
}
