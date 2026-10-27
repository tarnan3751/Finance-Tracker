// The subscription classifier on worked examples (docs/reference/recurring.md,
// **Subscriptions**).
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/recurring/domain/subscription_classifier.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Money usd(int minor) => Money(minor, 'USD');
final CategoryLookup lookup = categoryLookup(systemCategories);
final Map<String, Category> byCode = lookup.byPlaidCode;

RecurringStream stream({
  String id = 's1',
  String account = 'acc-1',
  String merchant = 'Netflix',
  RecurringCadence cadence = RecurringCadence.monthly,
  int minor = -1549,
  bool flagged = false,
  RecurringSource source = RecurringSource.detected,
  List<String> ids = const [],
}) => RecurringStream(
  id: id,
  accountId: account,
  merchantName: merchant,
  cadence: cadence,
  averageAmount: usd(minor),
  status: RecurringStatus.active,
  isSubscription: flagged,
  source: source,
  transactionIds: ids,
);

StreamBand band(int median, int min, int max) =>
    StreamBand(median: usd(median), min: usd(min), max: usd(max));

Transaction tx(String id, LocalDate date, {String? code, String? user}) {
  final DateTime at = DateTime.utc(2026);
  return Transaction(
    id: id,
    accountId: 'acc-1',
    amount: usd(-1549),
    date: date,
    pending: false,
    name: 'NETFLIX.COM',
    plaidDetailedCategory: code,
    userCategoryId: user,
    source: DataSource.import,
    createdAt: at,
    updatedAt: at,
    syncVersion: 0,
  );
}

void main() {
  group('isSubscription', () {
    final Category tv = byCode['ENTERTAINMENT_TV_AND_MOVIES']!;
    final StreamBand fixed = band(-1549, -1549, -1549);

    test('a stable monthly outflow in an ordinary category is one', () {
      expect(
        isSubscription(stream(), effectiveCategory: tv, band: fixed),
        isTrue,
      );
      expect(
        isSubscription(stream(), effectiveCategory: null, band: fixed),
        isTrue,
      );
    });

    test('the band holds at 5 % of the median and not past it', () {
      expect(
        isSubscription(
          stream(minor: -10000),
          effectiveCategory: tv,
          band: band(-10000, -10500, -9500),
        ),
        isTrue,
      );
      expect(
        isSubscription(
          stream(minor: -10000),
          effectiveCategory: tv,
          band: band(-10000, -10501, -10000),
        ),
        isFalse,
      );
    });

    test('an unknown band counts only when the source flags it', () {
      expect(
        isSubscription(stream(), effectiveCategory: tv, band: null),
        isFalse,
      );
      expect(
        isSubscription(
          stream(flagged: true, source: RecurringSource.demo),
          effectiveCategory: tv,
          band: band(-1549, -2000, -1000),
        ),
        isTrue,
      );
    });

    test('inflows are never subscriptions', () {
      expect(
        isSubscription(
          stream(minor: 1549, flagged: true),
          effectiveCategory: tv,
          band: band(1549, 1549, 1549),
        ),
        isFalse,
      );
    });

    test('weekly, monthly and annual only', () {
      for (final RecurringCadence c in RecurringCadence.values) {
        expect(
          isSubscription(
            stream(cadence: c),
            effectiveCategory: tv,
            band: fixed,
          ),
          {
            RecurringCadence.weekly,
            RecurringCadence.monthly,
            RecurringCadence.annually,
          }.contains(c),
          reason: c.name,
        );
      }
    });

    test('rent, utilities, loans, transfers, income and taxes are not', () {
      for (final String code in [
        'RENT_AND_UTILITIES',
        'RENT_AND_UTILITIES_RENT',
        'RENT_AND_UTILITIES_TELEPHONE',
        'LOAN_PAYMENTS_MORTGAGE_PAYMENT',
        'LOAN_PAYMENTS_CAR_PAYMENT',
        'TRANSFER_OUT_SAVINGS',
        'TRANSFER_IN_ACCOUNT_TRANSFER',
        'INCOME_SALARY',
        'GOVERNMENT_AND_NON_PROFIT_TAX_PAYMENT',
      ]) {
        expect(
          isSubscription(
            stream(),
            effectiveCategory: byCode[code]!,
            band: fixed,
          ),
          isFalse,
          reason: code,
        );
      }
      expect(
        isSubscription(
          stream(),
          effectiveCategory: byCode['GOVERNMENT_AND_NON_PROFIT_DONATIONS']!,
          band: fixed,
        ),
        isTrue,
      );
    });
  });

  group('streamCategory', () {
    test('the most common effective category, a user choice included', () {
      final List<Transaction> members = [
        tx('a', LocalDate(2026, 1, 7), code: 'ENTERTAINMENT_TV_AND_MOVIES'),
        tx('b', LocalDate(2026, 2, 7), code: 'ENTERTAINMENT_TV_AND_MOVIES'),
        tx(
          'c',
          LocalDate(2026, 3, 7),
          code: 'TRANSFER_OUT_ACCOUNT_TRANSFER',
          user: 'plaid:ENTERTAINMENT_TV_AND_MOVIES',
        ),
        tx(
          'd',
          LocalDate(2026, 4, 7),
          code: 'GENERAL_SERVICES_OTHER_GENERAL_SERVICES',
        ),
      ];
      expect(
        streamCategory(members, lookup)?.plaidCategory,
        'ENTERTAINMENT_TV_AND_MOVIES',
      );
    });

    test('a tie goes to the newest member; no members, no category', () {
      final List<Transaction> members = [
        tx('a', LocalDate(2026, 1, 7), code: 'ENTERTAINMENT_TV_AND_MOVIES'),
        tx('b', LocalDate(2026, 2, 7), code: 'ENTERTAINMENT_MUSIC_AND_AUDIO'),
      ];
      expect(
        streamCategory(members, lookup)?.plaidCategory,
        'ENTERTAINMENT_MUSIC_AND_AUDIO',
      );
      expect(streamCategory(const [], lookup), isNull);
    });
  });
}
