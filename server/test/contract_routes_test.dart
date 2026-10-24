// The server against the contract as a whole: one route per operation and none outside
// it, each mounted with the security the document declares; the error and rejection codes
// equal the document's enums; and the hand-written request validation rejects what the
// contract rejects and accepts the contract's examples. Every response in every test is
// validated against the contract by TestServer.call.
import 'package:contract_test/contract_test.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/sync/change_log_relay.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/shelf_sync_relay.dart';
import 'support/test_server.dart';

List<Object?> _enum(String schema) =>
    contract.schema(schema)['enum']! as List<Object?>;

void main() {
  test('every operation has exactly one route, and no route is outside the contract', () async {
    final server = await TestServer.start();
    final routes = {
      for (final r in server.app.routes) '${r.method} ${r.path}': r,
    };
    expect(
      routes,
      hasLength(server.app.routes.length),
      reason: 'duplicate route',
    );
    final operations = {
      for (final op in contract.operations) '${op.method} ${op.path}': op,
    };
    expect(routes.keys.toSet(), operations.keys.toSet());
    for (final MapEntry(:key, value: op) in operations.entries) {
      final route = routes[key]!;
      expect(route.operationId, op.operation['operationId'], reason: key);
      final security = op.operation['security'];
      final public = security is List && security.isEmpty;
      expect(route.authenticated, !public, reason: key);
    }
  });

  test('every route is mounted and enforces its security', () async {
    final server = await TestServer.start();
    for (final op in contract.operations) {
      final path = op.path.replaceAll(RegExp(r'\{[a-z_]+\}'), 'x');
      final r = await server.call(op.method, path);
      final security = op.operation['security'];
      if (security is List && security.isEmpty) {
        expect(r.status, isNot(404), reason: '${op.method} ${op.path}');
      } else {
        expect(r.status, 401, reason: '${op.method} ${op.path}');
        expect(r.code, 'invalid_credentials');
      }
    }
  });

  test('an unknown path or method is a 404 problem', () async {
    final server = await TestServer.start();
    for (final (method, path) in [
      ('get', '/nope'),
      ('put', '/me'),
      ('get', '/auth/login'),
    ]) {
      final r = await server.call(method, path);
      expect(r.status, 404);
      expect(r.code, 'not_found');
      expect(r.headers['content-type'], 'application/problem+json');
    }
  });

  test('ProblemCode equals the contract', () {
    expect([for (final c in ProblemCode.values) c.wire], _enum('ProblemCode'));
  });

  test("RejectionCode equals the contract and the engine's reasons", () {
    expect([
      for (final c in RejectionCode.values) c.wire,
    ], _enum('PushRejectionCode'));
    expect(rejectionReasons.keys, _enum('PushRejectionCode'));
    expect(rejectionReasons.values, PushRejectionReason.values);
  });

  group('request validation agrees with the contract', () {
    const hlc = '001761300000000-00000-d1';
    final entry = {
      'entity_type': 'category',
      'entity_id': 'c1',
      'operation': 'create',
      'payload': {'name': 'Food'},
      'hlc': hlc,
      'device_id': 'd1',
    };
    final invalid = <(String, String, Map<String, Object?>)>[
      (
        'post',
        '/auth/register',
        {'password': 'long enough', 'device_name': 'P'},
      ),
      (
        'post',
        '/auth/register',
        {'email': 'nope', 'password': 'long enough', 'device_name': 'P'},
      ),
      (
        'post',
        '/auth/register',
        {'email': 'a@b.test', 'password': 'short', 'device_name': 'P'},
      ),
      (
        'post',
        '/auth/register',
        {'email': 'a@b.test', 'password': 'x' * 129, 'device_name': 'P'},
      ),
      (
        'post',
        '/auth/register',
        {'email': 'a@b.test', 'password': 'long enough', 'device_name': ''},
      ),
      (
        'post',
        '/auth/register',
        {
          'email': 'a@b.test',
          'password': 'long enough',
          'device_name': 'x' * 101,
        },
      ),
      (
        'post',
        '/auth/register',
        {
          'email': 'a@b.test',
          'password': 'long enough',
          'device_name': 'P',
          'display_name': '',
        },
      ),
      (
        'post',
        '/auth/register',
        {
          'email': 'a@b.test',
          'password': 'long enough',
          'device_name': 'P',
          'display_name': null,
        },
      ),
      (
        'post',
        '/auth/register',
        {
          'email': 'a@b.test',
          'password': 'long enough',
          'device_name': 'P',
          'admin': true,
        },
      ),
      (
        'post',
        '/auth/register',
        {'email': 7, 'password': 'long enough', 'device_name': 'P'},
      ),
      ('post', '/auth/login', {'email': 'a@b.test', 'device_name': 'P'}),
      (
        'post',
        '/auth/login',
        {
          'email': 'a@b.test',
          'password': 'long enough',
          'device_name': 'P',
          'display_name': 'A',
        },
      ),
      ('post', '/auth/refresh', {}),
      ('post', '/auth/refresh', {'refresh_token': ''}),
      ('post', '/auth/refresh', {'refresh_token': 'r', 'device_id': 'd'}),
      ('post', '/auth/logout', {'refresh_token': ''}),
      ('post', '/plaid/link-token', {}),
      ('post', '/plaid/link-token', {'android_package_name': 'nodots'}),
      (
        'post',
        '/plaid/link-token',
        {'android_package_name': 'a.b', 'update_item_id': ''},
      ),
      (
        'post',
        '/plaid/link-token',
        {'android_package_name': 'a.b', 'update_item_id': null},
      ),
      (
        'post',
        '/plaid/link-token',
        {'android_package_name': 'a.b', 'redirect_uri': 'x'},
      ),
      (
        'post',
        '/plaid/items/{item_id}/update-link-token',
        {'android_package_name': '1a.b'},
      ),
      ('post', '/plaid/exchange', {'public_token': ''}),
      ('post', '/plaid/exchange', {'public_token': 'p', 'x': 1}),
      ('post', '/sync/push', {}),
      ('post', '/sync/push', {'entries': {}}),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry}..remove('hlc'),
          ],
        },
      ),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry, 'hlc': '1-2-x'},
          ],
        },
      ),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry, 'entity_type': 'item'},
          ],
        },
      ),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry, 'operation': 'upsert'},
          ],
        },
      ),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry, 'payload': 'x'},
          ],
        },
      ),
      (
        'post',
        '/sync/push',
        {
          'entries': [
            {...entry, 'synced': true},
          ],
        },
      ),
      ('post', '/sync/push', {'entries': [], 'device_id': 'd'}),
      (
        'post',
        '/sync/push',
        {
          'entries': ['x'],
        },
      ),
    ];

    test(
      'every body the contract rejects is a 400 ValidationProblem',
      () async {
        final server = await TestServer.start();
        final session = await server.register();
        for (final (i, (method, template, body)) in invalid.indexed) {
          final errors = contract.validator.validate(
            contract.requestSchema(template, method),
            body,
            mode: ValidationMode.request,
          );
          expect(
            errors,
            isNotEmpty,
            reason: 'the contract accepts $template $body',
          );
          final r = await server.call(
            method,
            template.replaceAll('{item_id}', 'x'),
            body: body,
            token: session.access,
            // One address per row, so the rate limiter never answers first.
            headers: {'x-test-ip': '10.1.0.$i'},
            validRequest: false,
          );
          expect(r.status, 400, reason: '$template $body answered $r');
          expect(r.code, 'validation_failed');
        }
      },
    );

    test("the contract's request examples are accepted", () async {
      final server = await TestServer.start();
      for (final (method, path, schema) in [
        ('post', '/auth/register', 'RegisterRequest'),
        ('post', '/auth/login', 'LoginRequest'),
      ]) {
        final example = contract.schema(schema)['example'];
        final r = await server.call(method, path, body: example);
        expect(r.status, isNot(400), reason: '$schema answered $r');
      }
    });
  });
}
