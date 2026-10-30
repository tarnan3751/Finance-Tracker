/// The [WidgetWriter] of the tests: no widgets, every snapshot recorded.
library;

import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/features/widgets/domain/widget_writer.dart';

/// The widget writer without a platform.
final class FakeWidgetWriter implements WidgetWriter {
  /// Every snapshot [write] was given, in order.
  final List<WidgetData> writes = [];

  /// The snapshot last written, or null before the first write.
  WidgetData? get last => writes.isEmpty ? null : writes.last;

  /// Thrown by [write] after it records the snapshot, when set.
  Object? failure;

  /// How many times [clear] ran.
  int clears = 0;

  /// Whether a snapshot is stored: one was written since the last [clear].
  bool get holdsSnapshot => _holds;
  bool _holds = false;

  @override
  Future<void> clear() async {
    clears++;
    _holds = false;
  }

  @override
  Future<void> write(WidgetData data) async {
    writes.add(data);
    _holds = true;
    if (failure case final Object e) throw e;
  }
}
