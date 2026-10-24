// The transaction list's application layer: the date presets resolved against today, the
// query the filters make (a category with the ones under it, and their Plaid codes),
// grouping by date, and paging one page at a time.
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  final LocalDate today = LocalDate(2026, 3, 15);

  group('date presets', () {
    LocalDateRange range(DatePreset preset) =>
        DateFilter(preset).rangeOn(today);

    test('this month is the calendar month', () {
      expect(
        range(DatePreset.thisMonth),
        LocalDateRange(LocalDate(2026, 3, 1), LocalDate(2026, 4, 1)),
      );
    });

    test('last month is the calendar month before, across a year', () {
      expect(
        range(DatePreset.lastMonth),
        LocalDateRange(LocalDate(2026, 2, 1), LocalDate(2026, 3, 1)),
      );
      expect(
        const DateFilter(DatePreset.lastMonth).rangeOn(LocalDate(2026, 1, 31)),
        LocalDateRange(LocalDate(2025, 12, 1), LocalDate(2026, 1, 1)),
      );
    });

    test('the last 90 days are today and the 89 days before', () {
      final LocalDateRange last90 = range(DatePreset.last90Days);
      expect(last90.length, 90);
      expect(last90.contains(today), isTrue);
      expect(last90.contains(today.addDays(-89)), isTrue);
      expect(last90.contains(today.addDays(-90)), isFalse);
    });

    test('this year is the calendar year', () {
      expect(
        range(DatePreset.thisYear),
        LocalDateRange(LocalDate(2026, 1, 1), LocalDate(2027, 1, 1)),
      );
    });

    test('a custom range is itself', () {
      final LocalDateRange custom = LocalDateRange(
        LocalDate(2025, 5, 2),
        LocalDate(2025, 6, 1),
      );
      expect(DateFilter.custom(custom).rangeOn(today), custom);
    });
  });

  test('filters make the query, trimming the text and limiting the page', () {
    final TransactionFilters filters = TransactionFilters(
      text: '  coffee ',
      accountIds: const {'a'},
      categoryIds: const {'c'},
      date: const DateFilter(DatePreset.thisMonth),
      minAmount: Money(500, 'USD'),
      tags: const {'t'},
    );

    expect(
      filters.toQuery(today, limit: 50),
      TransactionQuery(
        text: 'coffee',
        accountIds: const {'a'},
        categoryIds: const {'c'},
        range: LocalDateRange(LocalDate(2026, 3, 1), LocalDate(2026, 4, 1)),
        minAmount: Money(500, 'USD'),
        tags: const {'t'},
        limit: 50,
      ),
    );
    expect(TransactionFilters.none.toQuery(today), TransactionQuery.all);
    expect(TransactionFilters.none.withText('x').hasFilters, isFalse);
    expect(filters.withoutAccount('a').accountIds, isEmpty);
    expect(filters.withoutAmount().minAmount, isNull);
    expect(filters.withoutDate().date, isNull);
  });

  test('groupByDate puts a header before each date', () {
    final List<TransactionListItem> items = groupByDate([
      testTransaction('a', daysAgo: 0),
      testTransaction('b', daysAgo: 0),
      testTransaction('c', daysAgo: 3),
    ]);

    expect(items.map((i) => i.runtimeType), [
      DateHeaderItem,
      TransactionItem,
      TransactionItem,
      DateHeaderItem,
      TransactionItem,
    ]);
    expect((items[3] as DateHeaderItem).date, testClock.today().addDays(-3));
  });

  test('a chosen category brings the categories under it along', () {
    final TransactionQuery query =
        const TransactionFilters(categoryIds: {'food'}).toQuery(
          today,
          childrenOf: (id) => id == 'food' ? ['coffee', 'bars'] : [],
        );

    expect(query.categoryIds, {'food', 'coffee', 'bars'});
  });

  test('every category included brings its Plaid code along', () {
    final TransactionQuery query =
        const TransactionFilters(categoryIds: {'food'}).toQuery(
          today,
          childrenOf: (id) => id == 'food' ? ['coffee', 'mine'] : [],
          plaidCodeOf: (id) => switch (id) {
            'food' => 'FOOD_AND_DRINK',
            'coffee' => 'FOOD_AND_DRINK_COFFEE',
            _ => null,
          },
        );

    expect(query.categoryIds, {'food', 'coffee', 'mine'});
    expect(query.categoryPlaidCodes, {
      'FOOD_AND_DRINK',
      'FOOD_AND_DRINK_COFFEE',
    });
  });

  test('loadMore asks for one page until that page has arrived', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final TransactionListController controller = container.read(
      transactionListControllerProvider.notifier,
    );

    // A full first page: one scroll event asks for a second page, and every further
    // event before it arrives (the loaded count still 50) asks for nothing.
    controller.loadMore(loaded: transactionPageSize);
    controller.loadMore(loaded: transactionPageSize);
    controller.loadMore(loaded: transactionPageSize);
    expect(container.read(transactionListControllerProvider).pages, 2);

    controller.loadMore(loaded: 2 * transactionPageSize);
    expect(container.read(transactionListControllerProvider).pages, 3);

    // A filter change goes back to the first page.
    controller.setText('x');
    expect(container.read(transactionListControllerProvider).pages, 1);
  });
}
