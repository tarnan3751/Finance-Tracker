/// The [ScreenSecurity] of the tests: no window, every call recorded.
library;

import 'package:finance_tracker/core/platform/screen_security.dart';

/// The secure flag without a platform.
final class FakeScreenSecurity implements ScreenSecurity {
  /// Every value [set] was given, in order.
  final List<bool> calls = [];

  /// The flag as last set, or null before the first call.
  bool? get secure => calls.isEmpty ? null : calls.last;

  @override
  Future<void> set(bool secure) async => calls.add(secure);
}
