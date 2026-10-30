// The transactions' CSV: the golden of a fixed household byte for byte, then the RFC 4180
// edge cases (commas, double quotes, CR, LF and CRLF in a field, non-ASCII text, empty
// optional fields), the amounts in currencies of 0, 2 and 3 minor digits, the filters by
// date range and account, the tombstones left out, the order by date then id, and a
// reader that parses the text back to the same fields.
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/features/export/domain/transactions_csv.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

final DateTime _at = DateTime.utc(2026, 10, 24, 12);

Account _account(String id, String name, String currency) => Account(
  id: id,
  type: AccountType.depository,
  name: name,
  currencyCode: currency,
  isHidden: false,
  displayOrder: 0,
);

Transaction _t(
  String id,
  String date,
  int minor, {
  String account = 'checking',
  String currency = 'USD',
  String name = 'Purchase',
  String? merchant,
  String? category,
  String? plaidCode,
  String? notes,
  List<String> tags = const [],
  bool pending = false,
  bool hidden = false,
  DataSource source = DataSource.manual,
  bool deleted = false,
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(minor, currency),
  date: LocalDate.parse(date),
  pending: pending,
  name: name,
  merchantName: merchant,
  userCategoryId: category,
  plaidDetailedCategory: plaidCode,
  notes: notes,
  tags: tags,
  hidden: hidden,
  source: source,
  createdAt: _at,
  updatedAt: _at,
  deletedAt: deleted ? _at : null,
  syncVersion: 0,
);

Category _category(String id, String name, {String? parent, String? code}) =>
    Category(
      id: id,
      name: name,
      parentId: parent,
      isSystem: code != null,
      icon: 'category',
      color: 0,
      plaidCategory: code,
    );

final Map<String, Account> _accounts = {
  'checking': _account('checking', 'Everyday Checking', 'USD'),
  'card': _account('card', 'Rewards Card, Visa', 'USD'),
  'yen': _account('yen', 'Tokyo Wallet', 'JPY'),
};

final CategoryLookup _lookup = categoryLookup([
  _category('food', 'Food'),
  _category('groceries', 'Groceries', parent: 'food'),
  _category('plaid:INCOME_WAGES', 'Wages', code: 'INCOME_WAGES'),
]);

/// The household the golden pins: a salary under a system category found by its Plaid
/// code, groceries under a child category, a hidden pending row, a refund, a yen and a
/// dinar row, notes that need quoting, tags, a deleted row and an uncategorized one.
final List<Transaction> household = [
  _t(
    'tx-03',
    '2026-10-05',
    -6042,
    merchant: 'Safeway',
    name: 'SAFEWAY #1234',
    category: 'groceries',
    tags: ['household', 'weekly'],
    notes: 'Milk, eggs and "the good bread"',
  ),
  _t(
    'tx-01',
    '2026-10-01',
    400000,
    name: 'ACME PAYROLL',
    merchant: 'Acme Corp',
    plaidCode: 'INCOME_WAGES',
    source: DataSource.plaid,
  ),
  _t(
    'tx-02',
    '2026-10-01',
    -165000,
    name: 'Rent',
    notes: 'October\r\nlate fee waived',
  ),
  _t(
    'tx-04',
    '2026-10-07',
    -1299,
    account: 'card',
    merchant: 'Café Olé',
    name: 'CAFE OLE',
    pending: true,
    hidden: true,
    category: 'food',
    source: DataSource.demo,
  ),
  _t(
    'tx-05',
    '2026-10-08',
    2500,
    account: 'card',
    name: 'Refund',
    notes: 'line one\nline two',
  ),
  _t(
    'tx-06',
    '2026-10-09',
    -1500,
    account: 'yen',
    currency: 'JPY',
    name: 'Ramen',
  ),
  _t('tx-07', '2026-10-09', -12345, currency: 'KWD', name: 'Dinar test'),
  _t('tx-08', '2026-10-10', -999, name: 'Gone', deleted: true),
  _t(
    'tx-09',
    '2026-10-10',
    -100,
    name: '=SUM(A1:A2)',
    merchant: '+cmd',
    source: DataSource.import,
  ),
];

// An RFC 4180 reader for the test: the records and their fields.
List<List<String>> _read(String text) {
  final List<List<String>> records = [];
  List<String> fields = [];
  final StringBuffer field = StringBuffer();
  int i = 0;
  while (i < text.length) {
    if (text[i] == '"') {
      i++;
      while (true) {
        if (text[i] == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i += 2;
          } else {
            i++;
            break;
          }
        } else {
          field.write(text[i++]);
        }
      }
    }
    if (text.startsWith('\r\n', i)) {
      fields.add(field.toString());
      field.clear();
      records.add(fields);
      fields = [];
      i += 2;
    } else if (text[i] == ',') {
      fields.add(field.toString());
      field.clear();
      i++;
    } else {
      field.write(text[i++]);
    }
  }
  expect(fields, isEmpty, reason: 'the last record ends in CRLF');
  return records;
}

void main() {
  test('the household matches the golden byte for byte', () {
    final List<int> bytes = utf8.encode(
      transactionsCsv(household, accounts: _accounts, lookup: _lookup),
    );
    final File golden = File('test/features/export/goldens/transactions.csv');
    if (autoUpdateGoldenFiles) golden.writeAsBytesSync(bytes);
    expect(bytes, golden.readAsBytesSync());
    // UTF-8 with no byte order mark.
    expect(bytes.take(3), isNot([0xEF, 0xBB, 0xBF]));
  });

  test('every record reads back to its fields', () {
    final List<List<String>> records = _read(
      transactionsCsv(household, accounts: _accounts, lookup: _lookup),
    );

    expect(records.first, transactionsCsvHeader);
    expect(
      [for (final r in records.skip(1)) r.last],
      ['tx-01', 'tx-02', 'tx-03', 'tx-04', 'tx-05', 'tx-06', 'tx-07', 'tx-09'],
    );
    expect(records.every((r) => r.length == 14), isTrue);
    final Map<String, List<String>> byId = {
      for (final r in records.skip(1)) r.last: r,
    };
    expect(byId['tx-01'], [
      '2026-10-01',
      'Everyday Checking',
      'Acme Corp',
      'ACME PAYROLL',
      '4000.00',
      'USD',
      'Wages',
      '',
      'false',
      'false',
      '',
      '',
      'plaid',
      'tx-01',
    ]);
    expect(byId['tx-02']![11], 'October\r\nlate fee waived');
    expect(byId['tx-03']!.sublist(6, 12), [
      'Groceries',
      'Food',
      'false',
      'false',
      'household;weekly',
      'Milk, eggs and "the good bread"',
    ]);
    expect(byId['tx-04']!.sublist(1, 10), [
      'Rewards Card, Visa',
      'Café Olé',
      'CAFE OLE',
      '-12.99',
      'USD',
      'Food',
      '',
      'true',
      'true',
    ]);
    expect(byId['tx-05']![4], '25.00');
    expect(byId['tx-05']![11], 'line one\nline two');
    expect(byId['tx-06']!.sublist(4, 6), ['-1500', 'JPY']);
    expect(byId['tx-07']!.sublist(4, 6), ['-12.345', 'KWD']);
    // Not mangled: a leading = or + stays as stored (PLAN.md §12 "6f plan rulings").
    expect(byId['tx-09']!.sublist(2, 4), ['+cmd', '=SUM(A1:A2)']);
  });

  test('a field is quoted only when it needs to be', () {
    expect(csvField('plain text'), 'plain text');
    expect(csvField(''), '');
    expect(csvField('a,b'), '"a,b"');
    expect(csvField('say "hi"'), '"say ""hi"""');
    expect(csvField('cr\ronly'), '"cr\ronly"');
    expect(csvField('lf\nonly'), '"lf\nonly"');
    expect(csvField(' spaced '), ' spaced ');
    expect(csvField('-12.34'), '-12.34');
  });

  test('the range and the accounts filter the rows', () {
    List<String> ids(String csv) => [
      for (final r in _read(csv).skip(1)) r.last,
    ];

    expect(
      ids(
        transactionsCsv(
          household,
          accounts: _accounts,
          lookup: _lookup,
          range: LocalDateRange(
            LocalDate.parse('2026-10-05'),
            LocalDate.parse('2026-10-09'),
          ),
        ),
      ),
      ['tx-03', 'tx-04', 'tx-05'],
    );
    expect(
      ids(
        transactionsCsv(
          household,
          accounts: _accounts,
          lookup: _lookup,
          accountIds: {'card', 'yen'},
        ),
      ),
      ['tx-04', 'tx-05', 'tx-06'],
    );
    expect(
      transactionsCsv(
        household,
        accounts: _accounts,
        lookup: _lookup,
        accountIds: const {},
      ),
      '${transactionsCsvHeader.join(',')}\r\n',
    );
  });

  test('an account or a category that is gone writes an empty field', () {
    final List<List<String>> records = _read(
      transactionsCsv(
        [_t('x', '2026-10-01', -100, account: 'closed', category: 'deleted')],
        accounts: _accounts,
        lookup: _lookup,
      ),
    );

    expect(records[1].sublist(1, 2), ['']);
    expect(records[1].sublist(6, 8), ['', '']);
  });

  test('the order does not depend on the input order', () {
    final String forward = transactionsCsv(
      household,
      accounts: _accounts,
      lookup: _lookup,
    );
    final String backward = transactionsCsv(
      household.reversed,
      accounts: _accounts,
      lookup: _lookup,
    );

    expect(backward, forward);
  });
}
