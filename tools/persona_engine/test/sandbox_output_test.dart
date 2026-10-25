// The Sandbox outputs for one persona: the documented custom-user shape, Plaid's sign
// convention, the cut of the newest whole days under the request budget, the manifest,
// and the interest switch.
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

  test('the date shift moves every date of a custom user and nothing else', () {
    final date = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');
    for (final household in [student, family]) {
      for (final user in sandboxUsers(household)) {
        final before = writeJson(user.config);
        final shifted = shiftSandboxUserDates(user.config, 17);
        expect(writeJson(user.config), before, reason: 'the input is kept');
        var dates = 0;
        void compare(Object? a, Object? b, String path) {
          switch (a) {
            case final Map<String, Object?> m:
              final other = b! as Map<String, Object?>;
              expect(other.keys, m.keys, reason: path);
              for (final key in m.keys) {
                compare(m[key], other[key], '$path.$key');
              }
            case final List<Object?> l:
              final other = b! as List<Object?>;
              expect(other, hasLength(l.length), reason: path);
              for (var i = 0; i < l.length; i++) {
                compare(l[i], other[i], '$path[$i]');
              }
            case final String s when date.hasMatch(s):
              dates++;
              expect(b, LocalDate.parse(s).addDays(17).toIso(), reason: path);
            case final JsonDecimal d:
              expect((b! as JsonDecimal).text, d.text, reason: path);
            default:
              expect(b, a, reason: path);
          }
        }

        compare(user.config, shifted, r'$');
        expect(dates, greaterThan(0));
      }
    }
  });

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

  test("a student loan's custom user carries a student liability", () {
    final lender = sandboxUsers(student)
        .firstWhere((u) => u.split.institution.key == 'gingham');
    final liability = _maps(lender.config['override_accounts'])
        .first['liability'];
    expect((liability! as Map<String, Object?>)['type'], 'student');
  });

  test('neither a mortgage nor an auto loan carries a liability block; the demo seed '
      'keeps both liabilities', () {
    final loans = <String>[];
    for (final user in sandboxUsers(family)) {
      for (final account in _maps(user.config['override_accounts'])) {
        if (account['type'] != 'loan') continue;
        loans.add(account['subtype']! as String);
        expect(account.containsKey('liability'), isFalse, reason: '$account');
      }
    }
    expect(loans, containsAll(['mortgage', 'auto', 'auto']));
    final kinds = [
      for (final l in family.liabilities)
        if (l is LoanLiability) l.kind,
    ];
    expect(
      kinds,
      containsAll([LoanKind.mortgage, LoanKind.auto, LoanKind.auto]),
    );
  });

  test('the brokerage carries holdings and recent buys', () {
    final users = sandboxUsers(family);
    final tartan = users.firstWhere((u) => u.split.institution.key == 'tartan');
    final account = _maps(tartan.config['override_accounts']).single;
    expect(_maps(account['holdings']), hasLength(3));
    final buys = _maps(account['investment_transactions']);
    expect(
      buys.length,
      lessThanOrEqualTo(customUserInvestmentTransactionBudget),
    );
    expect(buys.map((b) => b['type']), everyElement('buy'));
  });

  test('the cut keeps the newest whole days that fit, and no more', () {
    const most = 100;
    final splits = splitForSandbox(
      family,
      fits: (_, carried) => carried.length <= most,
    );
    final platypus = splits.firstWhere((s) => s.institution.key == 'platypus');
    final kept = platypus.customUser;
    final left = platypus.leftOut;
    expect(kept.length, lessThanOrEqualTo(most));
    expect(left, isNotEmpty);
    // Whole days and the newest: the newest left-out day is older than every kept one.
    expect(left.first.date.isBefore(kept.first.date), isTrue);
    expect(kept.last.date, asOf);
    // The next day would not fit.
    final nextDay = left.takeWhile((t) => t.date == left.first.date).length;
    expect(kept.length + nextDay, greaterThan(most));
    // Oldest first in the custom user, newest first left out.
    for (var i = 1; i < kept.length; i++) {
      expect(kept[i].id.compareTo(kept[i - 1].id), greaterThan(0));
    }
    for (var i = 1; i < left.length; i++) {
      expect(left[i].date.isAfter(left[i - 1].date), isFalse);
    }
    // An institution whose history fits keeps all of it.
    final gingham = splits.firstWhere((s) => s.institution.key == 'gingham');
    expect(gingham.leftOut, isEmpty);
  });

  test(
    'a custom user is within the request budget, and one more day is over it',
    () {
      var cut = 0;
      for (final household in [student, family]) {
        for (final user in sandboxUsers(household)) {
          expect(
            sandboxRequestBytes(user.config),
            lessThanOrEqualTo(sandboxConfigByteBudget),
          );
          final left = user.split.leftOut;
          if (left.isEmpty) continue;
          cut++;
          final day = left.first.date;
          final more = [
            ...left.where((t) => t.date == day),
            ...user.split.customUser,
          ]..sort((a, b) => a.id.compareTo(b.id));
          expect(
            sandboxRequestBytes(
              sandboxUserConfig(household, user.split.institution, more),
            ),
            greaterThan(sandboxConfigByteBudget),
          );
        }
      }
      expect(cut, greaterThan(0));
    },
  );

  test('the request bytes are the configuration as a JSON string', () {
    final user = sandboxUsers(student).first;
    final compact = writeJson(user.config, pretty: false);
    final bytes = sandboxRequestBytes(user.config);
    // Each quote in the configuration gains a backslash; the string gains two quotes.
    expect(bytes, compact.length + '"'.allMatches(compact).length + 2);
  });

  test('without interest legs the Sandbox outputs drop exactly the interest charges', () {
    bool all(InstitutionSpec _, List<Transaction> _) => true;
    final withLegs = splitForSandbox(family, fits: all);
    final without = splitForSandbox(
      family,
      fits: all,
      includeInterestLegs: false,
    );
    int count(List<InstitutionSplit> s) =>
        s.fold(0, (n, x) => n + x.customUser.length + x.leftOut.length);
    expect(
      count(withLegs) - count(without),
      family.interestTransactionIds.length,
    );
    for (final s in without) {
      for (final t in [...s.customUser, ...s.leftOut]) {
        expect(family.interestTransactionIds, isNot(contains(t.id)));
      }
    }
  });

  test(
    'the manifest records the shift, the budget and what each Item carries',
    () {
      final files = renderOutputs(
        PersonaId.family,
        seed: 1,
        asOf: asOf,
        formats: {OutputFormat.sandboxUser},
        includeInterestLegs: false,
      );
      expect(files.keys, [
        'sandbox_manifest.json',
        'sandbox_user_gingham.json',
        'sandbox_user_platypus.json',
        'sandbox_user_tartan.json',
        'sandbox_user_tattersall.json',
      ]);
      final manifest = _decode(files['sandbox_manifest.json']!);
      expect(manifest['include_interest_legs'], isFalse);
      expect(manifest['as_of'], asOf.toIso());
      expect(manifest['date_shift'], contains('as_of'));
      expect(manifest['request_byte_budget'], sandboxConfigByteBudget);
      expect(manifest.containsKey('pacing'), isFalse);
      final users = sandboxUsers(family, includeInterestLegs: false);
      final items = _maps(manifest['items']);
      expect(items, hasLength(users.length));
      for (final (i, item) in items.indexed) {
        final split = users[i].split;
        expect(item['institution'], split.institution.key);
        expect(
          item['sandbox_user_file'],
          'sandbox_user_${split.institution.key}.json',
        );
        expect(item['custom_user_transactions'], split.customUser.length);
        expect(item['transactions_left_out'], split.leftOut.length);
        if (split.customUser.isEmpty) {
          expect(item['first_day_carried'], isNull);
          expect(item['days_carried'], 0);
        } else {
          final first = split.customUser.first.date;
          expect(item['first_day_carried'], first.toIso());
          expect(item['days_carried'], first.daysUntil(asOf) + 1);
        }
      }
      final platypus = items.firstWhere((i) => i['institution'] == 'platypus');
      expect(platypus['transactions_left_out'], greaterThan(0));
      expect(platypus['days_carried'], lessThan(maxWindowDays));
    },
  );
}
