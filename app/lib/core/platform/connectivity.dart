/// The platform boundary for whether a network is up (`docs/reference/background.md`,
/// **The network**): sync runs again when one returns after a failed session
/// (`core/sync/sync_controller.dart`). `connectivity_plus` is behind it in dev and prod
/// (`platform_connectivity.dart`); a fake whose state a test sets stands in for the demo
/// flavor and the tests (`fake_connectivity.dart`). Pure Dart, no Flutter import.
library;

/// Whether the device has a network.
abstract interface class Connectivity {
  /// Whether a network is up now.
  Future<bool> isOnline();

  /// Each change the platform reports: true when a network is up, false when none is.
  /// Over `connectivity_plus` that is a change of the set of network types (Wi-Fi,
  /// mobile, ...): a switch between two networks of one type is not reported.
  Stream<bool> get changes;
}
