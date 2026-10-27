// Round trips every entity through JSON (and through a real encode and decode), once with
// every field populated and once with every nullable field null, and checks the wire
// conventions: snake_case keys, Money objects, ISO dates, UTC millisecond instants with Z,
// enum fallbacks for Plaid-mirroring values, and errors at the boundary.
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

final _instant = DateTime.utc(2026, 10, 24, 15, 4, 5, 123);
final _later = DateTime.utc(2026, 10, 25, 8, 0, 0, 1);
final _date = LocalDate(2026, 10, 24);
Money _usd(int cents) => Money(cents, 'USD');

/// (name, full instance, minimal instance, fromJson).
final List<(String, Object, Object, Object Function(Map<String, dynamic>))>
_entities = [
  (
    'User',
    User(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'A',
      createdAt: _instant,
    ),
    User(
      id: 'u1',
      email: 'a@example.com',
      displayName: 'A',
      createdAt: _instant,
    ),
    User.fromJson,
  ),
  (
    'Device',
    Device(id: 'd1', userId: 'u1', name: 'Pixel', lastSyncAt: _instant),
    const Device(id: 'd1', userId: 'u1', name: 'Pixel'),
    Device.fromJson,
  ),
  (
    'Institution',
    Institution(
      id: 'ins_109508',
      name: 'First Platypus Bank',
      logoUrl: Uri.parse('https://example.com/logo.png'),
      primaryColor: 0xFF1A73E8,
    ),
    const Institution(id: 'ins_109508', name: 'First Platypus Bank'),
    Institution.fromJson,
  ),
  (
    'Item',
    Item(
      id: 'item1',
      institutionId: 'ins_109508',
      status: ItemStatus.pendingExpiration,
      lastSuccessfulSyncAt: _instant,
      errorCode: 'ITEM_LOGIN_REQUIRED',
    ),
    const Item(
      id: 'item1',
      institutionId: 'ins_109508',
      status: ItemStatus.healthy,
    ),
    Item.fromJson,
  ),
  (
    'Account',
    Account(
      id: 'acc1',
      itemId: 'item1',
      type: AccountType.credit,
      subtype: 'credit card',
      name: 'Plaid Credit Card',
      officialName: 'Plaid Diamond 12.5% APR Interest Credit Card',
      mask: '3333',
      currencyCode: 'USD',
      currentBalance: _usd(41000),
      availableBalance: _usd(-41000),
      creditLimit: _usd(200000),
      balancesAsOf: _instant,
      isHidden: true,
      displayOrder: 3,
    ),
    const Account(
      id: 'acc2',
      type: AccountType.depository,
      name: 'Wallet',
      currencyCode: 'JPY',
      isHidden: false,
      displayOrder: 0,
    ),
    Account.fromJson,
  ),
  (
    'Transaction',
    Transaction(
      id: 't1',
      accountId: 'acc1',
      amount: _usd(-1299),
      date: _date,
      authorizedDate: LocalDate(2026, 10, 23),
      pending: true,
      pendingTransactionId: 't0',
      name: 'NETFLIX.COM',
      merchantName: 'Netflix',
      merchantLogoUrl: Uri.parse('https://example.com/netflix.png'),
      plaidPrimaryCategory: 'ENTERTAINMENT',
      plaidDetailedCategory: 'ENTERTAINMENT_TV_AND_MOVIES',
      userCategoryId: 'cat1',
      notes: 'family plan',
      tags: const ['subscription', 'shared'],
      splits: [
        TransactionSplit(categoryId: 'cat1', amount: _usd(-1000), note: 'me'),
        TransactionSplit(categoryId: 'cat2', amount: _usd(-299)),
      ],
      receiptPath: 'receipts/t1.jpg',
      hidden: true,
      source: DataSource.plaid,
      createdAt: _instant,
      updatedAt: _later,
      deletedAt: _later,
      syncVersion: 7,
    ),
    Transaction(
      id: 't2',
      accountId: 'acc2',
      amount: Money(50000, 'JPY'),
      date: _date,
      pending: false,
      name: 'Opening balance',
      source: DataSource.manual,
      createdAt: _instant,
      updatedAt: _instant,
      syncVersion: 0,
    ),
    Transaction.fromJson,
  ),
  (
    'TransactionSplit',
    TransactionSplit(categoryId: 'c', amount: _usd(5), note: 'n'),
    TransactionSplit(categoryId: 'c', amount: _usd(5)),
    TransactionSplit.fromJson,
  ),
  (
    'Category',
    const Category(
      id: 'cat1',
      name: 'TV and movies',
      parentId: 'cat0',
      isSystem: true,
      icon: 'movie',
      color: 0xFFE53935,
      plaidCategory: 'ENTERTAINMENT_TV_AND_MOVIES',
    ),
    const Category(
      id: 'cat9',
      name: 'Pets',
      isSystem: false,
      icon: 'pets',
      color: 0xFF43A047,
    ),
    Category.fromJson,
  ),
  (
    'Rule',
    Rule(
      id: 'r1',
      name: 'Coffee',
      position: 2,
      conditions: [
        const RuleCondition(
          kind: RuleConditionKind.merchantContains,
          text: 'STARBUCKS',
        ),
        RuleCondition(
          kind: RuleConditionKind.amountBetween,
          minAmount: _usd(-2000),
          maxAmount: _usd(0),
        ),
      ],
      actions: const [
        RuleAction(kind: RuleActionKind.setCategory, value: 'cat5'),
        RuleAction(kind: RuleActionKind.hide),
      ],
    ),
    const Rule(
      id: 'r2',
      name: 'Empty',
      position: 0,
      conditions: [],
      actions: [],
    ),
    Rule.fromJson,
  ),
  (
    'RuleCondition',
    RuleCondition(
      kind: RuleConditionKind.amountBetween,
      text: 'x',
      minAmount: _usd(1),
      maxAmount: _usd(2),
    ),
    const RuleCondition(kind: RuleConditionKind.account),
    RuleCondition.fromJson,
  ),
  (
    'RuleAction',
    const RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
    const RuleAction(kind: RuleActionKind.hide),
    RuleAction.fromJson,
  ),
  (
    'Budget',
    Budget(
      id: 'b1',
      categoryId: 'cat1',
      period: BudgetPeriodKind.monthly,
      periodStartDay: 25,
      amount: _usd(40000),
      rollover: true,
      startDate: LocalDate(2026, 9, 25),
    ),
    Budget(
      id: 'b1',
      categoryId: 'cat1',
      period: BudgetPeriodKind.monthly,
      periodStartDay: 1,
      amount: _usd(0),
      rollover: false,
      startDate: LocalDate(2024, 2, 29),
    ),
    Budget.fromJson,
  ),
  (
    'RecurringStream',
    RecurringStream(
      id: 's1',
      accountId: 'acc1',
      merchantName: 'Netflix',
      cadence: RecurringCadence.semiMonthly,
      averageAmount: _usd(-1299),
      lastExpected: LocalDate(2026, 9, 24),
      nextExpected: LocalDate(2026, 11, 24),
      status: RecurringStatus.active,
      isSubscription: true,
      source: RecurringSource.plaid,
      transactionIds: ['t1', 't2'],
    ),
    RecurringStream(
      id: 's2',
      accountId: 'acc1',
      merchantName: 'Gym',
      cadence: RecurringCadence.quarterly,
      averageAmount: _usd(-4000),
      status: RecurringStatus.ended,
      isSubscription: false,
      source: RecurringSource.user,
    ),
    RecurringStream.fromJson,
  ),
  (
    'BillReminder',
    BillReminder(
      id: 'br1',
      streamId: 's1',
      name: 'Netflix',
      amount: _usd(-1299),
      dueDate: _date,
      reminderOffsetDays: const [3, 1],
    ),
    BillReminder(id: 'br2', dueDate: _date, reminderOffsetDays: const []),
    BillReminder.fromJson,
  ),
  (
    'Goal',
    Goal(
      id: 'g1',
      name: 'Emergency fund',
      target: _usd(1000000),
      linkedAccountIds: const ['acc1', 'acc2'],
      targetDate: LocalDate(2027, 12, 31),
      contributions: [GoalContribution(date: _date, amount: _usd(25000))],
    ),
    Goal(
      id: 'g2',
      name: 'Trip',
      target: _usd(300000),
      linkedAccountIds: const [],
      contributions: const [],
    ),
    Goal.fromJson,
  ),
  (
    'GoalContribution',
    GoalContribution(date: _date, amount: _usd(1)),
    GoalContribution(date: _date, amount: _usd(-1)),
    GoalContribution.fromJson,
  ),
  (
    'BalanceSnapshot',
    BalanceSnapshot(
      accountId: 'acc1',
      date: _date,
      current: _usd(41000),
      available: _usd(159000),
      limit: _usd(200000),
      source: DataSource.plaid,
    ),
    BalanceSnapshot(
      accountId: 'acc1',
      date: _date,
      current: _usd(41000),
      source: DataSource.derived,
    ),
    BalanceSnapshot.fromJson,
  ),
  (
    'NetWorthSnapshot',
    NetWorthSnapshot(
      date: _date,
      assets: _usd(1500000),
      liabilities: _usd(41000),
      byAccount: {'acc1': _usd(-41000), 'acc_2-x': _usd(1500000)},
      source: DataSource.derived,
    ),
    NetWorthSnapshot(
      date: _date,
      assets: _usd(0),
      liabilities: _usd(0),
      byAccount: const {},
      source: DataSource.demo,
    ),
    NetWorthSnapshot.fromJson,
  ),
  (
    'ChangeLogEntry',
    ChangeLogEntry(
      entityType: EntityType.recurringStream,
      entityId: 's1',
      operation: ChangeOperation.update,
      payload: const {
        'merchant_name': 'Netflix',
        'tags': ['a'],
        'nested': {'k': 1},
      },
      hlc: Hlc(1792854245123, 3, '7f3c2a1e-node'),
      deviceId: 'd1',
      synced: true,
    ),
    ChangeLogEntry(
      entityType: EntityType.settings,
      entityId: 'settings',
      operation: ChangeOperation.create,
      payload: const {},
      hlc: Hlc(0, 0, 'n'),
      deviceId: 'd1',
      synced: false,
    ),
    ChangeLogEntry.fromJson,
  ),
];

Map<String, dynamic> _toJson(Object entity) =>
    (entity as dynamic).toJson() as Map<String, dynamic>;

/// Every key in [json], recursively, except inside the free-form maps whose keys are data.
Iterable<(String, Object?)> _entries(Map<String, dynamic> json) sync* {
  for (final MapEntry(:key, :value) in json.entries) {
    yield (key, value);
    if (key == 'payload' || key == 'by_account') continue;
    if (value is Map<String, dynamic>) yield* _entries(value);
    if (value is List) {
      for (final element in value) {
        if (element is Map<String, dynamic>) yield* _entries(element);
      }
    }
  }
}

final _snake = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)*$');
final _instantForm = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$');

void main() {
  for (final (name, full, minimal, fromJson) in _entities) {
    group(name, () {
      for (final (label, entity) in [('full', full), ('minimal', minimal)]) {
        test('round trips ($label)', () {
          final json = _toJson(entity);
          expect(fromJson(json), entity);
          final wire = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
          expect(fromJson(wire), entity);
          expect(jsonEncode(_toJson(fromJson(wire))), jsonEncode(json));
        });

        test('uses snake_case keys and UTC millisecond instants ($label)', () {
          for (final (key, value) in _entries(_toJson(entity))) {
            expect(key, matches(_snake));
            if ((key.endsWith('_at') || key == 'balances_as_of') &&
                value != null) {
              expect(value, matches(_instantForm), reason: key);
            }
          }
        });
      }
    });
  }

  group('nullability', () {
    test('every nullable field is null in the minimal instances', () {
      final transaction = _toJson(_entities[5].$3);
      for (final key in [
        'authorized_date',
        'pending_transaction_id',
        'merchant_name',
        'merchant_logo_url',
        'plaid_primary_category',
        'plaid_detailed_category',
        'user_category_id',
        'notes',
        'receipt_path',
        'deleted_at',
      ]) {
        expect(transaction, containsPair(key, null), reason: key);
      }
      final account = _toJson(_entities[4].$3);
      for (final key in [
        'item_id',
        'subtype',
        'official_name',
        'mask',
        'current_balance',
        'available_balance',
        'credit_limit',
        'balances_as_of',
      ]) {
        expect(account, containsPair(key, null), reason: key);
      }
    });
  });

  group('wire shape', () {
    test('a transaction carries Money, dates and provenance as specified', () {
      final json = _toJson(_entities[5].$2);
      expect(json['amount'], {'minor_units': -1299, 'currency': 'USD'});
      expect(json['date'], '2026-10-24');
      expect(json['authorized_date'], '2026-10-23');
      expect(json['created_at'], '2026-10-24T15:04:05.123Z');
      expect(json['source'], 'plaid');
      expect(json['merchant_logo_url'], 'https://example.com/netflix.png');
      expect(json['splits'], [
        {
          'category_id': 'cat1',
          'amount': {'minor_units': -1000, 'currency': 'USD'},
          'note': 'me',
        },
        {
          'category_id': 'cat2',
          'amount': {'minor_units': -299, 'currency': 'USD'},
          'note': null,
        },
      ]);
    });

    test('enums are snake_case', () {
      expect(_toJson(_entities[3].$2)['status'], 'pending_expiration');
      expect(_toJson(_entities[12].$2)['cadence'], 'semi_monthly');
      expect(_toJson(_entities[18].$2)['entity_type'], 'recurring_stream');
      expect(
        _toJson(_entities[8].$2)['conditions'],
        contains(containsPair('kind', 'merchant_contains')),
      );
      expect(DataSource.values.map((v) => v.name), [
        'plaid',
        'manual',
        'import',
        'derived',
        'demo',
      ]);
    });

    test('the HLC is its packed string', () {
      expect(
        _toJson(_entities[18].$2)['hlc'],
        '001792854245123-00003-7f3c2a1e-node',
      );
    });

    test('tags and splits default to empty', () {
      final json = _toJson(_entities[5].$3)
        ..remove('tags')
        ..remove('splits');
      final transaction = Transaction.fromJson(json);
      expect(transaction.tags, isEmpty);
      expect(transaction.splits, isEmpty);
    });
  });

  group('boundary', () {
    test('unknown Plaid values fall back instead of throwing', () {
      final item = _toJson(_entities[3].$2)..['status'] = 'something_new';
      expect(Item.fromJson(item).status, ItemStatus.unknown);
      final account = _toJson(_entities[4].$2)..['type'] = 'crypto';
      expect(Account.fromJson(account).type, AccountType.other);
      final stream = _toJson(_entities[12].$2)..['cadence'] = 'fortnightly';
      expect(
        RecurringStream.fromJson(stream).cadence,
        RecurringCadence.unknown,
      );
    });

    test('an unknown provenance is an error, not a guess', () {
      final json = _toJson(_entities[5].$2)..['source'] = 'synthetic';
      expect(
        () => Transaction.fromJson(json),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });

    test('a floating amount is rejected at the boundary', () {
      final json = _toJson(_entities[5].$2)
        ..['amount'] = {'minor_units': 12.99, 'currency': 'USD'};
      expect(
        () => Transaction.fromJson(json),
        throwsA(
          isA<CheckedFromJsonException>()
              .having((e) => e.key, 'key', 'amount')
              .having((e) => e.innerError, 'innerError', isFormatException),
        ),
      );
    });

    test('a zone-less instant is rejected at the boundary', () {
      final json = _toJson(_entities[0].$2)
        ..['created_at'] = '2026-10-24T15:04:05';
      expect(
        () => User.fromJson(json),
        throwsA(
          isA<CheckedFromJsonException>().having(
            (e) => e.innerError,
            'innerError',
            isFormatException,
          ),
        ),
      );
    });

    test('a local DateTime cannot be serialized', () {
      final user = User(
        id: 'u',
        email: 'e',
        displayName: 'd',
        createdAt: DateTime(2026),
      );
      expect(user.toJson, throwsArgumentError);
    });

    test('a budget period start day outside 1 to 28 is rejected in JSON', () {
      for (final day in [0, 29, 31, -1]) {
        final json = _toJson(_entities[11].$2)..['period_start_day'] = day;
        expect(
          () => Budget.fromJson(json),
          throwsA(
            isA<CheckedFromJsonException>()
                .having((e) => e.key, 'key', 'period_start_day')
                .having((e) => e.innerError, 'innerError', isFormatException),
          ),
          reason: '$day',
        );
      }
      for (final day in [1, 28]) {
        final json = _toJson(_entities[11].$2)..['period_start_day'] = day;
        expect(Budget.fromJson(json).periodStartDay, day);
      }
    });

    test('a budget period start day outside 1 to 28 fails its assertion', () {
      expect(
        () => Budget(
          id: 'b',
          categoryId: 'c',
          period: BudgetPeriodKind.monthly,
          periodStartDay: 29,
          amount: _usd(1),
          rollover: false,
          startDate: LocalDate(2026, 10, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a budget needs its start date, as an ISO date', () {
      final Map<String, dynamic> json = _toJson(_entities[11].$2);
      expect(json['start_date'], '2026-09-25');
      expect(
        () => Budget.fromJson(Map.of(json)..remove('start_date')),
        throwsA(
          isA<CheckedFromJsonException>().having(
            (e) => e.key,
            'key',
            'start_date',
          ),
        ),
      );
      expect(
        () => Budget.fromJson(Map.of(json)..['start_date'] = '2026-02-30'),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });

  group('copyWith and equality', () {
    test('copyWith changes one field and keeps the rest', () {
      final transaction = _entities[5].$2 as Transaction;
      final edited = transaction.copyWith(notes: 'edited', merchantName: null);
      expect(edited.notes, 'edited');
      expect(edited.merchantName, isNull);
      expect(edited.amount, transaction.amount);
      expect(edited == transaction, isFalse);
      expect(
        edited.copyWith(notes: 'family plan', merchantName: 'Netflix'),
        transaction,
      );
    });

    test('collections compare by value', () {
      final a = _entities[5].$2 as Transaction;
      final b = a.copyWith(tags: ['subscription', 'shared']);
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
  });

  group('Hlc', () {
    test('orders by wall, counter, node', () {
      final hlcs = [
        Hlc(2, 0, 'a'),
        Hlc(1, 5, 'b'),
        Hlc(1, 5, 'a'),
        Hlc(1, 0, 'z'),
      ]..sort();
      expect(hlcs.map((h) => h.pack()), [
        '000000000000001-00000-z',
        '000000000000001-00005-a',
        '000000000000001-00005-b',
        '000000000000002-00000-a',
      ]);
    });

    test('parses its packed form, including a node id with dashes', () {
      final hlc = Hlc(1792854245123, 42, 'a-b-c');
      expect(Hlc.parse(hlc.pack()), hlc);
      expect(hlc.wall, DateTime.utc(2026, 10, 24, 15, 4, 5, 123));
      expect(hlc.wall.isUtc, isTrue);
    });

    test('rejects out-of-range values and bad packed strings', () {
      expect(() => Hlc(-1, 0, 'n'), throwsArgumentError);
      expect(() => Hlc(Hlc.maxWallMillis + 1, 0, 'n'), throwsArgumentError);
      expect(() => Hlc(0, Hlc.maxCounter + 1, 'n'), throwsArgumentError);
      expect(() => Hlc(0, 0, ''), throwsArgumentError);
      for (final node in ['a b', 'a\nb', 'n\t', 'ñ', 'a/b', 'a,b']) {
        expect(() => Hlc(0, 0, node), throwsArgumentError, reason: node);
      }
      expect(
        Hlc(0, 0, '3f2b8c1e-9d4a-4e7b-8f1a-2c3d4e5f6a7b').nodeId,
        hasLength(36),
      );
      expect(
        Hlc(0, 0, 'device_1.a:b').pack(),
        '000000000000000-00000-device_1.a:b',
      );
      for (final text in [
        '1-0-n',
        '000000000000001-00000-',
        'x',
        '000000000000001-00000-a b',
        '000000000000001-00000-a\n',
      ]) {
        expect(() => Hlc.parse(text), throwsFormatException, reason: text);
      }
    });
  });
}
