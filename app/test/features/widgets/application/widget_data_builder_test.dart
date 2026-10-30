// The home screen widgets' snapshot from fixed inputs: net worth from the observed series
// in the device's currency when held, labelled observed or estimated; the three largest
// visible accounts by their balance as shown; budgets over-limit first, then by fill;
// the next unpaid bills missed first; every amount formatted in the device's locale, the
// footer in the clock's zone; and the empty lists of an install with nothing yet.
import 'dart:convert';

import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/widgets/application/widget_data_builder.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:finance_tracker/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final LocalDate _today = LocalDate(2026, 10, 24);
final DateTime _now = DateTime.utc(2026, 10, 24, 21, 41);
final AppLocalizations _l10n = AppLocalizationsEn();

Money _usd(int cents) => Money(cents, 'USD');

Account _account(
  String id, {
  int order = 0,
  String? itemId,
  Money? reported,
  bool hidden = false,
  AccountType type = AccountType.depository,
}) => Account(
  id: id,
  itemId: itemId,
  type: type,
  name: 'Account $id',
  currencyCode: 'USD',
  currentBalance: reported,
  isHidden: hidden,
  displayOrder: order,
);

BudgetStatus _budget(String id, int spent, int available) {
  final Money s = _usd(spent);
  final Money a = _usd(available);
  return BudgetStatus(
    budget: Budget(
      id: id,
      categoryId: 'cat-$id',
      period: BudgetPeriodKind.monthly,
      periodStartDay: 1,
      amount: a,
      rollover: false,
      startDate: LocalDate(2026, 1, 1),
    ),
    period: LocalDateRange(LocalDate(2026, 10, 1), LocalDate(2026, 11, 1)),
    spent: s,
    carried: _usd(0),
    available: a,
    remaining: a - s,
    progress: Ratio.of(s, a),
    elapsedDays: 24,
    projected: s,
    projectedOverspend: false,
    thresholdsCrossed: const [],
  );
}

Category _category(String id) => Category(
  id: 'cat-$id',
  name: 'Budget $id',
  isSystem: false,
  icon: 'category',
  color: 0xFF000000,
);

BillStatus _bill(
  String id,
  LocalDate due, {
  int? cents,
  bool active = true,
  List<LocalDate> paid = const [],
}) => billStatus(
  BillReminder(
    id: id,
    name: 'Bill $id',
    amount: cents == null ? null : _usd(cents),
    dueDate: due,
    active: active,
    paidOccurrences: paid,
  ),
  _today,
);

WidgetData _build({
  List<Account> accounts = const [],
  Map<String, Money?> derived = const {},
  Map<String, List<NetWorthPoint>> netWorth = const {},
  List<BudgetStatus> budgets = const [],
  List<BillStatus> bills = const [],
  String deviceCurrency = 'USD',
  bool locked = false,
}) => buildWidgetData(
  accounts: accounts,
  derived: derived,
  netWorth: netWorth,
  budgets: budgets,
  categories: {
    for (final BudgetStatus b in budgets)
      b.budget.categoryId: _category(b.budget.id),
  },
  bills: bills,
  payments: const {},
  streamNames: const {},
  today: _today,
  now: _now,
  location: tz.getLocation('America/New_York'),
  deviceCurrency: deviceCurrency,
  locked: locked,
  l10n: _l10n,
);

NetWorthPoint _point(
  int assets, {
  String currency = 'USD',
  bool derived = false,
}) => NetWorthPoint(
  date: _today,
  assets: Money(assets, currency),
  liabilities: Money(0, currency),
  derived: derived,
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    await initializeDateFormatting('de_DE');
  });

  setUp(() => Intl.defaultLocale = 'en_US');

  test('nothing yet: signed in, every list empty, the footer in the zone', () {
    final WidgetData data = _build();
    expect(data.signedIn, isTrue);
    expect(data.netWorth, isNull);
    expect(data.accounts, isEmpty);
    expect(data.budgets, isEmpty);
    expect(data.bills, isEmpty);
    expect(data.updatedAt, _now);
    // 21:41 UTC is 5:41 PM in New York in October (EDT).
    expect(data.updatedText, 'Updated 5:41 PM');
  });

  group('net worth', () {
    test('the latest point in the device currency, observed', () {
      final WidgetData data = _build(
        netWorth: {
          'EUR': [_point(999, currency: 'EUR')],
          'USD': [_point(100), _point(1234567)],
        },
      );
      expect(data.netWorth!.amount, _usd(1234567));
      expect(data.netWorth!.text, r'$12,345.67');
      expect(data.netWorth!.estimated, isFalse);
      expect(data.netWorth!.basisText, 'From account balances');
      expect(
        data.netWorth!.spokenText,
        r'Net worth $12,345.67, From account balances',
      );
    });

    test('the first currency held when the device\'s is not; estimated', () {
      final WidgetData data = _build(
        netWorth: {
          'GBP': [_point(500, currency: 'GBP', derived: true)],
          'EUR': [_point(700, currency: 'EUR', derived: true)],
        },
      );
      expect(data.netWorth!.amount, Money(700, 'EUR'));
      expect(data.netWorth!.estimated, isTrue);
      expect(data.netWorth!.basisText, 'Estimated from transactions');
    });
  });

  test('accounts: the three largest visible by absolute balance as shown', () {
    final WidgetData data = _build(
      accounts: [
        _account('a', order: 0),
        _account('b', order: 1, itemId: 'item', reported: _usd(-90000)),
        _account('c', order: 2),
        _account('d', order: 3),
        _account('hidden', order: 4, hidden: true),
      ],
      derived: {
        'a': _usd(5000),
        'c': _usd(70000),
        'd': _usd(5000),
        'hidden': _usd(10000000),
      },
    );
    expect([for (final a in data.accounts) a.id], ['b', 'c', 'a']);
    final WidgetAccount card = data.accounts.first;
    expect(card.balance, _usd(-90000));
    expect(card.text, r'-$900.00');
    expect(card.reported, isTrue);
    expect(card.basisText, 'reported');
    expect(card.spokenText, r'Account b, -$900.00, reported');
    expect(data.accounts[1].basisText, 'from transactions');
  });

  test(
    'accounts: the device currency\'s first by size, then the others by name',
    () {
      Account foreign(String id, String name) => Account(
        id: id,
        type: AccountType.depository,
        name: name,
        currencyCode: 'EUR',
        isHidden: false,
        displayOrder: 0,
      );
      final WidgetData data = _build(
        accounts: [
          foreign('eur-big', 'Zürich savings'),
          foreign('eur-small', 'Berlin checking'),
          _account('usd-small', order: 1),
          _account('usd-big', order: 2),
        ],
        derived: {
          'eur-big': Money(99999999, 'EUR'),
          'eur-small': Money(100, 'EUR'),
          'usd-small': _usd(100),
          'usd-big': _usd(50000),
        },
      );
      expect(
        [for (final a in data.accounts) a.id],
        ['usd-big', 'usd-small', 'eur-small'],
      );
      expect(
        _build(
          accounts: [
            foreign('eur-big', 'Zürich savings'),
            foreign('eur-small', 'Berlin checking'),
          ],
          derived: {
            'eur-big': Money(99999999, 'EUR'),
            'eur-small': Money(100, 'EUR'),
          },
        ).accounts.map((a) => a.id),
        ['eur-small', 'eur-big'],
      );
    },
  );

  test('budgets: over-limit first, then by fill, as the card shows them', () {
    final WidgetData data = _build(
      budgets: [
        _budget('half', 5000, 10000),
        _budget('over', 12000, 10000),
        _budget('nothing', 100, 0),
        _budget('most', 9000, 10000),
      ],
    );
    expect([for (final b in data.budgets) b.id], ['over', 'nothing', 'most']);
    final WidgetBudget over = data.budgets[0];
    expect(over.over, isTrue);
    expect(over.fillBasisPoints, 10000);
    expect(over.percentText, '120 %');
    expect(over.detailText, r'$20.00 over');
    expect(
      over.spokenText,
      r'Budget over: 120 percent of $100.00 spent, $20.00 over',
    );
    final WidgetBudget nothing = data.budgets[1];
    expect(nothing.over, isTrue);
    expect(nothing.fillBasisPoints, 10000);
    expect(nothing.percentText, 'Nothing available');
    final WidgetBudget most = data.budgets[2];
    expect(most.over, isFalse);
    expect(most.fillBasisPoints, 9000);
    expect(most.detailText, r'$10.00 left');
  });

  test('bills: unpaid active ones, missed first, then by due date', () {
    final WidgetData data = _build(
      bills: [
        _bill('later', LocalDate(2026, 11, 20), cents: -5000),
        _bill('soon', LocalDate(2026, 10, 25), cents: -150000),
        _bill('missed', LocalDate(2026, 10, 10)),
        _bill('paused', LocalDate(2026, 10, 26), active: false),
        _bill('paid', LocalDate(2026, 10, 26), paid: [LocalDate(2026, 10, 26)]),
        _bill('fourth', LocalDate(2026, 12, 1)),
      ],
    );
    expect([for (final b in data.bills) b.id], ['missed', 'soon', 'later']);
    final WidgetBill missed = data.bills[0];
    expect(missed.overdue, isTrue);
    expect(missed.due, LocalDate(2026, 10, 10));
    expect(missed.dueText, 'Missed, Due Oct 10');
    expect(missed.amountText, isNull);
    expect(missed.spokenText, 'Bill missed, Missed, Due Oct 10');
    final WidgetBill soon = data.bills[1];
    expect(soon.dueText, 'Due tomorrow');
    expect(soon.amount, _usd(150000));
    expect(soon.amountText, r'$1,500.00');
    expect(soon.spokenText, r'Bill soon, Due tomorrow, $1,500.00');
    expect(data.bills[2].dueText, 'Due Nov 20');
  });

  test('money and dates follow the device locale', () {
    Intl.defaultLocale = 'de_DE';
    addTearDown(() => Intl.defaultLocale = 'en_US');
    final WidgetData data = _build(
      netWorth: {
        'USD': [_point(1234567)],
      },
      bills: [_bill('later', LocalDate(2026, 11, 20), cents: -5000)],
    );
    expect(data.netWorth!.text, '12.345,67 \$');
    expect(data.bills.single.amountText, '50,00 \$');
    expect(data.bills.single.dueText, 'Due 20. Nov.');
  });

  test('the snapshot JSON holds what the Kotlin side reads', () {
    final WidgetData data = _build(
      accounts: [_account('a')],
      derived: {'a': _usd(5000)},
      netWorth: {
        'USD': [_point(5000)],
      },
      budgets: [_budget('half', 5000, 10000)],
      bills: [_bill('soon', LocalDate(2026, 10, 25), cents: -150000)],
    );
    final Map<String, Object?> json = data.toJson();
    expect(json['v'], widgetSnapshotVersion);
    expect(json['locked'], isFalse);
    expect(json['signed_in'], isTrue);
    expect(json['updated'], 'Updated 5:41 PM');
    expect(json['updated_at'], '2026-10-24T21:41:00.000Z');
    expect(json['net_worth'], {
      'minor': 5000,
      'currency': 'USD',
      'text': r'$50.00',
      'estimated': false,
      'basis': 'From account balances',
      'spoken': r'Net worth $50.00, From account balances',
    });
    expect((json['accounts']! as List).single, {
      'id': 'a',
      'name': 'Account a',
      'minor': 5000,
      'currency': 'USD',
      'text': r'$50.00',
      'reported': false,
      'basis': 'from transactions',
      'spoken': r'Account a, $50.00, from transactions',
    });
    expect((json['budgets']! as List).single, {
      'id': 'half',
      'name': 'Budget half',
      'spent_minor': 5000,
      'available_minor': 10000,
      'currency': 'USD',
      'fill_bp': 5000,
      'over': false,
      'percent': '50 %',
      'detail': r'$50.00 left',
      'spoken': r'Budget half: 50 percent of $100.00 spent, $50.00 left',
    });
    expect((json['bills']! as List).single, {
      'id': 'soon',
      'name': 'Bill soon',
      'due': '2026-10-25',
      'due_text': 'Due tomorrow',
      'overdue': false,
      'minor': 150000,
      'currency': 'USD',
      'amount': r'$1,500.00',
      'spoken': r'Bill soon, Due tomorrow, $1,500.00',
    });
  });

  test('locked: flagged, and every spoken sentence hides its amount', () {
    final WidgetData data = _build(
      locked: true,
      accounts: [_account('a')],
      derived: {'a': _usd(5000)},
      netWorth: {
        'USD': [_point(5000)],
      },
      budgets: [_budget('half', 5000, 10000)],
      bills: [
        _bill('soon', LocalDate(2026, 10, 25), cents: -150000),
        _bill('bare', LocalDate(2026, 10, 26)),
      ],
    );
    expect(data.locked, isTrue);
    expect(data.toJson()['locked'], isTrue);
    expect(
      data.netWorth!.spokenText,
      'Net worth, hidden while the app is locked',
    );
    expect(
      data.accounts.single.spokenText,
      'Account a, balance hidden while the app is locked',
    );
    expect(
      data.budgets.single.spokenText,
      'Budget half, spending hidden while the app is locked',
    );
    expect(
      data.bills.first.spokenText,
      'Bill soon, Due tomorrow, amount hidden while the app is locked',
    );
    expect(data.bills.last.spokenText, 'Bill bare, Due in 2 days');
    final String json = jsonEncode(data.toJson());
    for (final String spoken in [
      for (final a in data.accounts) a.spokenText,
      for (final b in data.budgets) b.spokenText,
      for (final b in data.bills) b.spokenText,
      data.netWorth!.spokenText,
    ]) {
      expect(spoken, isNot(contains(r'$')), reason: spoken);
    }
    expect(json, contains('"locked":true'));
    // The stored snapshot holds no amount: no minor units, no currency, no digit in any
    // amount field, no fill.
    final Map<String, Object?> stored = data.toJson();
    final List<Map<String, Object?>> rows = [
      stored['net_worth']! as Map<String, Object?>,
      for (final String list in ['accounts', 'budgets', 'bills'])
        for (final Object? row in stored[list]! as List<Object?>)
          row! as Map<String, Object?>,
    ];
    for (final Map<String, Object?> row in rows) {
      for (final String key in [
        'minor',
        'spent_minor',
        'available_minor',
        'currency',
        'percent',
        'detail',
      ]) {
        expect(row[key], isNull, reason: '$key in $row');
      }
      for (final String key in ['text', 'amount']) {
        final Object? value = row[key];
        if (value != null) expect(value, widgetMask, reason: '$key in $row');
      }
      if (row.containsKey('fill_bp')) expect(row['fill_bp'], 0);
      if (row.containsKey('over')) expect(row['over'], isFalse);
    }
    expect(json, isNot(contains(r'$')));
    expect(json, isNot(contains('USD')));
  });

  test('locked: accounts and budgets by name, bills by due date alone', () {
    final WidgetData data = _build(
      locked: true,
      accounts: [
        _account('c', order: 0),
        _account('a', order: 1),
        _account('d', order: 2),
        _account('b', order: 3),
      ],
      derived: {
        'a': _usd(100),
        'b': _usd(900000),
        'c': _usd(500000),
        'd': _usd(700000),
      },
      budgets: [
        _budget('zeta', 12000, 10000),
        _budget('alpha', 100, 10000),
        _budget('mid', 9000, 10000),
        _budget('beta', 5000, 10000),
      ],
      bills: [
        _bill('later', LocalDate(2026, 11, 20), cents: -5000),
        _bill('soon', LocalDate(2026, 10, 25), cents: -150000),
        _bill('missed', LocalDate(2026, 10, 10)),
      ],
    );
    expect([for (final a in data.accounts) a.id], ['a', 'b', 'c']);
    expect([for (final b in data.budgets) b.id], ['alpha', 'beta', 'mid']);
    expect([for (final b in data.bills) b.id], ['missed', 'soon', 'later']);
    final WidgetData nearer = _build(
      locked: true,
      bills: [
        _bill('missed', LocalDate(2026, 10, 10)),
        _bill('earlier-one-off', LocalDate(2026, 9, 1)),
      ],
    );
    expect(
      nearer.bills.map((b) => b.due),
      [for (final b in nearer.bills) b.due]..sort(),
    );
  });

  test('unlocked by default; the signed-out snapshot is never locked', () {
    expect(_build().locked, isFalse);
    expect(
      WidgetData.signedOut(updatedAt: _now, updatedText: '').locked,
      isFalse,
    );
  });

  test('the signed-out snapshot holds nothing but its time', () {
    final Map<String, Object?> json = WidgetData.signedOut(
      updatedAt: _now,
      updatedText: 'Updated 5:41 PM',
    ).toJson();
    expect(json['signed_in'], isFalse);
    expect(json['net_worth'], isNull);
    expect(json['accounts'], isEmpty);
    expect(json['budgets'], isEmpty);
    expect(json['bills'], isEmpty);
  });
}
