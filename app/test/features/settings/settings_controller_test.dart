// SettingsController follows the repository and saves the changes the screen makes.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/settings/application/settings_controller.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemorySettingsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = InMemorySettingsRepository();
    addTearDown(repository.close);
    container = ProviderContainer.test(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
  });

  test('starts with the stored settings', () async {
    // Riverpod 3 pauses a provider nobody listens to, so every test listens first.
    container.listen(settingsControllerProvider, (_, _) {});
    expect(
      await container.read(settingsControllerProvider.future),
      const Settings.defaults(),
    );
  });

  test('setThemeMode saves the mode and the controller follows', () async {
    container.listen(settingsControllerProvider, (_, _) {});
    await container.read(settingsControllerProvider.future);

    await container
        .read(settingsControllerProvider.notifier)
        .setThemeMode(AppThemeMode.dark);
    await pumpEventQueue();

    expect((await repository.read()).themeMode, AppThemeMode.dark);
    expect(
      container.read(settingsControllerProvider).value?.themeMode,
      AppThemeMode.dark,
    );
  });

  test('setUseDynamicColor saves the flag and keeps the theme mode', () async {
    await repository.save(
      const Settings(themeMode: AppThemeMode.light, useDynamicColor: true),
    );
    container.listen(settingsControllerProvider, (_, _) {});
    await container.read(settingsControllerProvider.future);

    await container
        .read(settingsControllerProvider.notifier)
        .setUseDynamicColor(false);
    await pumpEventQueue();

    expect(
      container.read(settingsControllerProvider).value,
      const Settings(themeMode: AppThemeMode.light, useDynamicColor: false),
    );
  });

  test('two changes issued together both land', () async {
    container.listen(settingsControllerProvider, (_, _) {});
    await container.read(settingsControllerProvider.future);
    final SettingsController controller = container.read(
      settingsControllerProvider.notifier,
    );

    final Future<void> themeMode = controller.setThemeMode(AppThemeMode.dark);
    final Future<void> dynamicColor = controller.setUseDynamicColor(false);
    await Future.wait([themeMode, dynamicColor]);
    await pumpEventQueue();

    const Settings both = Settings(
      themeMode: AppThemeMode.dark,
      useDynamicColor: false,
    );
    expect(await repository.read(), both);
    expect(container.read(settingsControllerProvider).value, both);
  });
}
