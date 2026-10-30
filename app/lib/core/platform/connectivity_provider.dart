/// Which [Connectivity] says whether a network is up: the fake by default (the demo
/// flavor and the tests), `connectivity_plus` in dev and prod (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/connectivity.dart';
import 'package:finance_tracker/core/platform/fake_connectivity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// The connectivity.
@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) {
  final FakeConnectivity connectivity = FakeConnectivity();
  ref.onDispose(connectivity.close);
  return connectivity;
}
