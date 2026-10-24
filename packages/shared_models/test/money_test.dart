// Tests for Money: construction, arithmetic, rounding, allocation, parsing, formatting
// and JSON. Locale expectations are written out with escapes for the invisible characters
// intl uses: U+00A0 no-break space, U+202F narrow no-break space, U+200E/U+200F/U+061C
// bidi marks.
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_models/src/money/rounding.dart' show divideRounded;
import 'package:test/test.dart';

Money usd(int cents) => Money(cents, 'USD');

void main() {
  group('construction', () {
    test('keeps minor units and code', () {
      final m = Money(-1234, 'USD');
      expect(m.minorUnits, -1234);
      expect(m.currencyCode, 'USD');
      expect(m.scale, 2);
    });

    test('rejects a code that is not three uppercase letters', () {
      for (final code in ['usd', 'US', 'USDX', 'U1D', '', 'US ']) {
        expect(() => Money(1, code), throwsArgumentError, reason: code);
      }
    });

    test('scales come from the ISO table', () {
      expect(Money.zero('JPY').scale, 0);
      expect(Money.zero('KWD').scale, 3);
      expect(Money.zero('CLF').scale, 4);
      expect(Money.zero('UYW').scale, 4);
    });

    test('an unknown well-formed code is allowed at two digits', () {
      expect(Currency.isKnown('ABC'), isFalse);
      expect(Currency.isKnown('USD'), isTrue);
      expect(Money(5, 'ABC').scale, 2);
      expect(Currency.isKnown('XAU'), isFalse, reason: 'N.A. minor unit');
    });

    test('zero', () {
      expect(Money.zero('EUR'), Money(0, 'EUR'));
      expect(Money.zero('EUR').isZero, isTrue);
    });
  });

  group('arithmetic', () {
    test('plus, minus, negate, abs', () {
      expect(usd(150) + usd(-50), usd(100));
      expect(usd(150) - usd(200), usd(-50));
      expect(-usd(7), usd(-7));
      expect(usd(-7).abs(), usd(7));
      expect(usd(7).abs(), usd(7));
    });

    test('sign predicates', () {
      expect(usd(-1).isNegative, isTrue);
      expect(usd(1).isPositive, isTrue);
      expect(usd(0).isPositive || usd(0).isNegative, isFalse);
      expect([usd(-3).sign, usd(0).sign, usd(3).sign], [-1, 0, 1]);
    });

    test('times and truncating division by an int', () {
      expect(usd(125) * 3, usd(375));
      expect(usd(125) * -2, usd(-250));
      expect(usd(1000) ~/ 3, usd(333));
      expect(usd(-1000) ~/ 3, usd(-333));
      expect(() => usd(1) ~/ 0, throwsArgumentError);
    });

    test('comparison', () {
      expect(usd(1) < usd(2), isTrue);
      expect(usd(2) <= usd(2), isTrue);
      expect(usd(3) > usd(2), isTrue);
      expect(usd(2) >= usd(3), isFalse);
      expect(usd(5).compareTo(usd(5)), 0);
      expect(Money.min(usd(4), usd(-4)), usd(-4));
      expect(Money.max(usd(4), usd(-4)), usd(4));
      expect([usd(3), usd(-1), usd(2)]..sort(), [usd(-1), usd(2), usd(3)]);
    });

    test('a currency mismatch throws with both codes', () {
      final eur = Money(1, 'EUR');
      void expectMismatch(Object? Function() f) => expect(
        f,
        throwsA(
          isA<CurrencyMismatchException>()
              .having((e) => e.left, 'left', 'USD')
              .having((e) => e.right, 'right', 'EUR'),
        ),
      );
      expectMismatch(() => usd(1) + eur);
      expectMismatch(() => usd(1) - eur);
      expectMismatch(() => usd(1) < eur);
      expectMismatch(() => usd(1).compareTo(eur));
      expectMismatch(() => Money.sum([usd(1), eur]));
      expectMismatch(() => Money.sum([eur], currencyCode: 'USD'));
    });

    test('equality and hash on both fields', () {
      expect(usd(1), Money(1, 'USD'));
      expect(usd(1).hashCode, Money(1, 'USD').hashCode);
      expect(usd(1) == Money(1, 'CAD'), isFalse);
      expect(usd(1) == usd(2), isFalse);
    });

    test('64-bit overflow throws a RangeError', () {
      const max = 0x7FFFFFFFFFFFFFFF;
      expect(() => usd(max) + usd(1), throwsRangeError);
      expect(() => usd(-max) - usd(1), throwsRangeError);
      expect(() => usd(-max) + usd(-1), throwsRangeError);
      expect(() => usd(max) * 2, throwsRangeError);
      expect(() => usd(-max) * 2, throwsRangeError);
      expect(() => usd(-0x4000000000000000) * 2, throwsRangeError);
      expect(() => usd(max).multipliedBy(3, 3), throwsRangeError);
      expect(() => usd(max).percent(2), throwsRangeError);
      expect(usd(max) - usd(max), usd(0));
      expect(-usd(-max), usd(max));
      expect(usd(-max).abs(), usd(max));
      expect(usd(-max) ~/ -1, usd(max));
    });

    test('the range is symmetric: -2^63 is not an amount', () {
      expect(() => usd(-0x8000000000000000), throwsArgumentError);
      expect(
        () => Money.fromJson({
          'minor_units': -0x8000000000000000,
          'currency': 'USD',
        }),
        throwsFormatException,
      );
      expect(
        () => Money.parse('-92233720368547758.08', 'USD'),
        throwsFormatException,
      );
    });

    test('sum', () {
      expect(Money.sum([usd(1), usd(2), usd(3)]), usd(6));
      expect(Money.sum(<Money>[], currencyCode: 'JPY'), Money.zero('JPY'));
      expect(Money.sum([usd(4)], currencyCode: 'USD'), usd(4));
      expect(() => Money.sum(<Money>[]), throwsArgumentError);
    });
  });

  group('rounding', () {
    // (numerator, denominator) -> expected per mode, at and around the half, both signs.
    const modes = RoundingMode.values;
    final cases = <(int, int), Map<RoundingMode, int>>{
      (5, 2): {
        RoundingMode.halfEven: 2,
        RoundingMode.halfUp: 3,
        RoundingMode.halfDown: 2,
        RoundingMode.up: 3,
        RoundingMode.down: 2,
        RoundingMode.ceiling: 3,
        RoundingMode.floor: 2,
      },
      (-5, 2): {
        RoundingMode.halfEven: -2,
        RoundingMode.halfUp: -3,
        RoundingMode.halfDown: -2,
        RoundingMode.up: -3,
        RoundingMode.down: -2,
        RoundingMode.ceiling: -2,
        RoundingMode.floor: -3,
      },
      (3, 2): {
        RoundingMode.halfEven: 2,
        RoundingMode.halfUp: 2,
        RoundingMode.halfDown: 1,
        RoundingMode.up: 2,
        RoundingMode.down: 1,
        RoundingMode.ceiling: 2,
        RoundingMode.floor: 1,
      },
      (-3, 2): {
        RoundingMode.halfEven: -2,
        RoundingMode.halfUp: -2,
        RoundingMode.halfDown: -1,
        RoundingMode.up: -2,
        RoundingMode.down: -1,
        RoundingMode.ceiling: -1,
        RoundingMode.floor: -2,
      },
      (1, 2): {
        RoundingMode.halfEven: 0,
        RoundingMode.halfUp: 1,
        RoundingMode.halfDown: 0,
        RoundingMode.up: 1,
        RoundingMode.down: 0,
        RoundingMode.ceiling: 1,
        RoundingMode.floor: 0,
      },
      (-1, 2): {
        RoundingMode.halfEven: 0,
        RoundingMode.halfUp: -1,
        RoundingMode.halfDown: 0,
        RoundingMode.up: -1,
        RoundingMode.down: 0,
        RoundingMode.ceiling: 0,
        RoundingMode.floor: -1,
      },
      (7, 3): {
        // 2.33: below the half
        RoundingMode.halfEven: 2,
        RoundingMode.halfUp: 2,
        RoundingMode.halfDown: 2,
        RoundingMode.up: 3,
        RoundingMode.down: 2,
        RoundingMode.ceiling: 3,
        RoundingMode.floor: 2,
      },
      (-8, 3): {
        // -2.67: above the half
        RoundingMode.halfEven: -3,
        RoundingMode.halfUp: -3,
        RoundingMode.halfDown: -3,
        RoundingMode.up: -3,
        RoundingMode.down: -2,
        RoundingMode.ceiling: -2,
        RoundingMode.floor: -3,
      },
      (6, 3): {for (final m in modes) m: 2},
      (-6, 3): {for (final m in modes) m: -2},
    };

    cases.forEach((input, expected) {
      final (n, d) = input;
      for (final mode in modes) {
        test('$n / $d by ${mode.name}', () {
          expect(divideRounded(n, d, mode), expected[mode]);
          // A negative denominator gives the same result as the negated fraction.
          expect(divideRounded(-n, -d, mode), expected[mode]);
        });
      }
    });

    test('a zero denominator is an ArgumentError', () {
      expect(
        () => divideRounded(1, 0, RoundingMode.halfEven),
        throwsArgumentError,
      );
      expect(() => usd(1).multipliedBy(1, 0), throwsArgumentError);
    });
  });

  group('multipliedBy and percent', () {
    test('rounds half to even by default', () {
      expect(usd(5).multipliedBy(1, 2), usd(2)); // 2.5 -> 2
      expect(usd(15).multipliedBy(1, 2), usd(8)); // 7.5 -> 8
      expect(usd(-15).multipliedBy(1, 2), usd(-8));
    });

    test('takes a mode', () {
      expect(usd(5).multipliedBy(1, 2, mode: RoundingMode.halfUp), usd(3));
      expect(usd(-5).multipliedBy(1, 2, mode: RoundingMode.floor), usd(-3));
      expect(usd(100).multipliedBy(1, 3, mode: RoundingMode.up), usd(34));
    });

    test('percent in basis points', () {
      expect(usd(10000).percent(250), usd(250)); // 2.5 % of 100.00
      expect(usd(1999).percent(825), usd(165)); // 164.9175 -> 165
      expect(usd(-1999).percent(825), usd(-165));
      expect(usd(1).percent(5000), usd(0)); // 0.5 -> 0, half even
      expect(usd(1).percent(5000, mode: RoundingMode.halfUp), usd(1));
    });
  });

  group('allocate and split', () {
    test('largest remainder, ties to the earlier weight', () {
      expect(usd(100).split(3), [usd(34), usd(33), usd(33)]);
      expect(usd(5).allocate([1, 1]), [usd(3), usd(2)]);
      expect(usd(100).allocate([1, 2]), [usd(33), usd(67)]);
      expect(usd(1000).allocate([3, 0, 7]), [usd(300), usd(0), usd(700)]);
    });

    test('a negative amount allocates its absolute value', () {
      expect(usd(-100).split(3), [usd(-34), usd(-33), usd(-33)]);
      expect(Money.sum(usd(-101).allocate([1, 1, 1, 4])), usd(-101));
    });

    test('rejects empty, negative and all-zero weights', () {
      expect(() => usd(1).allocate([]), throwsArgumentError);
      expect(() => usd(1).allocate([1, -1]), throwsArgumentError);
      expect(() => usd(1).allocate([0, 0]), throwsArgumentError);
      expect(() => usd(1).split(0), throwsArgumentError);
    });
  });

  group('string forms', () {
    test('toDecimalString at fixed scale', () {
      expect(usd(-123456).toDecimalString(), '-1234.56');
      expect(usd(5).toDecimalString(), '0.05');
      expect(usd(-5).toDecimalString(), '-0.05');
      expect(Money(-1234, 'JPY').toDecimalString(), '-1234');
      expect(Money(1, 'KWD').toDecimalString(), '0.001');
      expect(Money(12345, 'CLF').toDecimalString(), '1.2345');
    });

    test('toString is the debugging form', () {
      expect(usd(-1234).toString(), 'USD -12.34');
    });
  });

  group('parse', () {
    test('en_US decimal text', () {
      expect(Money.parse('1234.56', 'USD'), usd(123456));
      expect(Money.parse('-1,234.56', 'USD'), usd(-123456));
      expect(Money.parse('(1,234.56)', 'USD'), usd(-123456));
      expect(Money.parse('\$1,234.56', 'USD'), usd(123456));
      expect(Money.parse('-\$1,234.56', 'USD'), usd(-123456));
      expect(Money.parse('\$-12', 'USD'), usd(-1200));
      expect(Money.parse('(\$12.00)', 'USD'), usd(-1200));
      expect(Money.parse('USD 12.3', 'USD'), usd(1230));
      expect(Money.parse('12.3 USD', 'USD'), usd(1230));
      expect(Money.parse('+12', 'USD'), usd(1200));
      expect(Money.parse('\u221212', 'USD'), usd(-1200));
      expect(Money.parse('.5', 'USD'), usd(50));
      expect(Money.parse('  7  ', 'USD'), usd(700));
      expect(Money.parse('0', 'USD'), usd(0));
    });

    test('scale 0 and 3', () {
      expect(Money.parse('1,234', 'JPY'), Money(1234, 'JPY'));
      expect(Money.parse('\u00A51,234', 'JPY'), Money(1234, 'JPY'));
      expect(Money.parse('1.5', 'KWD'), Money(1500, 'KWD'));
      expect(Money.parse('-0.001', 'KWD'), Money(-1, 'KWD'));
    });

    test('de_DE', () {
      expect(
        Money.parse('1.234,56', 'EUR', locale: 'de_DE'),
        Money(123456, 'EUR'),
      );
      expect(
        Money.parse('-1.234,56\u00A0\u20AC', 'EUR', locale: 'de_DE'),
        Money(-123456, 'EUR'),
      );
      expect(
        Money.parse('1234,5 EUR', 'EUR', locale: 'de_DE'),
        Money(123450, 'EUR'),
      );
      // "1.234" is grouping in de_DE: one thousand two hundred thirty-four yen.
      expect(Money.parse('1.234', 'JPY', locale: 'de_DE'), Money(1234, 'JPY'));
    });

    test('fr_FR with narrow no-break space grouping and a typed space', () {
      expect(
        Money.parse('1\u202F234,56\u00A0\u20AC', 'EUR', locale: 'fr_FR'),
        Money(123456, 'EUR'),
      );
      expect(
        Money.parse('1 234,56', 'EUR', locale: 'fr_FR'),
        Money(123456, 'EUR'),
      );
    });

    test('rejects too many fraction digits rather than rounding', () {
      for (final (text, code, locale) in [
        ('1.234', 'USD', 'en_US'),
        ('1.230', 'USD', 'en_US'),
        ('1.5', 'JPY', 'en_US'),
        ('1.0', 'JPY', 'en_US'),
        ('0,0001', 'KWD', 'de_DE'),
      ]) {
        expect(
          () => Money.parse(text, code, locale: locale),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('rejects malformed text', () {
      for (final text in [
        '',
        '-',
        '()',
        '12.',
        '1.2.3',
        'abc',
        '\u20AC12',
        'EUR 12',
        '-(12)',
        '(-12)',
        '12-',
        '1 234',
        '12.3,4',
        '99999999999999999999',
        '92233720368547758.08',
        // Group separators only where en_US groups: 3-digit groups, a 1-3 digit lead.
        '12,50',
        ',5',
        '1,,000',
        '1,000,00',
        '1,0000',
        '1234,567',
        ',123',
        '123,',
        '1,234,5',
        '0.1,2',
        // A leading zero before a group separator is a decimal typed in the wrong locale.
        '0,001',
        '0,500',
        '00,500',
        // The currency's marks only at the ends.
        '1\$2',
        '1USD2',
        '12\$34.00',
        '\$\$12',
      ]) {
        expect(
          () => Money.parse(text, 'USD'),
          throwsFormatException,
          reason: text,
        );
      }
      for (final text in ['1,234.56', '12.50', '1.2345', '1..234']) {
        expect(
          () => Money.parse(text, 'EUR', locale: 'de_DE'),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('a zero whole part parses in each locale\'s own form', () {
      expect(Money.parse('0.50', 'USD', locale: 'en_US'), usd(50));
      expect(Money.parse('0', 'USD', locale: 'en_US'), usd(0));
      expect(Money.parse('0,50', 'EUR', locale: 'de_DE'), Money(50, 'EUR'));
      expect(
        () => Money.parse('0.500', 'EUR', locale: 'de_DE'),
        throwsFormatException,
      );
    });

    test('grouping follows the locale, en_IN included', () {
      expect(Money.parse('1,234,567.89', 'USD'), usd(123456789));
      expect(Money.parse('999,999', 'USD'), usd(99999900));
      expect(
        Money.parse('12,34,567.89', 'INR', locale: 'en_IN'),
        Money(123456789, 'INR'),
      );
      expect(
        Money.parse('12,345', 'INR', locale: 'en_IN'),
        Money(1234500, 'INR'),
      );
      expect(
        Money.parse('1,23,45,67,890', 'INR', locale: 'en_IN'),
        Money(123456789000, 'INR'),
      );
      for (final text in ['1,234,567', '123,456', '123,45,678']) {
        expect(
          () => Money.parse(text, 'INR', locale: 'en_IN'),
          throwsFormatException,
          reason: text,
        );
      }
      expect(
        () => Money.parse('1\u202F2\u202F345', 'EUR', locale: 'fr_FR'),
        throwsFormatException,
      );
    });

    test('parse and format share intl\'s default locale', () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = 'de_DE';
      final money = Money(1250, 'EUR');
      expect(money.format(), '12,50\u00A0\u20AC');
      expect(Money.parse(money.format(), 'EUR'), money);
      expect(Money.parse('1.234,56', 'EUR'), Money(123456, 'EUR'));
      expect(() => Money.parse('12.50', 'EUR'), throwsFormatException);
    });
  });

  group('format', () {
    test('en_US for 0, 2 and 3 digit currencies', () {
      expect(
        Money(-123456789, 'JPY').format(locale: 'en_US'),
        '-\u00A5123,456,789',
      );
      expect(usd(123456789).format(locale: 'en_US'), '\$1,234,567.89');
      expect(usd(-5).format(locale: 'en_US'), '-\$0.05');
      expect(Money(1234567, 'KWD').format(locale: 'en_US'), 'din1,234.567');
      expect(usd(0).format(locale: 'en_US'), '\$0.00');
    });

    test('de_DE', () {
      expect(
        Money(-123456789, 'JPY').format(locale: 'de_DE'),
        '-123.456.789\u00A0\u00A5',
      );
      expect(
        Money(123456789, 'EUR').format(locale: 'de_DE'),
        '1.234.567,89\u00A0\u20AC',
      );
      expect(
        Money(-1234567, 'KWD').format(locale: 'de_DE'),
        '-1.234,567\u00A0din',
      );
    });

    test('fr_FR', () {
      expect(
        Money(123456789, 'JPY').format(locale: 'fr_FR'),
        '123\u202F456\u202F789\u00A0\u00A5',
      );
      expect(
        Money(-123456789, 'EUR').format(locale: 'fr_FR'),
        '-1\u202F234\u202F567,89\u00A0\u20AC',
      );
      expect(
        Money(1234567, 'KWD').format(locale: 'fr_FR'),
        '1\u202F234,567\u00A0din',
      );
    });

    test('without the symbol', () {
      expect(usd(-123456).format(locale: 'en_US', symbol: false), '-1,234.56');
      expect(
        Money(123456, 'EUR').format(locale: 'de_DE', symbol: false),
        '1.234,56',
      );
    });

    test('showPlusSign mirrors the minus sign', () {
      expect(usd(1234).format(locale: 'en_US', showPlusSign: true), '+\$12.34');
      expect(
        usd(-1234).format(locale: 'en_US', showPlusSign: true),
        '-\$12.34',
      );
      expect(usd(0).format(locale: 'en_US', showPlusSign: true), '\$0.00');
      expect(
        Money(1234, 'EUR').format(locale: 'de_DE', showPlusSign: true),
        '+12,34\u00A0\u20AC',
      );
      expect(
        Money(1234, 'EUR').format(locale: 'nl', showPlusSign: true),
        '\u20AC\u00A0+12,34',
      );
      expect(Money(-1234, 'EUR').format(locale: 'nl'), '\u20AC\u00A0-12,34');
      // ps writes negatives in parentheses, so the plus sign leads the positive form.
      expect(
        Money(-5, 'EUR').format(locale: 'ps'),
        '(\u20AC\u06F0\u066B\u06F0\u06F5)',
      );
      expect(
        Money(5, 'EUR').format(locale: 'ps', showPlusSign: true),
        '\u200E+\u200E\u20AC\u06F0\u066B\u06F0\u06F5',
      );
    });

    test('localized digits in the fraction', () {
      expect(
        Money(-123456, 'EUR').format(locale: 'ar_EG'),
        '\u061C-\u200F\u0661\u066C\u0662\u0663\u0664\u066B\u0665\u0666\u00A0\u20AC',
      );
    });

    test('2^53 + 1 minor units format exactly', () {
      const big = 9007199254740993;
      expect(usd(big).format(locale: 'en_US'), '\$90,071,992,547,409.93');
      expect(
        Money(big, 'JPY').format(locale: 'en_US'),
        '\u00A59,007,199,254,740,993',
      );
      expect(
        Money(big, 'KWD').format(locale: 'de_DE'),
        '9.007.199.254.740,993\u00A0din',
      );
      expect(usd(-big).toDecimalString(), '-90071992547409.93');
      expect(Money.parse('90,071,992,547,409.93', 'USD'), usd(big));
    });

    test('the range limits format and parse at every scale', () {
      const max = 0x7FFFFFFFFFFFFFFF;
      expect(usd(-max).toDecimalString(), '-92233720368547758.07');
      expect(usd(-max).format(locale: 'en_US'), '-\$92,233,720,368,547,758.07');
      expect(
        Money(-max, 'JPY').format(locale: 'en_US'),
        '-\u00A59,223,372,036,854,775,807',
      );
      for (final code in ['JPY', 'USD', 'KWD', 'CLF']) {
        for (final minor in [max, -max]) {
          final money = Money(minor, code);
          expect(Money.parse(money.toDecimalString(), code), money);
          expect(
            Money.parse(money.format(locale: 'de_DE'), code, locale: 'de_DE'),
            money,
          );
        }
      }
    });

    test(
      'every intl locale agrees with intl on whole amounts and round-trips',
      () {
        for (final locale in numberFormatSymbols.keys.cast<String>()) {
          for (final code in ['JPY', 'USD', 'KWD']) {
            final scale = Money.zero(code).scale;
            final oracle = NumberFormat.simpleCurrency(
              locale: locale,
              name: code,
              decimalDigits: scale,
            );
            for (final whole in [0, 7, 1234567, -1234567]) {
              final money = Money(whole * _pow10(scale), code);
              expect(
                money.format(locale: locale),
                oracle.format(whole),
                reason: '$locale $code $whole',
              );
            }
            for (final minor in [123456789, -123456789, 5, -5, 0]) {
              final money = Money(minor, code);
              for (final plus in [false, true]) {
                for (final symbol in [true, false]) {
                  final text = money.format(
                    locale: locale,
                    symbol: symbol,
                    showPlusSign: plus,
                  );
                  expect(
                    Money.parse(text, code, locale: locale),
                    money,
                    reason: '$locale $code "$text"',
                  );
                }
              }
            }
          }
        }
      },
    );
  });

  group('JSON', () {
    test('round trip', () {
      final m = usd(-1234);
      expect(m.toJson(), {'minor_units': -1234, 'currency': 'USD'});
      expect(Money.fromJson(m.toJson()), m);
      const converter = MoneyConverter();
      expect(converter.fromJson(converter.toJson(m)), m);
    });

    test('rejects a non-integer minor_units', () {
      for (final value in [12.0, 12.5, '12', null]) {
        expect(
          () => Money.fromJson({'minor_units': value, 'currency': 'USD'}),
          throwsFormatException,
          reason: '$value',
        );
      }
    });

    test('rejects a malformed currency', () {
      for (final value in ['usd', 'US', 1, null]) {
        expect(
          () => Money.fromJson({'minor_units': 1, 'currency': value}),
          throwsFormatException,
          reason: '$value',
        );
      }
    });
  });
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}
