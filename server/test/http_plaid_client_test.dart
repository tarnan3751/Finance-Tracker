// The real Plaid client over the recorded Sandbox fixtures: every call's request (path,
// version header, keys, options) and its mapping from the fixture, the error mapping, the
// Money decoding of the 316-row page with no double anywhere, and end to end through the
// server: a link and sync with every row of all seven Plaid tables carrying source plaid,
// and a full flow whose log carries no key, secret or token.
import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker_server/server.dart';
import 'package:finance_tracker_server/src/plaid/plaid_json.dart';
import 'package:finance_tracker_server/src/plaid/plaid_money.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support/recorded_plaid_transport.dart';
import 'support/test_server.dart';

const _package = 'dev.tarnan.financetracker';

/// Every number in [node], to prove none decoded as a double.
Iterable<Object?> _leaves(Object? node) sync* {
  switch (node) {
    case final Map<String, Object?> m:
      for (final v in m.values) {
        yield* _leaves(v);
      }
    case final List<Object?> l:
      for (final v in l) {
        yield* _leaves(v);
      }
    default:
      yield node;
  }
}

/// [text] (a plain decimal) in cents, rounded half-even, computed apart from the code
/// under test with BigInt division.
int _centsHalfEven(String text) {
  final negative = text.startsWith('-');
  final unsigned = negative ? text.substring(1) : text;
  final dot = unsigned.indexOf('.');
  final fraction = dot < 0 ? '' : unsigned.substring(dot + 1);
  final digits = BigInt.parse(unsigned.replaceFirst('.', ''));
  final scaled = digits * BigInt.from(100);
  final divisor = BigInt.from(10).pow(fraction.length);
  var quotient = scaled ~/ divisor;
  final twice = (scaled % divisor) * BigInt.two;
  if (twice > divisor || (twice == divisor && quotient.isOdd)) {
    quotient += BigInt.one;
  }
  return (negative ? -quotient : quotient).toInt();
}

void main() {
  late RecordedPlaidTransport transport;
  late HttpPlaidClient plaid;

  setUp(() {
    transport = RecordedPlaidTransport();
    plaid = transport.plaidClient();
  });

  Matcher plaidError(String type, String code, [String? requestId]) =>
      isA<PlaidException>()
          .having((e) => e.errorType, 'errorType', type)
          .having((e) => e.errorCode, 'errorCode', code)
          .having((e) => e.requestId, 'requestId', requestId ?? anything);

  group('requests and their mapping', () {
    test(
      'a link token asks for transactions, 730 days and the package',
      () async {
        transport.script('/link/token/create', ['link_token_create']);
        final token = await plaid.createLinkToken(
          const LinkTokenRequest(
            clientUserId: 'user-1',
            androidPackageName: _package,
          ),
        );
        expect(token.linkToken, 'link_token-REDACTED');
        expect(token.expiration, DateTime.utc(2026, 10, 25, 1, 51, 5));
        final body = transport.bodies('/link/token/create').single;
        expect(body, containsPair('products', ['transactions']));
        expect(body, containsPair('transactions', {'days_requested': 730}));
        expect(body, containsPair('android_package_name', _package));
        expect(body, containsPair('user', {'client_user_id': 'user-1'}));
        expect(body, containsPair('country_codes', ['US']));
        expect(body, containsPair('client_name', 'Finance Tracker'));
        expect(body.containsKey('webhook'), isFalse);
        expect(body.containsKey('access_token'), isFalse);
      },
    );

    test('a configured webhook URL reaches Link and Sandbox tokens', () async {
      final hooked = transport.plaidClient(
        webhookUrl: 'https://tunnel.example/v1/webhooks/plaid',
      );
      transport
        ..script('/link/token/create', ['link_token_create'])
        ..script('/sandbox/public_token/create', [
          'sandbox_public_token_create',
        ]);
      await hooked.createLinkToken(
        const LinkTokenRequest(
          clientUserId: 'user-1',
          androidPackageName: _package,
        ),
      );
      await hooked.sandboxPublicTokenCreate(
        institutionId: 'ins_109508',
        products: const ['transactions'],
      );
      expect(
        transport.bodies('/link/token/create').single['webhook'],
        'https://tunnel.example/v1/webhooks/plaid',
      );
      expect(
        transport.bodies('/sandbox/public_token/create').single['options'],
        {'webhook': 'https://tunnel.example/v1/webhooks/plaid'},
      );
    });

    test('an update-mode token names the Item and no products', () async {
      transport.script('/link/token/create', ['link_token_create_update_mode']);
      final token = await plaid.createUpdateLinkToken(
        'access-x',
        clientUserId: 'user-1',
        androidPackageName: _package,
      );
      expect(token.expiration, DateTime.utc(2026, 10, 24, 22, 21, 31));
      final body = transport.bodies('/link/token/create').single;
      expect(body, containsPair('access_token', 'access-x'));
      expect(
        body,
        containsPair('update', {'account_selection_enabled': false}),
      );
      expect(body.containsKey('products'), isFalse);
      expect(body.containsKey('transactions'), isFalse);
    });

    test('an unregistered package is Plaid INVALID_FIELD', () async {
      transport.script('/link/token/create', [
        'link_token_create_invalid_package',
      ]);
      await expectLater(
        plaid.createLinkToken(
          const LinkTokenRequest(
            clientUserId: 'user-1',
            androidPackageName: 'com.example.other',
          ),
        ),
        throwsA(
          plaidError('INVALID_REQUEST', 'INVALID_FIELD', '56bc954a760c6d8'),
        ),
      );
    });

    test('exchange, item, remove', () async {
      transport
        ..script('/item/public_token/exchange', ['item_public_token_exchange'])
        ..script('/item/get', [
          'item_get',
          'item_get_login_required',
          'item_get_removed',
        ])
        ..script('/item/remove', ['item_remove']);
      final exchanged = await plaid.exchangePublicToken('public-x');
      expect(exchanged.accessToken, 'access_token-REDACTED');
      expect(exchanged.itemId, 'GA3WJ917yPhb4BvvaZBaiNxDLnljrqiWqxpvK');
      expect(
        transport.bodies('/item/public_token/exchange').single['public_token'],
        'public-x',
      );
      final item = await plaid.getItem('access-x');
      expect(item.institutionId, 'ins_109508');
      expect(item.institutionName, 'First Platypus Bank');
      expect(item.products, ['transactions']);
      expect(item.errorCode, isNull);
      expect(
        (await plaid.getItem('access-x')).errorCode,
        'ITEM_LOGIN_REQUIRED',
      );
      await expectLater(
        plaid.getItem('access-x'),
        throwsA(plaidError('ITEM_ERROR', 'ITEM_NOT_FOUND', '52611be93e757c6')),
      );
      await plaid.removeItem('access-x');
      expect(
        transport.bodies('/item/remove').single['access_token'],
        'access-x',
      );
    });

    test('transactions sync: not ready, a page, up to date, errors', () async {
      transport.script('/transactions/sync', [
        'transactions_sync_not_ready',
        'transactions_sync_page1',
        'transactions_sync_up_to_date',
        'transactions_sync_invalid_cursor',
        'transactions_sync_item_login_required',
      ]);
      final notReady = await plaid.transactionsSync('access-x', '');
      expect(notReady.notReady, isTrue);
      expect(notReady.added, isEmpty);
      final page = await plaid.transactionsSync('access-x', '');
      expect(page.notReady, isFalse);
      expect(page.added, hasLength(316));
      expect(page.added.where((t) => t.pending), hasLength(12));
      expect(page.accounts, hasLength(7));
      expect(page.hasMore, isFalse);
      final end = await plaid.transactionsSync('access-x', page.nextCursor);
      expect(end.nextCursor, page.nextCursor);
      expect(end.added, isEmpty);
      await expectLater(
        plaid.transactionsSync('access-x', 'garbage'),
        throwsA(plaidError('INVALID_REQUEST', 'INVALID_FIELD')),
      );
      await expectLater(
        plaid.transactionsSync('access-x', page.nextCursor),
        throwsA(
          isA<PlaidException>().having(
            (e) => e.isLoginRequired,
            'isLoginRequired',
            isTrue,
          ),
        ),
      );
      final bodies = transport.bodies('/transactions/sync');
      expect(bodies.first.containsKey('cursor'), isFalse);
      expect(bodies[2]['cursor'], page.nextCursor);
      for (final b in bodies) {
        expect(b['count'], 500);
        expect(b['options'], {'personal_finance_category_version': 'v2'});
      }
    });

    test('the page maps names, merchants, logos and categories', () async {
      transport.script('/transactions/sync', ['transactions_sync_page1']);
      final page = await plaid.transactionsSync('access-x', 'c');
      final interest = page.added.firstWhere(
        (t) => t.transactionId == 'vy5xvdK1MVsnMBxxANBAS6JvLaN3VWtq3NZz1',
      );
      expect(interest.name, 'Interest payment');
      expect(interest.merchantName, isNull);
      expect(interest.amount, Money(-12, 'USD'));
      expect(interest.primaryCategory, 'INCOME');
      expect(interest.detailedCategory, 'INCOME_INTEREST_EARNED');
      expect(interest.date, LocalDate(2026, 9, 24));
      expect(interest.authorizedDate, LocalDate(2026, 9, 24));
      expect(page.added.where((t) => t.merchantName != null), hasLength(103));
      expect(page.added.where((t) => t.logoUrl != null), hasLength(77));
    });

    test('a missing logo falls back to the merchant counterparty', () {
      Map<String, Object?> json(Object? logo) => {
        'transaction_id': 't1',
        'account_id': 'a1',
        'amount': '4.5',
        'iso_currency_code': 'USD',
        'date': '2026-10-01',
        'pending': false,
        'name': 'STARBUCKS',
        'logo_url': logo,
        'counterparties': [
          {'type': 'payment_app', 'logo_url': 'https://x/app.png'},
          {'type': 'merchant', 'logo_url': null},
          {'type': 'merchant', 'logo_url': 'https://x/merchant.png'},
        ],
      };
      expect(
        PlaidTransaction.fromPlaidJson(json(null)).logoUrl,
        'https://x/merchant.png',
      );
      expect(
        PlaidTransaction.fromPlaidJson(json('https://x/own.png')).logoUrl,
        'https://x/own.png',
      );
    });

    test('balances, liabilities, recurring streams', () async {
      transport
        ..script('/accounts/balance/get', ['accounts_balance_get'])
        ..script('/liabilities/get', ['liabilities_get'])
        ..script('/transactions/recurring/get', [
          'transactions_recurring_get',
          'transactions_recurring_get',
        ]);
      final accounts = await plaid.accountsBalanceGet('access-x');
      expect(accounts, hasLength(7));
      final checking = accounts.firstWhere((a) => a.subtype == 'checking');
      expect(checking.current, Money(50000, 'USD'));
      expect(checking.available, Money(34210, 'USD'));
      final card = accounts.firstWhere((a) => a.type == 'credit');
      expect(card.limit, Money(480000, 'USD'));
      expect(card.available, Money(428301, 'USD'));
      expect(
        transport.bodies('/accounts/balance/get').single.keys,
        unorderedEquals(['client_id', 'secret', 'access_token']),
      );

      final liabilities = await plaid.liabilitiesGet('access-x');
      expect(liabilities.mortgage, isEmpty);
      expect(liabilities.credit.single['aprs'], [
        containsPair('apr_percentage', '12.5'),
        containsPair('apr_percentage', '27.95'),
      ]);
      final student = liabilities.student.single;
      expect(student['interest_rate_percentage'], '5.25');
      expect(student['last_payment_amount'], Money(31195, 'USD').toJson());
      expect(
        student['origination_principal_amount'],
        Money(2500000, 'USD').toJson(),
      );

      // Sandbox's average_amount carries no currency: the account's is used, and a
      // stream of an account the server does not know is left out.
      final recurring = await plaid.transactionsRecurringGet(
        'access-x',
        currencyOf: (id) =>
            accounts.any((a) => a.accountId == id) ? 'USD' : null,
      );
      expect(recurring.inflow, hasLength(2));
      expect(recurring.outflow, hasLength(3));
      final payroll = recurring.inflow.firstWhere(
        (s) => s.frequency == 'WEEKLY',
      );
      expect(payroll.merchantName, 'Sweetgreen');
      expect(payroll.averageAmount, Money(-81000, 'USD'));
      final interest = recurring.inflow.firstWhere(
        (s) => s.frequency == 'MONTHLY',
      );
      expect(interest.merchantName, isNotEmpty);
      final netflix = recurring.outflow.firstWhere(
        (s) => s.merchantName == 'Netflix',
      );
      expect(netflix.averageAmount, Money(1957, 'USD'));
      expect(netflix.predictedNextDate, isNotNull);
      final spotify = recurring.outflow.firstWhere(
        (s) => s.merchantName == 'Spotify',
      );
      expect(spotify.averageAmount, Money(1265, 'USD'));
      final unknown = await plaid.transactionsRecurringGet(
        'access-x',
        currencyOf: (_) => null,
      );
      expect([...unknown.inflow, ...unknown.outflow], isEmpty);
    });

    test('an Item with no investment accounts is Plaid ITEM_ERROR', () async {
      transport
        ..script('/investments/holdings/get', ['investments_holdings_get'])
        ..script('/investments/transactions/get', [
          'investments_transactions_get',
        ]);
      await expectLater(
        plaid.investmentsHoldingsGet('access-x'),
        throwsA(plaidError('ITEM_ERROR', 'NO_INVESTMENT_ACCOUNTS')),
      );
      await expectLater(
        plaid.investmentsTransactionsGet(
          'access-x',
          start: LocalDate(2024, 10, 24),
          end: LocalDate(2026, 10, 24),
        ),
        throwsA(plaidError('ITEM_ERROR', 'NO_INVESTMENT_ACCOUNTS')),
      );
    });

    test('investment transactions page by offset to the total', () async {
      // Synthesized: Sandbox's user_good has 586 investment transactions, more than a
      // page; the fixtures' Item has no investment account.
      const total = 586;
      transport.byDefault('/investments/transactions/get', (
        Map<String, Object?> body,
      ) {
        final options = body['options']! as Map<String, Object?>;
        final offset = options['offset']! as int;
        final count = options['count']! as int;
        final n = (total - offset).clamp(0, count);
        final rows = [
          for (var i = offset; i < offset + n; i++)
            '{"investment_transaction_id":"it$i","account_id":"inv",'
                '"security_id":"s${i % 3}","date":"2026-01-02","name":"BUY",'
                '"type":"buy","subtype":"buy","quantity":1.5,"price":10.333,'
                '"amount":15.4995,"fees":0,"iso_currency_code":"USD"}',
        ];
        final securities = [
          for (var s = 0; s < 3; s++)
            '{"security_id":"s$s","name":"Fund $s","ticker_symbol":"F$s",'
                '"type":"etf","is_cash_equivalent":false,"close_price":1e2,'
                '"close_price_as_of":null,"iso_currency_code":"USD"}',
        ];
        return (
          status: 200,
          body:
              '{"investment_transactions":[${rows.join(',')}],'
              '"securities":[${securities.join(',')}],'
              '"total_investment_transactions":$total,"request_id":"r"}',
        );
      });
      final result = await plaid.investmentsTransactionsGet(
        'access-x',
        start: LocalDate(2024, 10, 24),
        end: LocalDate(2026, 10, 24),
      );
      expect(result.transactions, hasLength(total));
      expect(result.securities, hasLength(3));
      expect(result.securities.first.closePrice, '100');
      final first = result.transactions.first;
      expect(first.quantity, '1.5');
      expect(first.price, '10.333');
      expect(first.amount, Money(1550, 'USD'));
      expect(first.fees, Money(0, 'USD'));
      final bodies = transport.bodies('/investments/transactions/get');
      expect(
        [for (final b in bodies) (b['options']! as Map)['offset']],
        [0, 500],
      );
      expect(bodies.first['start_date'], '2024-10-24');
      expect(bodies.first['end_date'], '2026-10-24');
    });

    test('the institution with its logo and colour', () async {
      transport.script('/institutions/get_by_id', ['institutions_get_by_id']);
      final institution = await plaid.institutionsGetById('ins_109508');
      expect(institution.name, 'First Platypus Bank');
      expect(institution.primaryColor, 0xFF0075A3);
      expect(institution.logo, isNotNull);
      expect(institution.logo!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      final body = transport.bodies('/institutions/get_by_id').single;
      expect(body['institution_id'], 'ins_109508');
      expect(body['country_codes'], ['US']);
      expect(body['options'], {'include_optional_metadata': true});
    });

    test('a logo that is not a PNG and a bad colour count as none', () {
      final institution = PlaidInstitution.fromPlaidJson({
        'institution_id': 'ins_1',
        'name': 'Bank',
        'logo': base64.encode(utf8.encode('GIF89a not a png')),
        'primary_color': 'blue',
      });
      expect(institution.logo, isNull);
      expect(institution.primaryColor, isNull);
      expect(
        PlaidInstitution.fromPlaidJson({
          'institution_id': 'ins_1',
          'name': 'Bank',
          'logo': '%%%',
        }).logo,
        isNull,
      );
    });

    test('webhook verification keys', () async {
      transport.script('/webhook_verification_key/get', [
        (
          status: 200,
          body:
              '{"key":{"alg":"ES256","crv":"P-256","kid":"k1","kty":"EC",'
              '"use":"sig","x":"x","y":"y","created_at":1,"expired_at":null},'
              '"request_id":"r"}',
        ),
        'webhook_verification_key_get_unknown',
      ]);
      final key = await plaid.webhookVerificationKeyGet('k1');
      expect(key, containsPair('kid', 'k1'));
      expect(key, containsPair('expired_at', null));
      await expectLater(
        plaid.webhookVerificationKeyGet('nope'),
        throwsA(
          plaidError('INVALID_INPUT', 'INVALID_WEBHOOK_VERIFICATION_KEY_ID'),
        ),
      );
      expect(
        transport.bodies('/webhook_verification_key/get').last['key_id'],
        'nope',
      );
    });

    test('the Sandbox controls', () async {
      transport
        ..script('/sandbox/public_token/create', [
          'sandbox_public_token_create',
          'sandbox_public_token_create',
        ])
        ..script('/sandbox/item/reset_login', ['sandbox_item_reset_login'])
        ..script('/sandbox/transactions/create', [
          'sandbox_transactions_create',
        ])
        ..byDefault('/sandbox/item/fire_webhook', 'item_remove')
        ..script('/transactions/refresh', ['transactions_refresh']);
      expect(
        await plaid.sandboxPublicTokenCreate(
          institutionId: 'ins_109508',
          products: const ['transactions'],
          overrideUsername: 'user_transactions_dynamic',
          overridePassword: 'pass_good',
          daysRequested: 730,
        ),
        'public_token-REDACTED',
      );
      await plaid.sandboxPublicTokenCreate(
        institutionId: 'ins_109508',
        products: const ['transactions'],
      );
      final tokenBodies = transport.bodies('/sandbox/public_token/create');
      expect(tokenBodies.first['initial_products'], ['transactions']);
      expect(tokenBodies.first['options'], {
        'override_username': 'user_transactions_dynamic',
        'override_password': 'pass_good',
        'transactions': {'days_requested': 730},
      });
      expect(tokenBodies.last.containsKey('options'), isFalse);

      await plaid.sandboxItemResetLogin('access-x');
      await plaid.sandboxTransactionsCreate('access-x', [
        (
          dateTransacted: LocalDate(2026, 10, 20),
          datePosted: LocalDate(2026, 10, 21),
          amount: Money(-1250, 'USD'),
          description: 'NETFLIX.COM',
          accountId: 'acc-1',
        ),
        (
          dateTransacted: LocalDate(2026, 10, 20),
          datePosted: LocalDate(2026, 10, 20),
          amount: Money(499, 'USD'),
          description: 'WHOLEFDS MKT',
          accountId: null,
        ),
      ]);
      final create = transport.requests.firstWhere(
        (r) => r.path == '/sandbox/transactions/create',
      );
      // Amounts go out as JSON numbers written from their decimal text.
      expect(create.raw, contains('"amount":-12.50'));
      expect(create.raw, contains('"amount":4.99'));
      final rows = (create.body['transactions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(rows.first['date_transacted'], '2026-10-20');
      expect(rows.first['date_posted'], '2026-10-21');
      expect(rows.first['iso_currency_code'], 'USD');
      expect(rows.first['account_id'], 'acc-1');
      expect(rows.last.containsKey('account_id'), isFalse);

      for (final code in fireWebhookTypes.keys) {
        await plaid.sandboxItemFireWebhook('access-x', code);
      }
      final fired = transport.bodies('/sandbox/item/fire_webhook');
      expect(fired.first['webhook_type'], 'TRANSACTIONS');
      expect(fired.first['webhook_code'], 'SYNC_UPDATES_AVAILABLE');
      expect(
        fired.firstWhere((b) => b['webhook_code'] == 'ERROR')['webhook_type'],
        'ITEM',
      );
      await plaid.transactionsRefresh('access-x');
      expect(
        transport.bodies('/transactions/refresh').single['access_token'],
        'access-x',
      );
    });
  });

  group('Money from the recorded page', () {
    test('the 316 rows decode with no double, sub-cent amounts half-even', () {
      final page =
          decodePlaidJson(fixtureAnswer('transactions_sync_page1').body)!
              as Map<String, Object?>;
      expect(_leaves(page).whereType<double>(), isEmpty);
      final added = (page['added']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(added, hasLength(316));
      var exact = 0, rounded = 0;
      for (final json in added) {
        final raw = json['amount']!;
        final text = raw is int ? '$raw' : raw as String;
        final money = PlaidTransaction.fromPlaidJson(
          json,
          rounding: HttpPlaidClient.rounding,
        ).amount;
        final dot = text.indexOf('.');
        final digits = dot < 0 ? 0 : text.length - dot - 1;
        if (digits <= 2) {
          exact++;
          // Round-trips to Plaid's text, up to trailing zeros.
          final padded = dot < 0 ? '$text.00' : text.padRight(dot + 3, '0');
          expect(money.toDecimalString(), padded, reason: text);
        } else {
          rounded++;
          expect(money.minorUnits, _centsHalfEven(text), reason: text);
        }
      }
      expect(exact, 281);
      expect(rounded, 35);
    });

    test('the strict reading refuses a sub-cent amount', () {
      expect(() => plaidMoney('10.021521', 'USD'), throwsFormatException);
    });
  });

  group('errors', () {
    HttpPlaidClient over(MockClient client, {Duration? timeout}) =>
        HttpPlaidClient(
          clientId: testPlaidClientId,
          secret: testPlaidSecret,
          baseUrl: Uri.parse('https://sandbox.plaid.com'),
          httpClient: client,
          timeout: timeout ?? const Duration(seconds: 60),
        );

    test('a non-JSON 500, a bare 429, an unreadable 200', () async {
      final answers = [
        http.Response('<html>oops</html>', 500),
        http.Response('', 429),
        http.Response('{"request_id":"r1"}', 200),
        http.Response('[1, 2]', 200),
      ];
      final client = over(MockClient((_) async => answers.removeAt(0)));
      await expectLater(
        client.removeItem('a'),
        throwsA(plaidError('API_ERROR', 'HTTP_500')),
      );
      await expectLater(
        client.removeItem('a'),
        throwsA(
          isA<PlaidException>().having((e) => e.isRateLimit, 'rate', isTrue),
        ),
      );
      await expectLater(
        client.getItem('a'),
        throwsA(plaidError('API_ERROR', 'INVALID_RESPONSE', 'r1')),
      );
      await expectLater(
        client.removeItem('a'),
        throwsA(plaidError('API_ERROR', 'INVALID_RESPONSE')),
      );
    });

    test("Plaid's own rate limit keeps its type", () async {
      final client = over(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error_type': 'RATE_LIMIT_EXCEEDED',
              'error_code': 'TRANSACTIONS_SYNC_LIMIT',
              'error_message': 'slow down',
              'request_id': 'r2',
            }),
            429,
          ),
        ),
      );
      await expectLater(
        client.transactionsSync('a', ''),
        throwsA(
          plaidError('RATE_LIMIT_EXCEEDED', 'TRANSACTIONS_SYNC_LIMIT', 'r2'),
        ),
      );
    });

    test('a timeout and a network failure', () async {
      final hang = over(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        hang.removeItem('a'),
        throwsA(plaidError('API_ERROR', 'TIMEOUT')),
      );
      final down = over(
        MockClient((_) async => throw http.ClientException('refused')),
      );
      await expectLater(
        down.removeItem('a'),
        throwsA(plaidError('API_ERROR', 'NETWORK_ERROR')),
      );
    });
  });

  group('through the server', () {
    late TestServer server;
    late Session ada;

    setUp(() async {
      server = await TestServer.start(plaid: (_) => plaid);
      ada = await server.register();
      transport
        ..byDefault('/item/public_token/exchange', 'item_public_token_exchange')
        ..byDefault('/item/get', 'item_get')
        ..byDefault('/institutions/get_by_id', 'institutions_get_by_id')
        ..byDefault(
          '/transactions/recurring/get',
          'transactions_recurring_get',
        );
    });

    Future<String> link() async {
      final r = await server.call(
        'post',
        '/plaid/exchange',
        token: ada.access,
        body: {'public_token': 'public-recorded'},
      );
      expect(r.status, 201, reason: '$r');
      return r.json['id']! as String;
    }

    test('link, not ready, the page, up to date: every row is plaid', () async {
      transport.script('/transactions/sync', [
        'transactions_sync_not_ready',
        'transactions_sync_page1',
        'transactions_sync_up_to_date',
      ]);
      final itemId = await link();
      Future<TestResponse> sync() =>
          server.call('post', '/plaid/items/$itemId/sync', token: ada.access);
      expect((await sync()).json['status'], 'not_ready');
      final run = await sync();
      expect(run.json, containsPair('status', 'completed'));
      expect(run.json, containsPair('added', 316));
      expect((await sync()).json, containsPair('added', 0));

      final page = await server.call(
        'get',
        '/transactions?since=0',
        token: ada.access,
      );
      final rows = (page.json['transactions']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(rows, hasLength(316));
      expect(rows.map((t) => t['source']).toSet(), {'plaid'});
      expect(_leaves(page.json).whereType<double>(), isEmpty);
      final interest = rows.firstWhere((t) => t['name'] == 'Interest payment');
      // Ingestion flips Plaid's sign: an inflow of 0.12 is positive in ours.
      expect(interest['amount'], Money(12, 'USD').toJson());
      final accounts = await server.call('get', '/accounts', token: ada.access);
      expect(accounts.list, hasLength(7));
      final recurring = await server.call(
        'get',
        '/recurring',
        token: ada.access,
      );
      expect(recurring.list.map((s) => (s! as Map)['source']).toSet(), {
        'plaid',
      });
      final stored = await server.app.db.read(
        (tx) => tx.select(
          'SELECT DISTINCT source FROM accounts UNION '
          'SELECT DISTINCT source FROM transactions UNION '
          'SELECT DISTINCT source FROM recurring_streams',
        ),
      );
      expect(stored.map((r) => r['source']).toSet(), {'plaid'});
    });

    test('login required on a sync is 409 and marks the Item', () async {
      transport.script('/transactions/sync', [
        'transactions_sync_item_login_required',
      ]);
      final itemId = await link();
      final r = await server.call(
        'post',
        '/plaid/items/$itemId/sync',
        token: ada.access,
      );
      expect(r.status, 409);
      expect(r.code, 'item_login_required');
      final items = await server.call('get', '/plaid/items', token: ada.access);
      expect(items.list.single, containsPair('status', 'login_required'));
      expect(
        items.list.single,
        containsPair('error_code', 'ITEM_LOGIN_REQUIRED'),
      );
    });

    test('every row of the seven Plaid tables carries source plaid', () async {
      // Synthesized where the fixtures' Item has none: the investments product and one
      // holding and one investment transaction on the fixtures' checking account.
      const account = '3oB3Mjm6GgFPAM77GLMGfMRoAZbeX4sZvBV5K';
      transport
        ..byDefault('/item/get', (Map<String, Object?> _) {
          final body = jsonDecode(
            fixtureAnswer('item_get').body,
          ) as Map<String, Object?>;
          (body['item']! as Map<String, Object?>)['products'] = [
            'investments',
            'liabilities',
            'transactions',
          ];
          return (status: 200, body: jsonEncode(body));
        })
        ..script('/transactions/sync', ['transactions_sync_page1'])
        ..byDefault('/liabilities/get', 'liabilities_get')
        ..byDefault('/investments/holdings/get', (
          status: 200,
          body:
              '{"holdings":[{"account_id":"$account","security_id":"sec-1",'
              '"quantity":2.5,"institution_price":101.25,'
              '"institution_price_as_of":"2026-10-23","institution_value":253.125,'
              '"cost_basis":200,"iso_currency_code":"USD"}],'
              '"securities":[{"security_id":"sec-1","name":"Index Fund",'
              '"ticker_symbol":"IDX","type":"mutual fund","is_cash_equivalent":false,'
              '"close_price":101.25,"close_price_as_of":"2026-10-23",'
              '"iso_currency_code":"USD"}],"request_id":"r"}',
        ))
        ..byDefault('/investments/transactions/get', (
          status: 200,
          body:
              '{"investment_transactions":[{"investment_transaction_id":"it-1",'
              '"account_id":"$account","security_id":"sec-1","date":"2026-10-01",'
              '"name":"BUY IDX","type":"buy","subtype":"buy","quantity":2.5,'
              '"price":80,"amount":200,"fees":0,"iso_currency_code":"USD"}],'
              '"securities":[],"total_investment_transactions":1,"request_id":"r"}',
        ));
      final itemId = await link();
      final run = await server.call(
        'post',
        '/plaid/items/$itemId/sync',
        token: ada.access,
      );
      expect(run.json['status'], 'completed');
      for (final table in const [
        'accounts',
        'transactions',
        'recurring_streams',
        'liabilities',
        'securities',
        'holdings',
        'investment_transactions',
      ]) {
        final rows = await server.app.db.read(
          (tx) => tx.select('SELECT source FROM $table'),
        );
        expect(rows, isNotEmpty, reason: table);
        expect(rows.map((r) => r['source']).toSet(), {'plaid'}, reason: table);
      }
      final holding = await server.app.db.read(
        (tx) => tx.first('SELECT institution_value_minor FROM holdings'),
      );
      // 253.125 rounds half-even to 253.12.
      expect(holding!['institution_value_minor'], 25312);
    });

    test('a full flow logs no key, secret or token', () async {
      const linkToken = 'link-token-value-first';
      const updateToken = 'link-token-value-update';
      const publicToken = 'public-token-value-from-link';
      const accessToken = 'access-token-value-from-exchange';
      RecordedAnswer token(String value) => (
        status: 200,
        body: jsonEncode({
          'link_token': value,
          'expiration': '2026-10-25T01:51:05Z',
          'request_id': 'req-link',
        }),
      );
      transport
        ..script('/link/token/create', [token(linkToken), token(updateToken)])
        ..script('/item/public_token/exchange', [
          (
            status: 200,
            body: jsonEncode({
              'access_token': accessToken,
              'item_id': 'GA3WJ917yPhb4BvvaZBaiNxDLnljrqiWqxpvK',
              'request_id': 'req-exchange',
            }),
          ),
        ])
        ..script('/transactions/sync', [
          'transactions_sync_page1',
          'transactions_sync_item_login_required',
        ]);
      final lines = <String>[];
      final subscription = Logger.root.onRecord.listen(
        (r) => lines.add(formatRecord(r, LogFormat.json)),
      );
      addTearDown(subscription.cancel);

      final link = await server.call(
        'post',
        '/plaid/link-token',
        token: ada.access,
        body: {'android_package_name': _package},
      );
      expect(link.json['link_token'], linkToken);
      final item = await server.call(
        'post',
        '/plaid/exchange',
        token: ada.access,
        body: {'public_token': publicToken},
      );
      final itemId = item.json['id']! as String;
      final update = await server.call(
        'post',
        '/plaid/items/$itemId/update-link-token',
        token: ada.access,
        body: {'android_package_name': _package},
      );
      expect(update.json['link_token'], updateToken);
      for (var i = 0; i < 2; i++) {
        await server.call(
          'post',
          '/plaid/items/$itemId/sync',
          token: ada.access,
        );
      }
      // The access token reached Plaid on the update-mode and sync calls.
      expect(
        transport.bodies('/transactions/sync').first['access_token'],
        accessToken,
      );
      final paths = {
        for (final l in lines)
          if (jsonDecode(l) case {
            'event': 'plaid_call',
            'path': final String path,
          })
            path,
      };
      expect(
        paths,
        containsAll([
          '/link/token/create',
          '/item/public_token/exchange',
          '/item/get',
          '/transactions/sync',
        ]),
      );
      expect(lines.join('\n'), contains('11aa49fd0aa1d74'));
      for (final line in lines) {
        for (final secret in [
          testPlaidClientId,
          testPlaidSecret,
          linkToken,
          updateToken,
          publicToken,
          accessToken,
          ada.access,
        ]) {
          expect(line, isNot(contains(secret)), reason: line);
        }
      }
    });
  });
}
