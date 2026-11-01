// The device's app mode store: what it keeps in the preferences and clears, an install
// that holds an account (or may) resolving to live and written so, and the configuration
// it gives (the demo flavor's untouched).
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  PreferencesAppModeStore store({String? installUser, bool fails = false}) =>
      PreferencesAppModeStore(
        preferences: SharedPreferences.getInstance,
        installUser: () async =>
            fails ? throw StateError('keystore') : installUser,
      );

  setUp(() => SharedPreferences.setMockInitialValues({'unrelated': 'kept'}));

  test('a fresh install has chosen nothing', () async {
    final StoredAppMode stored = await store().read();
    expect(stored.mode, isNull);
    expect(stored.demoPersona, isNull);
    expect(stored.serverUrl, isNull);
  });

  test(
    'keeps the mode, the household and the server URL, and clears them',
    () async {
      final PreferencesAppModeStore modes = store();
      await modes.writeMode(AppMode.demo);
      await modes.writeDemoPersona(PersonaId.smallBusiness);
      await modes.writeServerUrl(Uri.parse('https://money.example.com/ft'));
      StoredAppMode stored = await store().read();
      expect(stored.mode, AppMode.demo);
      expect(stored.demoPersona, PersonaId.smallBusiness);
      expect(stored.serverUrl, Uri.parse('https://money.example.com/ft'));

      await modes.clear();
      stored = await store().read();
      expect(stored.mode, isNull);
      expect(stored.demoPersona, isNull);
      expect(stored.serverUrl, isNull);
      expect((await SharedPreferences.getInstance()).getKeys(), {'unrelated'});
    },
  );

  test('an install that holds an account is live, and is written so', () async {
    expect((await store(installUser: 'user-1').read()).mode, AppMode.live);
    // Written: it stays live once the marker is gone.
    expect((await store().read()).mode, AppMode.live);
  });

  test('a marker that cannot be read counts as an account', () async {
    expect((await store(fails: true).read()).mode, AppMode.live);
  });

  test(
    'a stored mode wins over the marker; an unknown value is none',
    () async {
      await store().writeMode(AppMode.demo);
      expect((await store(installUser: 'user-1').read()).mode, AppMode.demo);
      SharedPreferences.setMockInitialValues({
        PreferencesAppModeStore.modeKey: 'kiosk',
        PreferencesAppModeStore.personaKey: 'landlord',
      });
      final StoredAppMode stored = await store().read();
      expect(stored.mode, isNull);
      expect(stored.demoPersona, isNull);
    },
  );

  test(
    'the configuration takes the choices; the demo flavor keeps its own',
    () async {
      final InMemoryAppModeStore modes = InMemoryAppModeStore(
        mode: AppMode.demo,
        demoPersona: PersonaId.family,
        serverUrl: Uri.parse('https://money.example.com'),
      );
      final AppConfig prod = await resolveAppConfig(AppConfig.prod(), modes);
      expect(prod.flavor, Flavor.prod);
      expect(prod.isDemo, isTrue);
      expect(prod.choosesMode, isTrue);
      expect(prod.demoPersona, PersonaId.family);
      expect(prod.enteredServerUrl, Uri.parse('https://money.example.com'));
      expect(prod.appName, AppConfig.prod().appName);

      modes.mode = null;
      final AppConfig chosen = await resolveAppConfig(AppConfig.dev(), modes);
      expect(chosen.mode, isNull);
      expect(chosen.isDemo || chosen.isLive, isFalse);

      final AppConfig demo = await resolveAppConfig(AppConfig.demo(), modes);
      expect(demo.isDemo, isTrue);
      expect(demo.choosesMode, isFalse);
      expect(demo.demoPersona, isNull);
    },
  );

  test('a configuration built directly is live, or the demo flavor', () {
    expect(AppConfig.dev().isLive, isTrue);
    expect(AppConfig.prod().isLive, isTrue);
    expect(AppConfig.demo().isDemo, isTrue);
    expect(AppConfig.prod().choosesMode, isFalse);
  });
}
