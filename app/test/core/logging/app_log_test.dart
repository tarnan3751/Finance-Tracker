// setUpLogging: prod keeps only the most recent records in memory; dev and demo keep none.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  test(
    'prod keeps the last $recentLogCapacity records, oldest first',
    () async {
      setUpLogging(Flavor.prod);
      final Logger log = Logger('test');
      for (int i = 0; i < recentLogCapacity + 20; i++) {
        log.info('record $i');
      }
      await Future<void>.delayed(Duration.zero);

      final List<LogRecord> kept = recentLogRecords();
      expect(kept, hasLength(recentLogCapacity));
      expect(kept.first.message, 'record 20');
      expect(kept.last.message, 'record ${recentLogCapacity + 19}');
    },
  );

  test('demo prints records instead of keeping them', () async {
    final List<String?> printed = [];
    final DebugPrintCallback original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => printed.add(message);
    addTearDown(() => debugPrint = original);

    setUpLogging(Flavor.demo);
    Logger('test').warning('hello');
    await Future<void>.delayed(Duration.zero);

    expect(recentLogRecords(), isEmpty);
    expect(printed, ['WARNING test: hello']);
  });
}
