// The log: one structured line per request with the route template and ids, and never a
// password, an email, a token or an amount.
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  test('request lines carry the template and ids, never secrets', () async {
    final lines = <String>[];
    final subscription = configureLogging(LogFormat.json, _Sink(lines));
    addTearDown(subscription.cancel);
    final server = await TestServer.start();

    final session = await server.register(
      'secret.person@example.com',
      'hunter2 hunter2',
    );
    final refreshed = Session(
      (await server.call(
        'post',
        '/auth/refresh',
        body: {'refresh_token': session.refresh},
      )).json,
    );
    await server.call(
      'post',
      '/auth/refresh',
      body: {'refresh_token': session.refresh},
    );
    // The reuse above revoked that family; another device removes the first.
    final other = await server.login(
      'secret.person@example.com',
      'hunter2 hunter2',
    );
    await server.call(
      'delete',
      '/devices/${session.deviceId}',
      token: other.access,
    );

    final text = lines.join('\n');
    for (final secret in [
      'secret.person',
      'hunter2',
      session.access,
      session.refresh,
      refreshed.access,
      refreshed.refresh,
      other.access,
      other.refresh,
    ]) {
      expect(text, isNot(contains(secret)));
    }
    final requests = [
      for (final l in lines)
        if ((jsonDecode(l) as Map<String, Object?>)['event'] == 'request')
          jsonDecode(l) as Map<String, Object?>,
    ];
    expect(requests.first, containsPair('route', '/auth/register'));
    expect(requests.first, containsPair('status', 201));
    expect(requests.first['request_id'], isA<String>());
    expect(requests.last, containsPair('route', '/devices/{device_id}'));
    expect(requests.last, containsPair('status', 204));
    expect(requests.last, containsPair('user_id', session.userId));
    expect(requests.last, containsPair('device_id', other.deviceId));
    expect(lines.where((l) => l.contains('refresh_token_reuse')), hasLength(1));
  });

  test('an unexpected error is a 500 with the request id, and the stack in the log', () async {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    addTearDown(subscription.cancel);
    final server = await TestServer.start();
    final session = await server.register();
    await server.app.db.read((tx) => tx.execute('DROP TABLE refresh_tokens'));
    final r = await server.call('get', '/me', token: session.access);
    expect(r.status, 500);
    expect(r.code, 'internal');
    expect(r.json['instance'], r.headers['x-request-id']);
    expect(r.json, isNot(contains('detail')));
    final severe = records.singleWhere((l) => l.level == Level.SEVERE);
    expect(severe.stackTrace, isNotNull);
    final line = jsonDecode(
      formatRecord(severe, LogFormat.json),
    ) as Map<String, Object?>;
    expect(line['event'], 'unhandled_error');
    expect(line['error_type'], 'SqliteException');
    expect(line['sqlite_result_code'], 1);
    expect(line['sqlite_message'], contains('refresh_tokens'));
    final text = jsonEncode(line..remove('stack'));
    // Never the statement, its parameters or the operation.
    for (final leak in [
      'SELECT',
      'EXISTS',
      session.deviceId,
      session.userId,
      'preparing',
    ]) {
      expect(text, isNot(contains(leak)));
    }
    expect(line.keys, isNot(contains('error')));
  });

  test('the text format is one readable line', () {
    final line = formatRecord(
      LogRecord(
        Level.INFO,
        'request',
        'http',
        null,
        null,
        null,
        const LogEvent('request', {'status': 200}),
      ),
      LogFormat.text,
    );
    expect(line, endsWith('INFO http request status=200'));
  });
}

final class _Sink implements StringSink {
  _Sink(this.lines);

  final List<String> lines;

  @override
  void writeln([Object? object = '']) => lines.add('$object');

  @override
  void write(Object? object) => lines.add('$object');

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      lines.add(objects.join(separator));

  @override
  void writeCharCode(int charCode) => lines.add(String.fromCharCode(charCode));
}
