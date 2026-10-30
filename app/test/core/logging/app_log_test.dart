// setUpLogging: prod keeps a sanitised copy of only the most recent records in memory;
// dev and demo keep none. The copy holds no token (bearer, JWT, padded JWT, Plaid access,
// public and link tokens, the server's refresh tokens), email (an IDN one included) or
// database key (hex or base64), whether the record carried it in its message or its
// error; an amount and a merchant are caught inside an exception's text and in a logged
// object, which the sink reduces to their types. An amount written into a message by hand
// is not caught here: that is the call-site rule's business (app-core.md, Logging). The
// stack trace is kept.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

/// An exception whose text carries what the call-site rule forbids, as a library's might.
final class _LeakyException implements Exception {
  const _LeakyException(this.detail);

  final String detail;

  @override
  String toString() => '_LeakyException: $detail';
}

const String _jwt =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEifQ.c2lnbmF0dXJl';
const String _accessToken =
    'access-sandbox-de3ce8ef-33f8-452c-a685-8671031fc0f6';
const String _email = 'jordan.lee@example.com';
const String _hexKey =
    '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
const String _amount = r'$1,234.56';
const String _merchant = 'Blue Bottle Coffee';

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

  test('prod keeps no token, email, key, amount or merchant', () async {
    setUpLogging(Flavor.prod);
    final Logger log = Logger('test');
    final StackTrace stack = StackTrace.current;
    log
      ..info('request with Authorization: Bearer $_jwt')
      ..info('refreshed $_jwt')
      ..warning('item token $_accessToken rejected')
      ..info('signed in as $_email')
      ..severe('PRAGMA key = "x\'$_hexKey\'" failed')
      ..info('key material $_hexKey')
      ..severe(
        'the pull failed',
        const _LeakyException(
          '$_amount at $_merchant for $_email, $_accessToken',
        ),
        stack,
      )
      ..warning('sync rejected', StateError('token $_jwt key $_hexKey'))
      ..info(() => const _LeakyException('$_amount at $_merchant'));
    await Future<void>.delayed(Duration.zero);

    final List<LogRecord> kept = recentLogRecords();
    expect(kept, hasLength(9));
    final String everything = [
      for (final LogRecord r in kept) ...[
        r.message,
        '${r.error}',
        '${r.object}',
      ],
    ].join('\n');
    for (final String secret in [
      _jwt,
      'eyJ',
      _accessToken,
      'access-sandbox-',
      _email,
      _hexKey,
      _hexKey.substring(0, 16),
      _amount,
      '1,234.56',
      _merchant,
    ]) {
      expect(everything, isNot(contains(secret)), reason: secret);
    }
    // What a crash log needs survives: the levels, the loggers, the plain words, the
    // error's type and the stack trace.
    expect(kept[2].message, 'item token [redacted] rejected');
    expect(kept[6].message, 'the pull failed');
    expect(kept[6].level, Level.SEVERE);
    expect(kept[6].loggerName, 'test');
    expect('${kept[6].error}', '_LeakyException');
    expect(kept[6].stackTrace, same(stack));
    expect('${kept[7].error}', 'StateError');
    expect(kept[8].message, '_LeakyException');
    expect(kept[8].object, isNull);
  });

  test('prod scrubs each token, email and key form from a message', () async {
    setUpLogging(Flavor.prod);
    final Map<String, String> secrets = {
      'refresh token': 'Zm9vYmFyYmF6cXV4MTIzNDU2Nzg5MGFiY2RlZmdoaWpr_-AB',
      'public token': 'public-sandbox-0b2f6a3c-1d2e-4f5a-8b9c-0d1e2f3a4b5c',
      'link token': 'link-sandbox-0b2f6a3c-1d2e-4f5a-8b9c-0d1e2f3a4b5c',
      'IDN email': 'jörg@exämple.de',
      'tagged email': 'a.b+tag@example.co.uk',
      'padded JWT': 'eyJhbGciOiJIUzI1NiJ9=.eyJzdWIiOiJ1c2VyLTEiLCJlbWFpbCI6ImFAYi5jIn0=.c2ln',
      'base64 key': 'n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=',
    };
    final Logger log = Logger('test');
    for (final String secret in secrets.values) {
      log.info('value $secret end');
    }
    await Future<void>.delayed(Duration.zero);

    final List<LogRecord> kept = recentLogRecords();
    expect(kept, hasLength(secrets.length));
    for (final (int i, String name) in secrets.keys.indexed) {
      expect(kept[i].message, 'value [redacted] end', reason: name);
    }
  });

  test('a record with nothing to scrub is kept as it was', () async {
    setUpLogging(Flavor.prod);
    const List<String> plain = [
      'pushed 3 changes, pulled 12 in 2 pages; cursor 4096',
      // A stack frame, an API path, a file path and a long snake_case entity type: long
      // runs, but not the mixed ones random tokens and keys are.
      'at package:finance_tracker/core/sync/sync_controller.dart:120:7',
      'GET /v1/transactions/recurring-streams/overrides',
      'opened /data/user/0/dev.tarnan.financetracker/files/receipts/manual_lunch.jpg',
      'held 2 records of recurring_stream_override_with_a_long_entity_name_v2',
    ];
    final Logger log = Logger('sync');
    for (final String message in plain) {
      log.info(message);
    }
    await Future<void>.delayed(Duration.zero);

    final List<LogRecord> kept = recentLogRecords();
    expect(kept.map((r) => r.message), plain);
    expect(kept.every((r) => r.error == null), isTrue);
  });

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
