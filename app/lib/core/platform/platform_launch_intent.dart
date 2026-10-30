/// The [LaunchIntent] of every flavor on a device: a home screen widget's tap starts
/// `MainActivity` with `home_widget`'s launch action and the link as the intent's data;
/// the plugin answers the starting intent's link (`initiallyLaunchedFromHomeWidget`) and
/// forwards each later one from `onNewIntent` (`widgetClicked`). An intent with no link
/// (the plugin's empty `Uri`) is not passed on. One instance serves the process: the
/// starting intent's link is answered once, so an app started again in the same process
/// (after a restore or a wipe) does not reopen it.
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/launch_intent.dart';
import 'package:home_widget/home_widget.dart';

/// Launch links from the platform.
final class PlatformLaunchIntent implements LaunchIntent {
  PlatformLaunchIntent();

  final StreamController<Uri> _opened = StreamController<Uri>.broadcast();
  bool _started = false;

  @override
  Future<Uri?> initial() async {
    if (_started) return null;
    _started = true;
    // Listened to for the life of the process.
    HomeWidget.widgetClicked.listen((link) {
      if (link != null && link.hasScheme) _opened.add(link);
    });
    final Uri? widget = await HomeWidget.initiallyLaunchedFromHomeWidget();
    return widget != null && widget.hasScheme ? widget : null;
  }

  @override
  Stream<Uri> get opened => _opened.stream;
}
