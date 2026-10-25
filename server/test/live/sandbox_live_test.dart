// The optional live suite against Plaid Sandbox (docs/reference/testing-tools.md, **The
// live Sandbox suite**). Skipped unless PLAID_LIVE_TESTS=1 and PLAID_CLIENT_ID and
// PLAID_SECRET are in the environment; CI and the lanes never set them, and only the
// owner's seat runs it:
//
//   cd server && PLAID_LIVE_TESTS=1 PLAID_CLIENT_ID=... PLAID_SECRET=... \
//     dart test test/live
//
// The keys go into the client only and are never printed. One run creates one Item for
// user_transactions_dynamic at First Platypus Bank through the real server code (every
// response checked against the contract), syncs it, checks the data carries source
// plaid, exercises a repeated exchange, balances, an unknown webhook key and
// reset-login, and removes the Item; a failed step still removes it. About twenty Plaid
// calls, well inside Sandbox's limits.
import 'dart:io';

import 'package:finance_tracker_server/server.dart';
import 'package:test/test.dart';

import '../support/test_server.dart';

const _package = 'dev.tarnan.financetracker';

final _env = Platform.environment;
final _enabled =
    _env['PLAID_LIVE_TESTS'] == '1' &&
    (_env['PLAID_CLIENT_ID'] ?? '').isNotEmpty &&
    (_env['PLAID_SECRET'] ?? '').isNotEmpty;

void main() {
  group(
    'live Sandbox',
    () {
      late HttpPlaidClient plaid;
      late TestServer server;
      late Session ada;
      String? itemId;

      setUpAll(() {
        plaid = HttpPlaidClient(
          clientId: _env['PLAID_CLIENT_ID']!,
          secret: _env['PLAID_SECRET']!,
          baseUrl: Uri.parse(plaidBaseUrls['sandbox']!),
        );
      });

      setUp(() async {
        server = await TestServer.start(plaid: (_) => plaid);
        ada = await server.register();
        itemId = null;
      });

      test(
        'link, sync, data, re-exchange, balances, reset-login, unlink',
        () async {
          final link = await server.call(
            'post',
            '/plaid/link-token',
            token: ada.access,
            body: {'android_package_name': _package},
          );
          expect(link.status, 200, reason: '$link');
          final unregistered = await server.call(
            'post',
            '/plaid/link-token',
            token: ada.access,
            body: {'android_package_name': 'com.example.unregistered'},
          );
          expect(unregistered.status, 502);

          final publicToken = await plaid.sandboxPublicTokenCreate(
            institutionId: 'ins_109508',
            products: const ['transactions'],
            overrideUsername: 'user_transactions_dynamic',
            overridePassword: 'pass_good',
            daysRequested: 730,
          );
          final exchanged = await server.call(
            'post',
            '/plaid/exchange',
            token: ada.access,
            body: {'public_token': publicToken},
          );
          expect(exchanged.status, 201, reason: '$exchanged');
          itemId = exchanged.json['id']! as String;
          // Registered after the server's own teardown, so it runs first: a failed step
          // still removes the Item at Plaid.
          addTearDown(() async {
            if (itemId != null) {
              await server.call(
                'delete',
                '/plaid/items/$itemId',
                token: ada.access,
              );
            }
          });
          final institution =
              exchanged.json['institution']! as Map<String, Object?>;
          expect(institution['name'], 'First Platypus Bank');
          expect(institution['logo_url'], isNotNull);
          expect(institution['primary_color'], 0xFF0075A3);

          final again = await server.call(
            'post',
            '/plaid/exchange',
            token: ada.access,
            body: {'public_token': publicToken},
          );
          expect(again.status, 201, reason: '$again');
          expect(again.json['id'], itemId);

          Map<String, Object?>? run;
          for (var i = 0; i < 24; i++) {
            final r = await server.call(
              'post',
              '/plaid/items/$itemId/sync',
              token: ada.access,
            );
            expect(r.status, 202, reason: '$r');
            run = r.json;
            if (run['status'] == 'completed') break;
            await Future<void>.delayed(const Duration(seconds: 5));
          }
          expect(run!['status'], 'completed');

          final page = await server.call(
            'get',
            '/transactions?since=0',
            token: ada.access,
          );
          final rows = (page.json['transactions']! as List<Object?>)
              .cast<Map<String, Object?>>();
          expect(rows, isNotEmpty);
          expect(rows.map((t) => t['source']).toSet(), {'plaid'});
          for (final t in rows) {
            final amount = t['amount']! as Map<String, Object?>;
            expect(amount['minor_units'], isA<int>());
          }
          final accounts = await server.call(
            'get',
            '/accounts',
            token: ada.access,
          );
          expect(accounts.list, hasLength(7));

          final balances = await server.call(
            'post',
            '/plaid/items/$itemId/balances',
            token: ada.access,
          );
          expect(balances.status, 200, reason: '$balances');
          expect(balances.list, hasLength(7));

          await expectLater(
            plaid.webhookVerificationKeyGet('finance-tracker-unknown-kid'),
            throwsA(
              isA<PlaidException>().having(
                (e) => e.errorCode,
                'errorCode',
                'INVALID_WEBHOOK_VERIFICATION_KEY_ID',
              ),
            ),
          );

          final reset = await server.call(
            'post',
            '/sandbox/items/$itemId/reset-login',
            token: ada.access,
          );
          expect(reset.status, 204, reason: '$reset');
          final locked = await server.call(
            'post',
            '/plaid/items/$itemId/sync',
            token: ada.access,
          );
          expect(locked.status, 409);
          expect(locked.code, 'item_login_required');

          final unlinked = await server.call(
            'delete',
            '/plaid/items/$itemId',
            token: ada.access,
          );
          expect(unlinked.status, 204, reason: '$unlinked');
          itemId = null;
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );
    },
    skip: _enabled
        ? false
        : 'live Sandbox suite: set PLAID_LIVE_TESTS=1, PLAID_CLIENT_ID and '
              'PLAID_SECRET to run it (the owner only)',
  );
}
