// The two checks beyond draft 7: an integer is a Dart int, never a whole-valued double
// or an out-of-range integer that jsonDecode returned as a double; and a date or an
// instant is a real one, whatever pattern the document adds. Values are decoded from JSON
// text, as a test of a real response would see them.
import 'dart:convert';

import 'package:contract_test/contract_test.dart';
import 'package:test/test.dart';

import 'support.dart';

/// 2^63, one past the largest int64: jsonDecode returns it as a double.
const _tooBig = '9223372036854775808';

Map<String, Object?> _transaction({String syncVersion = '42'}) => jsonDecode('''
{"id": "t1", "account_id": "a1", "amount": {"minor_units": -1299, "currency": "USD"},
 "date": "2026-10-23", "authorized_date": null, "pending": false,
 "pending_transaction_id": null, "name": "NETFLIX.COM", "merchant_name": null,
 "merchant_logo_url": null, "plaid_primary_category": null,
 "plaid_detailed_category": null, "user_category_id": null, "notes": null, "tags": [],
 "splits": [], "receipt_path": null, "hidden": false, "source": "plaid",
 "created_at": "2026-10-23T12:00:00.000Z", "updated_at": "2026-10-23T12:00:00.000Z",
 "deleted_at": null, "sync_version": $syncVersion}
''') as Map<String, Object?>;

Map<String, Object?> _pulled({String seq = '18'}) => jsonDecode('''
{"entity_type": "goal", "entity_id": "g1", "operation": "update",
 "payload": {"progress": 0.5}, "hlc": "001761300000000-00000-device-2",
 "device_id": "device-2", "seq": $seq}
''') as Map<String, Object?>;

void main() {
  group('an integer must be an int', () {
    for (final bad in ['1.0', '1e3', _tooBig]) {
      test('minor_units $bad fails', () {
        final money = jsonDecode('{"minor_units": $bad, "currency": "USD"}');
        expect(money, isNot(conformsToSchema(contract, 'Money')));
        expect(
          contract.validator.validateSchema(
            'Money',
            money,
            mode: ValidationMode.response,
          ),
          contains(startsWith('/minor_units: wanted an integer')),
        );
      });
      test('sync_version $bad fails', () {
        expect(
          _transaction(syncVersion: bad),
          isNot(conformsToSchema(contract, 'Transaction')),
        );
      });
      test('seq $bad fails', () {
        expect(
          _pulled(seq: bad),
          isNot(conformsToSchema(contract, 'PulledChangeLogEntry')),
        );
      });
      test('next_since $bad fails', () {
        final page = jsonDecode(
          '{"transactions": [], "next_since": $bad, "has_more": false}',
        );
        expect(page, isNot(conformsToSchema(contract, 'TransactionPage')));
      });
    }

    test('a nested double inside a nullable Money fails', () {
      final account =
          (jsonDecode(jsonEncode(contract.schema('Account')['example']))
                as Map<String, Object?>)
            ..['credit_limit'] = jsonDecode(
              '{"minor_units": 1.0, "currency": "USD"}',
            );
      expect(
        contract.validator.validateSchema(
          'Account',
          account,
          mode: ValidationMode.response,
        ),
        contains(startsWith('/credit_limit/minor_units: wanted an integer')),
      );
    });

    test('ints pass, and a double in a free-form payload is not an error', () {
      expect(_transaction(), conformsToSchema(contract, 'Transaction'));
      expect(_pulled(), conformsToSchema(contract, 'PulledChangeLogEntry'));
      expect(
        jsonDecode('{"minor_units": 9223372036854775807, "currency": "USD"}'),
        conformsToSchema(contract, 'Money'),
      );
    });
  });

  group('dates and instants are real', () {
    // No pattern here, so only the format checks stand between a value and a pass.
    final bare = OpenApiDocument.parse('''
openapi: 3.0.3
info: {title: t, version: '1'}
paths: {}
components:
  schemas:
    Day: {type: string, format: date}
    Moment: {type: string, format: date-time}
''');
    List<String> check(String name, String value) => bare.validator
        .validateSchema(name, value, mode: ValidationMode.response);

    test('a calendar date passes', () {
      expect(check('Day', '2026-10-24'), isEmpty);
      expect(check('Day', '2024-02-29'), isEmpty);
    });

    for (final bad in [
      '2026-02-30',
      '2025-02-29',
      '2026-13-24',
      '20261024',
      '2026-1-24',
    ]) {
      test('the date $bad fails', () {
        expect(check('Day', bad), isNotEmpty);
      });
    }

    test('instants with Z or an offset pass', () {
      expect(check('Moment', '2026-10-24T09:30:00.000Z'), isEmpty);
      expect(check('Moment', '2026-10-24T09:30:00+05:30'), isEmpty);
    });

    for (final bad in [
      '2026-13-24T09:30:00.000Z',
      '2026-02-30T09:30:00.000Z',
      '2026-10-24T24:00:00Z',
      '2026-10-24T09:60:00Z',
      '2026-10-24T09:30:60Z',
      '2026-10-24T09:30:00+25:00',
      '20261024T093000Z',
      '2026-10-24T09:30:00',
    ]) {
      test('the instant $bad fails', () {
        expect(check('Moment', bad), isNotEmpty);
      });
    }

    test("the contract's dates are checked too", () {
      expect(
        _transaction()..['date'] = '2026-02-30',
        isNot(conformsToSchema(contract, 'Transaction')),
      );
    });
  });
}
