// A smoke test of the generated client: a Dio whose interceptor answers canned JSON, so
// no socket is opened, driving getHealth, listAccounts and listTransactions. It proves the
// generated built_value serializers read Money, ISO dates and UTC instants, and that an
// Account written back by the serializers is the JSON it was read from.
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

const _account = {
  'id': 'acc-1',
  'item_id': 'item-1',
  'type': 'credit',
  'subtype': 'credit card',
  'name': 'Plaid Credit Card',
  'official_name': null,
  'mask': '3333',
  'currency_code': 'USD',
  'current_balance': {'minor_units': 41000, 'currency': 'USD'},
  'available_balance': null,
  'credit_limit': {'minor_units': 9223372036854775807, 'currency': 'USD'},
  'balances_as_of': '2026-10-24T09:30:00.250Z',
  'is_hidden': false,
  'display_order': 2,
};

const _transaction = {
  'id': 'txn-1',
  'account_id': 'acc-1',
  'amount': {'minor_units': -1299, 'currency': 'USD'},
  'date': '2026-10-23',
  'authorized_date': null,
  'pending': false,
  'pending_transaction_id': null,
  'name': 'NETFLIX.COM',
  'merchant_name': 'Netflix',
  'merchant_logo_url': null,
  'plaid_primary_category': 'ENTERTAINMENT',
  'plaid_detailed_category': null,
  'user_category_id': null,
  'notes': null,
  'tags': <String>[],
  'splits': [
    {
      'category_id': 'c1',
      'amount': {'minor_units': -1299, 'currency': 'USD'},
      'note': null,
    },
  ],
  'receipt_path': null,
  'source': 'plaid',
  'created_at': '2026-10-23T12:00:00.000Z',
  'updated_at': '2026-10-23T12:00:00.000Z',
  'deleted_at': null,
  'sync_version': 42,
};

/// The canned answers, by path, and the requests seen.
final class _Canned extends Interceptor {
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    final body = switch (options.path) {
      '/health' => {'status': 'ok', 'version': '0.2.0'},
      '/accounts' => [_account],
      '/transactions' => {
        'transactions': [_transaction],
        'next_since': 42,
        'has_more': false,
      },
      _ => null,
    };
    if (body == null) {
      handler.reject(
        DioException(requestOptions: options, message: 'unexpected'),
      );
      return;
    }
    handler.resolve(
      Response<Object?>(
        requestOptions: options,
        statusCode: 200,
        // As Dio's JSON transformer would hand it over: decoded from the wire text.
        data: jsonDecode(jsonEncode(body)),
        headers: Headers.fromMap({
          Headers.contentTypeHeader: [Headers.jsonContentType],
        }),
      ),
    );
  }
}

void main() {
  late _Canned canned;
  late ApiClient client;

  setUp(() {
    canned = _Canned();
    client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'http://localhost:8080/v1')),
      interceptors: [canned],
    );
  });

  test('getHealth reads the health check', () async {
    final health = (await client.getHealthApi().getHealth()).data!;
    expect(health.status, HealthStatusEnum.ok);
    expect(health.version, '0.2.0');
  });

  test('listAccounts reads Money, nulls and a UTC instant', () async {
    final accounts = (await client.getDataApi().listAccounts()).data!;
    final account = accounts.single;
    expect(account.type, AccountType.credit);
    expect(account.currentBalance!.minorUnits, 41000);
    expect(account.currentBalance!.currency, 'USD');
    expect(account.availableBalance, isNull);
    expect(account.creditLimit!.minorUnits, 9223372036854775807);
    expect(account.officialName, isNull);
    expect(account.balancesAsOf, DateTime.utc(2026, 10, 24, 9, 30, 0, 250));
    expect(account.balancesAsOf!.isUtc, isTrue);
  });

  test('an Account round-trips through the serializers', () async {
    final account = (await client.getDataApi().listAccounts()).data!.single;
    final written = standardSerializers.serialize(
      account,
      specifiedType: const FullType(Account),
    );
    expect(jsonDecode(jsonEncode(written)), _account);
  });

  test('listTransactions reads a page with ISO dates and splits', () async {
    final page = (await client.getDataApi().listTransactions(since: 41)).data!;
    expect(canned.requests.single.queryParameters, {'since': 41, 'limit': 500});
    expect(page.nextSince, 42);
    expect(page.hasMore, isFalse);
    final transaction = page.transactions.single;
    expect(transaction.amount.minorUnits, -1299);
    expect(transaction.date, Date(2026, 10, 23));
    expect(transaction.authorizedDate, isNull);
    expect(transaction.source_, DataSource.plaid);
    expect(transaction.splits.single.amount.minorUnits, -1299);
    expect(transaction.deletedAt, isNull);
  });
}
