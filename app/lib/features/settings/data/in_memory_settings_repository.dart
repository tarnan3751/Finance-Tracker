/// A [SettingsRepository] held in memory: what tests use, and the base of the demo
/// flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Settings kept in memory for the life of the object. Every save records the fields it
/// changed in the settings record through [recorder], as an update against the current
/// settings.
base class InMemorySettingsRepository implements SettingsRepository {
  /// A repository holding [initial], or the defaults, recording through [recorder].
  InMemorySettingsRepository({
    required this.recorder,
    Settings initial = const Settings.defaults(),
  }) : _current = initial;

  /// Where the saves are recorded.
  final ChangeRecorder recorder;

  Settings _current;
  final StreamController<Settings> _changes =
      StreamController<Settings>.broadcast();

  @override
  Stream<Settings> watch() => Stream<Settings>.multi((controller) {
    controller.add(_current);
    final StreamSubscription<Settings> subscription = _changes.stream.listen(
      controller.add,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Settings> read() async => _current;

  @override
  Future<void> save(Settings settings) async {
    final Map<String, Object?> before = settingsRecordJson(_current);
    _current = settings;
    _changes.add(settings);
    await recorder.record(
      EntityType.settings,
      settingsRecordId,
      before,
      settingsRecordJson(settings),
    );
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
