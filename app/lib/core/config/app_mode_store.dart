/// Where this device keeps how the app runs (`docs/reference/onboarding.md`): the app
/// mode chosen on the Welcome screen (`app_mode`: `demo` or `live`), the demo's household
/// (`demo_persona`) and the server URL entered on the sign-in screen (`server_url`), in
/// the preferences beside the wipe's pending record (`core/db/local_wipe.dart`), outside
/// the database, so `startApp` reads them before anything local opens.
///
/// - No stored mode is the fresh install's "not chosen", except on an install that holds
///   an account (its user is recorded, `install_user_v1`): one built before the mode
///   existed, which is `live` and is written so. A marker that cannot be read counts as
///   recorded, so an install that may hold an account never lands on Welcome, whose demo
///   ends in a wipe.
/// - The local wipe clears all three ([AppModeStore.clear]), so the next start is a fresh
///   install's, on Welcome.
/// - The demo flavor keeps none of them: it is always the demo, on `FT_DEMO_PERSONA`.
library;

import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:logging/logging.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_preferences/shared_preferences.dart';

final Logger _log = Logger('app');

/// What [AppModeStore] holds.
final class StoredAppMode {
  const StoredAppMode({this.mode, this.demoPersona, this.serverUrl});

  /// The chosen mode, or null when none is.
  final AppMode? mode;

  /// The demo's household, or null for the default.
  final PersonaId? demoPersona;

  /// The server URL entered on the sign-in screen, or null.
  final Uri? serverUrl;
}

/// Reads and writes the device's app mode, demo household and entered server URL.
abstract interface class AppModeStore {
  /// What is stored.
  Future<StoredAppMode> read();

  /// Stores [mode].
  Future<void> writeMode(AppMode mode);

  /// Stores [persona] as the demo's household.
  Future<void> writeDemoPersona(PersonaId persona);

  /// Stores [url] as the entered server URL.
  Future<void> writeServerUrl(Uri url);

  /// Removes all three.
  Future<void> clear();
}

/// [config] with what [store] holds (the demo flavor's as it is).
Future<AppConfig> resolveAppConfig(AppConfig config, AppModeStore store) async {
  if (config.flavor == Flavor.demo) return config;
  final StoredAppMode stored = await store.read();
  return config.withChoices(
    mode: stored.mode,
    demoPersona: stored.demoPersona,
    enteredServerUrl: stored.serverUrl,
  );
}

/// The device's store: the preferences, and the install's user from secure storage.
AppModeStore deviceAppModeStore() => PreferencesAppModeStore(
  preferences: SharedPreferences.getInstance,
  installUser: () => SecureTokenStore().readInstallUserId(),
);

/// The store over the preferences.
final class PreferencesAppModeStore implements AppModeStore {
  PreferencesAppModeStore({
    required this.preferences,
    required this.installUser,
  });

  static const String modeKey = 'app_mode';
  static const String personaKey = 'demo_persona';
  static const String serverUrlKey = 'server_url';

  final Future<SharedPreferences> Function() preferences;

  /// The install's user (`TokenStore.readInstallUserId`).
  final Future<String?> Function() installUser;

  @override
  Future<StoredAppMode> read() async {
    final SharedPreferences prefs = await preferences();
    // The other engine (the app or the background task's) may have written since.
    await prefs.reload();
    AppMode? mode = AppMode.values.asNameMap()[prefs.getString(modeKey)];
    if (mode == null && await _holdsAccount()) {
      mode = AppMode.live;
      await prefs.setString(modeKey, mode.name);
    }
    final String? slug = prefs.getString(personaKey);
    final String? url = prefs.getString(serverUrlKey);
    return StoredAppMode(
      mode: mode,
      demoPersona: PersonaId.values.where((p) => p.slug == slug).firstOrNull,
      serverUrl: url == null ? null : Uri.tryParse(url),
    );
  }

  Future<bool> _holdsAccount() async {
    try {
      return await installUser() != null;
    } on Object catch (e) {
      _log.warning('the install user could not be read: ${e.runtimeType}');
      return true;
    }
  }

  @override
  Future<void> writeMode(AppMode mode) async =>
      (await preferences()).setString(modeKey, mode.name);

  @override
  Future<void> writeDemoPersona(PersonaId persona) async =>
      (await preferences()).setString(personaKey, persona.slug);

  @override
  Future<void> writeServerUrl(Uri url) async =>
      (await preferences()).setString(serverUrlKey, url.toString());

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await preferences();
    for (final String key in [modeKey, personaKey, serverUrlKey]) {
      await prefs.remove(key);
    }
  }
}

/// The store in memory: the tests' and the demo flavor's.
final class InMemoryAppModeStore implements AppModeStore {
  InMemoryAppModeStore({this.mode, this.demoPersona, this.serverUrl});

  AppMode? mode;
  PersonaId? demoPersona;
  Uri? serverUrl;

  /// How many times [clear] ran.
  int clears = 0;

  @override
  Future<StoredAppMode> read() async =>
      StoredAppMode(mode: mode, demoPersona: demoPersona, serverUrl: serverUrl);

  @override
  Future<void> writeMode(AppMode mode) async => this.mode = mode;

  @override
  Future<void> writeDemoPersona(PersonaId persona) async =>
      demoPersona = persona;

  @override
  Future<void> writeServerUrl(Uri url) async => serverUrl = url;

  @override
  Future<void> clear() async {
    mode = null;
    demoPersona = null;
    serverUrl = null;
    clears++;
  }
}
