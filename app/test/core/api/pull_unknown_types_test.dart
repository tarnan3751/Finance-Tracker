// A pulled change-log page read by the client itself: the entries of known types as
// ChangeLogEntry, an entry of a type this build does not know (a newer version's) kept
// apart with its raw type name instead of failing the page, the request authenticated
// like any secured operation, and a malformed page still a ServerError.
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/scripted_adapter.dart';

final Clock _clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

HttpFinanceApi _api(ScriptedAdapter adapter) => HttpFinanceApi(
  buildDio(
    AppConfig.prod(),
    adapter: adapter,
    baseUrl: Uri.parse('https://api.test'),
    version: () async => '1.0.0',
  ),
  tokens: InMemoryTokenStore(
    session: Session(
      accessToken: 'a1',
      refreshToken: 'r1',
      accessExpiresAt: DateTime.utc(2026, 10, 25),
      user: testUser,
      device: testDevice,
    ),
  ),
  clock: _clock,
);

Map<String, Object?> _entry(int seq, String type, String id, String op) => {
  'seq': seq,
  'entity_type': type,
  'entity_id': id,
  'operation': op,
  'payload': {'id': id, 'name': 'x'},
  'hlc': '001761300000000-0000$seq-device-2',
  'device_id': 'device-2',
};

void main() {
  test('an entry of an unknown type is kept apart with its raw type; the rest '
      'of the page reads as before', () async {
    final ScriptedAdapter adapter = ScriptedAdapter(
      (options, _) => ok({
        'entries': [
          _entry(1, 'category', 'c1', 'create'),
          _entry(2, 'future_type', 'f1', 'update'),
          _entry(3, 'goal', 'g1', 'create'),
        ],
        'next_since': 3,
        'has_more': false,
      }),
    );
    final PullPage page = await _api(adapter).pullChanges(since: 0, limit: 500);
    expect(page.entries.map((e) => (e.entityType, e.entityId, e.synced)), [
      (EntityType.category, 'c1', true),
      (EntityType.goal, 'g1', true),
    ]);
    final UnknownTypeEntry unknown = page.unknownTypes.single;
    expect(unknown.entityType, 'future_type');
    expect(unknown.entityId, 'f1');
    expect(unknown.operation, ChangeOperation.update);
    expect(unknown.payload, {'id': 'f1', 'name': 'x'});
    expect(unknown.hlc, Hlc.parse('001761300000000-00002-device-2'));
    expect(unknown.deviceId, 'device-2');
    expect(page.nextSince, 3);
    expect(page.hasMore, isFalse);

    final Recorded request = adapter.requests.single;
    expect((request.method, request.path), ('GET', '/sync/pull'));
    expect(request.headers['Authorization'], 'Bearer a1');
  });

  test('the query carries the cursor and the limit', () async {
    late Uri uri;
    final ScriptedAdapter adapter = ScriptedAdapter((options, _) {
      uri = options.uri;
      return ok({'entries': <Object?>[], 'next_since': 7, 'has_more': false});
    });
    await _api(adapter).pullChanges(since: 7, limit: 50);
    expect(uri.queryParameters, {'since': '7', 'limit': '50'});
  });

  test('a page this build cannot read is still a server error', () async {
    final ScriptedAdapter adapter = ScriptedAdapter(
      (options, _) => ok({
        'entries': [_entry(1, 'category', 'c1', 'rename')],
        'next_since': 1,
        'has_more': false,
      }),
    );
    await expectLater(
      _api(adapter).pullChanges(since: 0, limit: 500),
      throwsA(isA<ServerError>()),
    );
  });

  test('a cursor past the log is still sync_cursor_invalid', () async {
    final ScriptedAdapter adapter = ScriptedAdapter(
      (options, _) => problem(409, 'sync_cursor_invalid'),
    );
    await expectLater(
      _api(adapter).pullChanges(since: 99, limit: 500),
      throwsA(isA<SyncCursorInvalid>()),
    );
  });
}
