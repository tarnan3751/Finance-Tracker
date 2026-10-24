// The contract every SettingsRepository implementation passes: the in-memory one now
// (in_memory_settings_repository_test.dart), the Drift one from Phase 1c. Call
// settingsRepositoryContract from a test file with a factory for a fresh, empty
// repository; the factory registers its own teardown with addTearDown.
import 'dart:async';

import 'package:finance_tracker/features/settings/data/settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the contract tests for the implementation [create] builds.
void settingsRepositoryContract(
  String implementation,
  FutureOr<SettingsRepository> Function() create,
) {
  group('$implementation satisfies the SettingsRepository contract', () {
    const Settings changed = Settings(
      themeMode: AppThemeMode.dark,
      useDynamicColor: false,
    );

    test('a fresh repository reads the defaults', () async {
      final SettingsRepository repository = await create();
      expect(await repository.read(), const Settings.defaults());
    });

    test('a fresh repository watches the defaults first', () async {
      final SettingsRepository repository = await create();
      expect(await repository.watch().first, const Settings.defaults());
    });

    test('read returns what was saved', () async {
      final SettingsRepository repository = await create();
      await repository.save(changed);
      expect(await repository.read(), changed);
    });

    test('a watcher gets the current value, then each save in order', () async {
      final SettingsRepository repository = await create();
      final Future<List<Settings>> seen = repository.watch().take(3).toList();
      await pumpEventQueue();

      await repository.save(changed);
      await pumpEventQueue();
      await repository.save(changed.copyWith(themeMode: AppThemeMode.light));

      expect(await seen, [
        const Settings.defaults(),
        changed,
        changed.copyWith(themeMode: AppThemeMode.light),
      ]);
    });

    test(
      'a watcher that starts after a save gets the saved value first',
      () async {
        final SettingsRepository repository = await create();
        await repository.save(changed);
        expect(await repository.watch().first, changed);
      },
    );

    test('every watcher is told of a save', () async {
      final SettingsRepository repository = await create();
      final Future<List<Settings>> first = repository.watch().take(2).toList();
      final Future<List<Settings>> second = repository.watch().take(2).toList();
      await pumpEventQueue();

      await repository.save(changed);

      expect(await first, [const Settings.defaults(), changed]);
      expect(await second, [const Settings.defaults(), changed]);
    });
  });
}
