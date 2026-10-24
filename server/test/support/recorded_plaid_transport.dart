// Replays the coordinator's sanitized Sandbox captures (test/fixtures/plaid/*.json, each
// {status, body}, tokens redacted as *-REDACTED) as Plaid's HTTP answers, so the real
// HttpPlaidClient runs end to end with no network. Each Plaid path answers from a queue of
// scripted responses (a fixture name, or a synthesized body for a case Sandbox did not
// show), then from its default; a path with neither fails the test. Every request is
// recorded with its decoded body for assertions, and checked for the version header and
// the test keys.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker_server/server.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The client id and secret the recorded client is built with; not Plaid's.
const testPlaidClientId = 'test-client-id';
const testPlaidSecret = 'test-plaid-secret';

/// A fixture's raw text, `{status, body}`.
String plaidFixture(String name) =>
    File(p.join('test', 'fixtures', 'plaid', '$name.json')).readAsStringSync();

/// One answer: a status and the body's exact text.
typedef RecordedAnswer = ({int status, String body});

/// A fixture as an answer, its body text cut out of the file unchanged (numbers as
/// written).
RecordedAnswer fixtureAnswer(String name) {
  final text = plaidFixture(name);
  final status = (jsonDecode(text) as Map<String, Object?>)['status']! as int;
  final start = text.indexOf('"body"');
  final open = text.indexOf('{', start);
  final close = text.lastIndexOf('"status"');
  final end = text.lastIndexOf('}', close);
  return (status: status, body: text.substring(open, end + 1));
}

/// A synthesized Plaid error answer of Plaid's documented shape.
RecordedAnswer plaidErrorAnswer(int status, String type, String code) => (
  status: status,
  body: jsonEncode({
    'error_type': type,
    'error_code': code,
    'error_message': 'synthesized for a test',
    'request_id': 'req-synthesized',
  }),
);

/// A recorded request.
typedef RecordedRequest = ({
  String path,
  Map<String, String> headers,
  String raw,
  Map<String, Object?> body,
});

/// The transport.
final class RecordedPlaidTransport {
  final Map<String, Queue<Object>> _scripts = {};
  final Map<String, Object> _defaults = {};

  /// Every request, in order.
  final List<RecordedRequest> requests = [];

  /// Answers the next calls of [path] with [answers] in order: fixture names (`String`),
  /// [RecordedAnswer]s, or functions of the request body returning one.
  void script(String path, List<Object> answers) =>
      _scripts.putIfAbsent(path, Queue.new).addAll(answers);

  /// Answers [path] with [answer] once its script is used up.
  void byDefault(String path, Object answer) => _defaults[path] = answer;

  /// The bodies sent to [path].
  List<Map<String, Object?>> bodies(String path) => [
    for (final r in requests)
      if (r.path == path) r.body,
  ];

  /// The `http.Client` the client under test uses.
  late final http.Client client = MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, Object?>;
    requests.add((
      path: request.url.path,
      headers: request.headers,
      raw: request.body,
      body: body,
    ));
    expect(request.method, 'POST');
    expect(request.headers['plaid-version'], plaidApiVersion);
    expect(request.headers['content-type'], startsWith('application/json'));
    expect(body['client_id'], testPlaidClientId);
    expect(body['secret'], testPlaidSecret);
    final queue = _scripts[request.url.path];
    final next = queue != null && queue.isNotEmpty
        ? queue.removeFirst()
        : _defaults[request.url.path];
    if (next == null) fail('No recorded answer for ${request.url.path}');
    final answer = switch (next) {
      final String name => fixtureAnswer(name),
      final RecordedAnswer a => a,
      final RecordedAnswer Function(Map<String, Object?>) f => f(body),
      _ => throw ArgumentError.value(next),
    };
    return http.Response.bytes(
      utf8.encode(answer.body),
      answer.status,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  });

  /// An [HttpPlaidClient] over this transport.
  HttpPlaidClient plaidClient({String? webhookUrl}) => HttpPlaidClient(
    clientId: testPlaidClientId,
    secret: testPlaidSecret,
    baseUrl: Uri.parse(plaidBaseUrls['sandbox']!),
    webhookUrl: webhookUrl,
    httpClient: client,
  );
}
