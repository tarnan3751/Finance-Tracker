// The mirror test: every shared_models entity the contract carries, serialized fully
// populated and with every nullable field null, conforms to the schema of the same name,
// strictly (an undeclared key fails, and every declared property is required), so the
// models and the contract cannot drift apart. The documented differences are applied
// here and nowhere else: the API's Item embeds its Institution, ChangeLogEntry travels
// without the local `synced` flag, and PulledChangeLogEntry adds the server's `seq`.
import 'dart:convert';

import 'package:contract_test/contract_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

import 'support.dart';

final _instant = DateTime.utc(2026, 10, 24, 15, 4, 5, 123);
final _date = LocalDate(2026, 10, 24);
Money _usd(int cents) => Money(cents, 'USD');

/// Encodes and decodes, so the value is the JSON a peer would receive.
Map<String, Object?> _wire(Object model) =>
    jsonDecode(jsonEncode(model)) as Map<String, Object?>;

final _institutionFull = Institution(
  id: 'ins_109508',
  name: 'First Platypus Bank',
  logoUrl: Uri.parse('https://example.com/logo.png'),
  primaryColor: 0xFF1E88E5,
);
const _institutionNulls = Institution(id: 'ins_1', name: 'Bank');

final _transactionFull = Transaction(
  id: 't1',
  accountId: 'a1',
  amount: _usd(-1299),
  date: _date,
  authorizedDate: LocalDate(2026, 10, 23),
  pending: true,
  pendingTransactionId: 't0',
  name: 'NETFLIX.COM',
  merchantName: 'Netflix',
  merchantLogoUrl: Uri.parse('https://example.com/n.png'),
  plaidPrimaryCategory: 'ENTERTAINMENT',
  plaidDetailedCategory: 'ENTERTAINMENT_TV_AND_MOVIES',
  userCategoryId: 'c1',
  notes: 'shared',
  tags: const ['tv'],
  splits: [
    TransactionSplit(categoryId: 'c1', amount: _usd(-1000), note: 'mine'),
    TransactionSplit(categoryId: 'c2', amount: _usd(-299)),
  ],
  receiptPath: 'receipts/t1.jpg',
  hidden: true,
  source: DataSource.plaid,
  createdAt: _instant,
  updatedAt: _instant,
  deletedAt: _instant,
  syncVersion: 42,
);

final _changeFull = ChangeLogEntry(
  entityType: EntityType.recurringStream,
  entityId: 's1',
  operation: ChangeOperation.update,
  payload: const {
    'notes': 'x',
    'nested': {'a': 1},
  },
  hlc: Hlc(1761300000000, 3, 'device-1'),
  deviceId: 'device-1',
  synced: true,
);
final _changeMinimal = ChangeLogEntry(
  entityType: EntityType.settings,
  entityId: 'theme',
  operation: ChangeOperation.delete,
  payload: const {},
  hlc: Hlc(0, 0, 'd'),
  deviceId: 'd',
  synced: false,
);

/// (schema, fully populated JSON, all-nulls JSON), as responses.
final _responses = <(String, Map<String, Object?>, Map<String, Object?>)>[
  ('Money', _wire(_usd(-1234)), _wire(Money(0, 'JPY'))),
  (
    'User',
    _wire(
      User(
        id: 'u1',
        email: 'a@example.com',
        displayName: 'A',
        createdAt: _instant,
      ),
    ),
    _wire(
      User(
        id: 'u1',
        email: 'a@example.com',
        displayName: 'A',
        createdAt: _instant,
      ),
    ),
  ),
  (
    'Device',
    _wire(Device(id: 'd1', userId: 'u1', name: 'Pixel', lastSyncAt: _instant)),
    _wire(const Device(id: 'd1', userId: 'u1', name: 'Pixel')),
  ),
  ('Institution', _wire(_institutionFull), _wire(_institutionNulls)),
  (
    'Item',
    {
      ..._wire(
        Item(
          id: 'i1',
          institutionId: 'ins_109508',
          status: ItemStatus.loginRequired,
          lastSuccessfulSyncAt: _instant,
        ),
      ),
      'institution': _wire(_institutionFull),
    },
    {
      ..._wire(
        const Item(
          id: 'i1',
          institutionId: 'ins_1',
          status: ItemStatus.healthy,
        ),
      ),
      'institution': _wire(_institutionNulls),
    },
  ),
  (
    'Account',
    _wire(
      Account(
        id: 'a1',
        itemId: 'i1',
        type: AccountType.credit,
        subtype: 'credit card',
        name: 'Card',
        officialName: 'Platinum Card',
        mask: '3333',
        currencyCode: 'USD',
        currentBalance: _usd(41000),
        availableBalance: _usd(59000),
        creditLimit: _usd(100000),
        balancesAsOf: _instant,
        isHidden: true,
        displayOrder: 3,
      ),
    ),
    _wire(
      const Account(
        id: 'a1',
        type: AccountType.other,
        name: 'Cash',
        currencyCode: 'EUR',
        isHidden: false,
        displayOrder: 0,
      ),
    ),
  ),
  (
    'Transaction',
    _wire(_transactionFull),
    _wire(
      Transaction(
        id: 't2',
        accountId: 'a1',
        amount: _usd(500),
        date: _date,
        pending: false,
        name: 'Deposit',
        source: DataSource.manual,
        createdAt: _instant,
        updatedAt: _instant,
        syncVersion: 0,
      ),
    ),
  ),
  (
    'TransactionSplit',
    _wire(TransactionSplit(categoryId: 'c1', amount: _usd(-1), note: 'n')),
    _wire(TransactionSplit(categoryId: 'c1', amount: _usd(-1))),
  ),
  (
    'RecurringStream',
    _wire(
      RecurringStream(
        id: 's1',
        accountId: 'a1',
        merchantName: 'Netflix',
        cadence: RecurringCadence.semiMonthly,
        averageAmount: _usd(-1299),
        lastExpected: _date,
        nextExpected: LocalDate(2026, 11, 24),
        status: RecurringStatus.ended,
        isSubscription: true,
        source: RecurringSource.detected,
        transactionIds: ['t1', 't2'],
      ),
    ),
    _wire(
      RecurringStream(
        id: 's1',
        accountId: 'a1',
        merchantName: 'Payroll',
        cadence: RecurringCadence.quarterly,
        averageAmount: _usd(250000),
        status: RecurringStatus.active,
        isSubscription: false,
        source: RecurringSource.plaid,
      ),
    ),
  ),
  (
    'PulledChangeLogEntry',
    {..._wire(_changeFull)..remove('synced'), 'seq': 18},
    {..._wire(_changeMinimal)..remove('synced'), 'seq': 1},
  ),
];

void main() {
  for (final (name, full, nulls) in _responses) {
    group(name, () {
      test('fully populated conforms', () {
        expect(full, conformsToSchema(contract, name));
      });
      test('with every nullable field null conforms', () {
        expect(nulls, conformsToSchema(contract, name));
      });
    });
  }

  test('every enum has the same values as shared_models', () {
    // The enums serialize as their snake_case names (JsonEnum fieldRename: snake).
    String snake(Enum value) => value.name.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '_${match[0]!.toLowerCase()}',
    );
    final enums = <String, List<Enum>>{
      'AccountType': AccountType.values,
      'ItemStatus': ItemStatus.values,
      'DataSource': DataSource.values,
      'RecurringCadence': RecurringCadence.values,
      'RecurringStatus': RecurringStatus.values,
      'RecurringSource': RecurringSource.values,
      'EntityType': EntityType.values,
      'ChangeOperation': ChangeOperation.values,
    };
    for (final MapEntry(key: name, value: values) in enums.entries) {
      expect(
        contract.schema(name)['enum'],
        unorderedEquals(values.map(snake)),
        reason: name,
      );
    }
  });

  group('ChangeLogEntry, as pushed', () {
    test('fully populated, without synced, conforms', () {
      expect(
        _wire(_changeFull)..remove('synced'),
        conformsToSchema(
          contract,
          'ChangeLogEntry',
          mode: ValidationMode.request,
        ),
      );
    });
    test('minimal, without synced, conforms', () {
      expect(
        _wire(_changeMinimal)..remove('synced'),
        conformsToSchema(
          contract,
          'ChangeLogEntry',
          mode: ValidationMode.request,
        ),
      );
    });
    test('the local synced flag is refused', () {
      expect(
        _wire(_changeFull),
        isNot(
          conformsToSchema(
            contract,
            'ChangeLogEntry',
            mode: ValidationMode.request,
          ),
        ),
      );
    });
    test('a seq is refused', () {
      expect(
        {..._wire(_changeFull)..remove('synced'), 'seq': 1},
        isNot(
          conformsToSchema(
            contract,
            'ChangeLogEntry',
            mode: ValidationMode.request,
          ),
        ),
      );
    });
    test('a push body of entries conforms to the operation', () {
      expect({
        'entries': [_wire(_changeFull)..remove('synced')],
      }, conformsToRequest(contract, '/sync/push', 'post'));
    });
  });
}
