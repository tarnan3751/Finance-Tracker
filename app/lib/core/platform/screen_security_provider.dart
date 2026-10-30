/// Which [ScreenSecurity] sets the window's secure flag: the fake by default (the tests),
/// the app's channel in every flavor (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/fake_screen_security.dart';
import 'package:finance_tracker/core/platform/screen_security.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_security_provider.g.dart';

/// The screen security.
@Riverpod(keepAlive: true)
ScreenSecurity screenSecurity(Ref ref) => FakeScreenSecurity();
