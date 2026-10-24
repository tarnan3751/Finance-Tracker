// The Sandbox outputs for one persona: the documented custom-user shape, Plaid's sign
// convention, the split between custom user and injection, and the interest switch.
import 'dart:convert';

import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

Map<String, Object?> _decode(String text) =>
    jsonDecode(text) as Map<String, Object?>;

List<Map<String, Object?>> _maps(Object? list) =>
    (list! as List<Object?>).cast<Map<String, Object?>>();

void main() {
  final asOf = LocalDate(2026, 10, 24);
  final student = generateHousehold(
    personaFor(PersonaId.student),
    seed: 1,
    asOf: asOf,
  );
  final family = generateHousehold(
    personaFor(PersonaId.family),
    seed: 1,
    asOf: asOf,
  );

  test('a custom user has the documented top level', () {
    final user = sandboxUsers(student).first;
    expect(user.config.keys, [
      'version',
      'seed',
      'roll_dates_forward',
      'override_accounts',
    ]);
    expect(user.config['roll_dates_forward'], isFalse);
    expect(user.config['version'], 2);
  });

  test("amounts are in Plaid's sign: positive is money out", () {
    final user = sandboxUsers(student).first;
    final json = _decode(writeJson(user.config));
    final checking = _maps(json['override_accounts']).first;
    final rent = _maps(checking['transactions'])
        .firstWhere((t) => t['description'] == 'COLLEGEVIEW APTS RENT');
    expect(rent['amount'], 725);
    final pay = _maps(checking['transactions'])
        .firstWhere((t) => t['description'] == 'STATE UNIV PAYROLL DIR DEP');
    expect(pay['amount'] as num, isNegative);
  });

  test('starting balances are the as-of balance, owed amounts positive', () {
    final user = sandboxUsers(student).first;
    final accounts = _maps(user.config['override_accounts']);
    final card = accounts.firstWhere((a) => a['type'] == 'credit');
    final cardAccount = student.accounts.firstWhere(
      (a) => a.type == AccountType.credit,
    );
    expect(
      (card['starting_balance']! as JsonDecimal).text,
      (-cardAccount.currentBalance!).toDecimalString(),
    );
    expect(
      (card['meta']! as Map<String, Object?>)['limit'],
      isA<JsonDecimal>(),
    );
    for (final a in accounts) {
      expect(a['identity'], accounts.first['identity']);
    }
  });

  test(
    'student loans: all in the custom user, none injected, liability student',
    () {
      final lender = sandboxUsers(student)
          .firstWhere((u) => u.split.institution.key == 'gingham');
      final loanTransactions = student.transactions.where(
        (t) => t.accountId.contains('loan_'),
      );
      expect(lender.split.customUser, containsAll(loanTransactions));
      expect(lender.split.injected, isEmpty);
      final liability = _maps(lender.config['override_accounts'])
          .first['liability'];
      expect((liability! as Map<String, Object?>)['type'], 'student');
    },
  );

  test('a mortgage carries no liability block; an auto loan a loan block', () {
    final users = sandboxUsers(family);
    final tartan = users.firstWhere((u) => u.split.institution.key == 'tartan');
    final mortgage = _maps(tartan.config['override_accounts']).single;
    expect(mortgage['subtype'], 'mortgage');
    expect(mortgage.containsKey('liability'), isFalse);
    final gingham = users.firstWhere(
      (u) => u.split.institution.key == 'gingham',
    );
    for (final auto in _maps(gingham.config['override_accounts'])) {
      final l = auto['liability']! as Map<String, Object?>;
      expect(l['type'], 'loan');
      expect(l['payment_frequency'], 'monthly');
    }
  });

  test('the brokerage carries holdings and recent buys', () {
    final users = sandboxUsers(family);
    final tattersall = users.firstWhere(
      (u) => u.split.institution.key == 'tattersall',
    );
    final account = _maps(tattersall.config['override_accounts']).single;
    expect(_maps(account['holdings']), hasLength(3));
    final buys = _maps(account['investment_transactions']);
    expect(
      buys.length,
      lessThanOrEqualTo(customUserInvestmentTransactionBudget),
    );
    expect(buys.map((b) => b['type']), everyElement('buy'));
  });

  test("injection is newest first, ten a call, on the generator's dates", () {
    final user = sandboxUsers(family)
        .firstWhere((u) => u.split.institution.key == 'platypus');
    final file = injectionFile(family, user);
    final batches = (file['batches']! as List<Object?>).cast<List<Object?>>();
    expect(batches, isNotEmpty);
    expect(batches.map((b) => b.length), everyElement(lessThanOrEqualTo(10)));
    final injected = user.split.injected;
    for (var i = 1; i < injected.length; i++) {
      expect(injected[i].date.isAfter(injected[i - 1].date), isFalse);
    }
    final newestInjected = injected.first.date;
    final oldestCustom = user.split.customUser.first.date;
    expect(newestInjected.isBefore(oldestCustom), isTrue);
    expect(file['as_of'], asOf.toIso());
    expect(file.containsKey('anchor_date'), isFalse);
    final first = batches.first.first! as Map<String, Object?>;
    expect(first.keys, [
      'date_transacted',
      'date_posted',
      'amount',
      'description',
      'iso_currency_code',
      'account',
    ]);
  });

  test('without interest legs the Sandbox outputs drop exactly the interest charges', () {
    final withLegs = splitForSandbox(family);
    final without = splitForSandbox(family, includeInterestLegs: false);
    int count(List<InstitutionSplit> s) =>
        s.fold(0, (n, x) => n + x.customUser.length + x.injected.length);
    expect(
      count(withLegs) - count(without),
      family.interestTransactionIds.length,
    );
    for (final s in without) {
      for (final t in [...s.customUser, ...s.injected]) {
        expect(family.interestTransactionIds, isNot(contains(t.id)));
      }
    }
  });

  test('the manifest records order, one shift for every Item, and pacing', () {
    final files = renderOutputs(
      PersonaId.renter,
      seed: 1,
      asOf: asOf,
      formats: {OutputFormat.injection},
      includeInterestLegs: false,
    );
    final manifest = _decode(files['injection_manifest.json']!);
    expect(manifest['order'], 'newest_first');
    expect(manifest['include_interest_legs'], isFalse);
    expect(
      (manifest['pacing']!
          as Map<String, Object?>)['interval_seconds_per_item'],
      35,
    );
    expect(manifest['as_of'], asOf.toIso());
    expect(manifest['date_shift'], contains('as_of'));
    final item = _maps(manifest['items']).single;
    expect(item.containsKey('anchor_date'), isFalse);
    expect(
      item['batch_count'],
      ((item['injected_transactions']! as int) + 9) ~/ 10,
    );
    expect(files.keys, ['injection_manifest.json', 'injection_platypus.json']);
  });
}
