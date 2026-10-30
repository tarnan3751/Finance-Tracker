/// Which [LaunchIntent] reports the links the app is opened at: the fake by default (the
/// tests), the platform's in every flavor (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/fake_launch_intent.dart';
import 'package:finance_tracker/core/platform/launch_intent.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'launch_intent_provider.g.dart';

/// The launch links.
@Riverpod(keepAlive: true)
LaunchIntent launchIntent(Ref ref) => FakeLaunchIntent();
