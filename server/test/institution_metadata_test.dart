// Institution metadata through the real client over the recorded fixtures: the exchange
// fetches /institutions/get_by_id, stores the PNG logo and the ARGB colour on the Item,
// and the logo route serves the bytes; at most one fetch a day per institution, every
// visible Item there updated; a failed fetch never fails the exchange.
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'support/recorded_plaid_transport.dart';
import 'support/test_server.dart';

void main() {
  late RecordedPlaidTransport transport;
  late TestServer server;
  late Session ada;
  var exchanges = 0;

  setUp(() async {
    transport = RecordedPlaidTransport();
    server = await TestServer.start(plaid: (_) => transport.plaidClient());
    ada = await server.register();
    exchanges = 0;
    transport
      ..byDefault('/item/public_token/exchange', (Map<String, Object?> _) {
        exchanges++;
        return (
          status: 200,
          body: jsonEncode({
            'access_token': 'access_token-REDACTED',
            'item_id': 'item-$exchanges',
            'request_id': 'r$exchanges',
          }),
        );
      })
      ..byDefault('/item/get', 'item_get');
  });

  Future<Map<String, Object?>> link() async {
    final r = await server.call(
      'post',
      '/plaid/exchange',
      token: ada.access,
      body: {'public_token': 'public-recorded'},
    );
    expect(r.status, 201, reason: '$r');
    return r.json;
  }

  List<int> fixtureLogo() {
    final body = jsonDecode(
      fixtureAnswer('institutions_get_by_id').body,
    ) as Map<String, Object?>;
    final institution = body['institution']! as Map<String, Object?>;
    return base64.decode(institution['logo']! as String);
  }

  test(
    'the exchange stores the logo and colour, the route serves them',
    () async {
      transport.byDefault('/institutions/get_by_id', 'institutions_get_by_id');
      final item = await link();
      final institution = item['institution']! as Map<String, Object?>;
      expect(institution['primary_color'], 0xFF0075A3);
      expect(
        institution['logo_url'],
        'http://localhost/v1/institutions/ins_109508/logo',
      );
      final logo = await server.call(
        'get',
        '/institutions/ins_109508/logo',
        token: ada.access,
      );
      expect(logo.status, 200);
      expect(logo.headers['content-type'], 'image/png');
      expect(logo.body, fixtureLogo());
    },
  );

  test(
    'at most one fetch a day; every Item at the institution updated',
    () async {
      transport.byDefault('/institutions/get_by_id', 'institutions_get_by_id');
      await link();
      await link();
      expect(transport.bodies('/institutions/get_by_id'), hasLength(1));
      await server.app.items.refreshStaleInstitutions();
      expect(transport.bodies('/institutions/get_by_id'), hasLength(1));

      // A day later, the scheduled refresh fetches again and rewrites every Item there.
      await server.app.db.read(
        (tx) => tx.execute(
          'UPDATE items SET institution_logo = NULL, '
          'institution_primary_color = NULL',
        ),
      );
      server.clock.advance(const Duration(days: 1));
      await server.app.items.refreshStaleInstitutions();
      expect(transport.bodies('/institutions/get_by_id'), hasLength(2));
      final rows = await server.app.db.read(
        (tx) => tx.select(
          'SELECT institution_logo, institution_primary_color FROM items',
        ),
      );
      expect(rows, hasLength(2));
      for (final r in rows) {
        expect(r['institution_logo'], fixtureLogo());
        expect(r['institution_primary_color'], 0xFF0075A3);
      }
    },
  );

  test('a failed fetch is logged and the exchange still succeeds', () async {
    final events = <String>[];
    final subscription = Logger.root.onRecord.listen(
      (r) => events.add(formatRecord(r, LogFormat.json)),
    );
    addTearDown(subscription.cancel);
    transport.script('/institutions/get_by_id', [
      plaidErrorAnswer(429, 'RATE_LIMIT_EXCEEDED', 'INSTITUTIONS_GET_LIMIT'),
    ]);
    final item = await link();
    final institution = item['institution']! as Map<String, Object?>;
    expect(institution['logo_url'], isNull);
    expect(institution['primary_color'], isNull);
    expect(
      events.where((e) => e.contains('institution_metadata_skipped')).single,
      contains('INSTITUTIONS_GET_LIMIT'),
    );
    // Nothing was cached, so the next exchange tries again.
    transport.byDefault('/institutions/get_by_id', 'institutions_get_by_id');
    final second = await link();
    expect(
      (second['institution']! as Map<String, Object?>)['primary_color'],
      0xFF0075A3,
    );
  });
}
