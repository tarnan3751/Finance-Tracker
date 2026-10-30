/// The [Connectivity] of dev and prod, over `connectivity_plus` 7.3.2 (BSD-3): Android's
/// default-network callback, a result of `none` meaning no network. The plugin reports a
/// change of the set of network types only (it applies `distinct()`), so a switch between
/// two Wi-Fi networks, say, is not a change here.
library;

import 'package:connectivity_plus/connectivity_plus.dart' as plus;
import 'package:finance_tracker/core/platform/connectivity.dart';

/// Whether a network is up, from the platform.
final class PlatformConnectivity implements Connectivity {
  /// The connectivity over [plugin], the plugin's by default.
  PlatformConnectivity([plus.Connectivity? plugin])
    : _plugin = plugin ?? plus.Connectivity();

  final plus.Connectivity _plugin;

  static bool _up(List<plus.ConnectivityResult> results) =>
      !results.every((r) => r == plus.ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _up(await _plugin.checkConnectivity());

  @override
  Stream<bool> get changes => _plugin.onConnectivityChanged.map(_up);
}
