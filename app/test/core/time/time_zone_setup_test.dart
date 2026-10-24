// Time zone setup: a known zone becomes tz.local; an unknown zone, or a platform call that
// fails, leaves the current zone (UTC unless something set it) and logs a warning.
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  tearDown(() => tz.setLocalLocation(tz.UTC));

  test('a known identifier becomes the local zone', () {
    applyLocalTimeZone('America/Chicago');
    expect(tz.local.name, 'America/Chicago');
  });

  test(
    'an unknown identifier leaves the zone as it was and logs a warning',
    () {
      final tz.Location before = tz.local;
      expect(before.currentTimeZone.offset, Duration.zero);
      final List<LogRecord> records = [];
      Logger.root.level = Level.ALL;
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);

      applyLocalTimeZone('Mars/Olympus_Mons');

      expect(tz.local, same(before));
      expect(records, hasLength(1));
      expect(records.single.level, Level.WARNING);
      expect(records.single.message, contains('Mars/Olympus_Mons'));
    },
  );

  group('setUpTimeZones', () {
    const MethodChannel channel = MethodChannel('flutter_timezone');
    late List<LogRecord> records;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      records = [];
      Logger.root.level = Level.ALL;
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
    });

    void answer(Future<Object?>? Function(MethodCall call)? handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
    }

    test('sets the zone the platform reports', () async {
      answer((call) async => 'Asia/Kolkata');

      await setUpTimeZones();

      expect(tz.local.name, 'Asia/Kolkata');
      expect(records, isEmpty);
    });

    test('a platform exception leaves the zone and logs a warning', () async {
      final tz.Location before = tz.local;
      answer((call) async => throw PlatformException(code: 'UNAVAILABLE'));

      await setUpTimeZones();

      expect(tz.local, same(before));
      expect(records.single.level, Level.WARNING);
      expect(records.single.message, contains('UNAVAILABLE'));
    });

    test('a missing plugin leaves the zone and logs a warning', () async {
      final tz.Location before = tz.local;
      answer(null);

      await setUpTimeZones();

      expect(tz.local, same(before));
      expect(records.single.level, Level.WARNING);
      expect(records.single.message, contains('MissingPluginException'));
    });
  });
}
