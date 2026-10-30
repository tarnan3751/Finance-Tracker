/// The platform boundary for the home screen widgets (`docs/reference/widgets.md`,
/// **The writer**): the app hands a [WidgetData] snapshot to a [WidgetWriter], which
/// stores it where the widgets read it and asks them to redraw. `home_widget` is behind it
/// in every flavor (`data/home_widget_writer.dart`); a fake that records stands in for the
/// tests. The app's refresh runner and the background cycle call the same writer. Pure
/// Dart, no Flutter import.
library;

import 'package:finance_tracker/features/widgets/domain/widget_data.dart';

/// Stores a snapshot for the home screen widgets and redraws them.
abstract interface class WidgetWriter {
  /// Replaces the widgets' snapshot with [data] and redraws every placed widget. Throws
  /// when the platform fails.
  Future<void> write(WidgetData data);

  /// Removes the snapshot and redraws every placed widget, which then offers to set the
  /// app up (the local wipe's step). Throws when the platform fails.
  Future<void> clear();
}
