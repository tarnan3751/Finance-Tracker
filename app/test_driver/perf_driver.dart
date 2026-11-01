// The driver of the performance integration tests (docs/reference/performance.md): runs
// the test, then summarises each timeline the test traced (`start`, `scroll`) with
// flutter_driver's TimelineSummary into build/perf/<key>.timeline_summary.json, and writes
// the test's other figures (`data_on_screen_ms`, `ledger_rows`) to
// build/perf/perf_drive.json. Used only by tools/perf/scroll.sh through `flutter drive`.
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

const String _out = 'build/perf';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 20),
  responseDataCallback: (Map<String, dynamic>? data) async {
    if (data == null) return;
    final Map<String, dynamic> figures = {};
    for (final MapEntry<String, dynamic> e in data.entries) {
      final Object? value = e.value;
      if (value is Map<String, dynamic> && value.containsKey('traceEvents')) {
        await writeResponseData(
          TimelineSummary.summarize(Timeline.fromJson(value)).summaryJson,
          testOutputFilename: '${e.key}.timeline_summary',
          destinationDirectory: _out,
        );
      } else {
        figures[e.key] = value;
      }
    }
    await writeResponseData(
      figures,
      testOutputFilename: 'perf_drive',
      destinationDirectory: _out,
    );
  },
);
