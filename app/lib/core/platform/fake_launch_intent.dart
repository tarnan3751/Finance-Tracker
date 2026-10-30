/// The [LaunchIntent] of the tests: started at [start], later links given by [open].
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/launch_intent.dart';

/// Launch links without a platform.
final class FakeLaunchIntent implements LaunchIntent {
  /// Started at [start] (a plain start when null).
  FakeLaunchIntent({this.start});

  /// The link [initial] answers.
  final Uri? start;

  final StreamController<Uri> _opened = StreamController<Uri>.broadcast();

  /// Delivers [link] to the running app, as a tap while it runs would.
  void open(Uri link) => _opened.add(link);

  @override
  Future<Uri?> initial() async => start;

  @override
  Stream<Uri> get opened => _opened.stream;
}
