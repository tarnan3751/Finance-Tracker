/// The [Connectivity] of the demo flavor and the tests: online until a test says not,
/// with every change the test makes delivered to the listeners.
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/connectivity.dart';

/// A network without a platform.
final class FakeConnectivity implements Connectivity {
  /// A network that is up when [online].
  FakeConnectivity({this.online = true});

  /// Whether the network is up.
  bool online;

  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  /// Sets the network up or down and tells the listeners.
  void set(bool online) {
    this.online = online;
    _changes.add(online);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get changes => _changes.stream;

  /// Closes the stream.
  Future<void> close() => _changes.close();
}
