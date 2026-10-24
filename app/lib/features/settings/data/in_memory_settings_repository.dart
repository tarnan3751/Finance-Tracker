/// A [SettingsRepository] held in memory: what tests use, and the base of the demo
/// flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';

/// Settings kept in memory for the life of the object.
base class InMemorySettingsRepository implements SettingsRepository {
  /// A repository holding [initial], or the defaults.
  InMemorySettingsRepository([Settings initial = const Settings.defaults()])
    : _current = initial;

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
    _current = settings;
    _changes.add(settings);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
