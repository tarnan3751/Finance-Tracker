// The transaction list's application layer: the date presets resolved against today, the
// query the filters make (a category with the ones under it, and their Plaid codes),
// grouping by date, paging one page at a time, the filters' JSON for a saved filter, and
// the saved filter the list's filters are.
import 'dart:async';
import 'dart:convert';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
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
        hidden: false,
        limit: 50,
      ),
    );
    expect(
      TransactionFilters.none.toQuery(today),
      TransactionQuery(hidden: false),
    );
    expect(TransactionFilters.none.withText('x').hasFilters, isFalse);
    expect(filters.withoutAccount('a').accountIds, isEmpty);
    expect(filters.withoutAmount().minAmount, isNull);
    expect(filters.withoutDate().date, isNull);
  });

  test(
    'show hidden lists every row, counts as a filter and survives edits',
    () {
      const TransactionFilters shown = TransactionFilters(showHidden: true);
      expect(shown.toQuery(today), TransactionQuery.all);
      expect(shown.hasFilters, isTrue);
      expect(shown.withText('x').showHidden, isTrue);
      expect(shown.withoutTag('t').showHidden, isTrue);
      expect(shown.withoutHidden(), TransactionFilters.none);
      expect(shown, isNot(TransactionFilters.none));
    },
  );

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

  test('a bulk action applies to the rows as stored when it runs', () async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [storeOverride(seededStore())],
    );
    final TransactionRepository repository = container.read(
      transactionRepositoryProvider,
    );
    await repository.upsert(testTransaction('m1', name: 'Alpha'));
    await repository.upsert(testTransaction('m2', name: 'Beta'));
    // What the list showed when the rows were selected.
    final List<Transaction> selected = [
      (await repository.watchById('m1').first)!,
      (await repository.watchById('m2').first)!,
    ];
    // Synced in since: an edit of m1's notes, and m2 deleted.
    await repository.upsert(
      selected[0].copyWith(notes: 'from the other device'),
    );
    await repository.delete('m2');

    final int changed = await container
        .read(transactionActionsProvider)
        .setHidden(selected, true);
    expect(changed, 1);
    final Transaction m1 = (await repository.watchById('m1').first)!;
    expect(m1.hidden, isTrue);
    expect(m1.notes, 'from the other device');
    expect(await repository.watchById('m2').first, isNull);
  });

  group('saved filter JSON', () {
    final TransactionFilters full = TransactionFilters(
      text: 'coffee shop',
      accountIds: const {'b', 'a'},
      categoryIds: const {'plaid:FOOD_AND_DRINK'},
      date: DateFilter.custom(
        LocalDateRange(LocalDate(2026, 1, 1), LocalDate(2026, 2, 1)),
      ),
      minAmount: Money(500, 'EUR'),
      maxAmount: Money(10000, 'EUR'),
      tags: const {'work'},
      showHidden: true,
    );

    test('round-trips every field, through encoded JSON too', () {
      expect(TransactionFilters.fromJson(full.toJson()), full);
      expect(
        TransactionFilters.fromJson(
          jsonDecode(jsonEncode(full.toJson())) as Map<String, Object?>,
        ),
        full,
      );
      expect(full.toJson()['account_ids'], ['a', 'b']);
      expect(TransactionFilters.none.toJson(), isEmpty);
      expect(TransactionFilters.fromJson(const {}), TransactionFilters.none);
    });

    test('keeps a date preset as a preset, never as dates', () {
      const TransactionFilters thisMonth = TransactionFilters(
        date: DateFilter(DatePreset.thisMonth),
      );
      expect(thisMonth.toJson(), {
        'date': {'preset': 'this_month'},
      });
      for (final DatePreset preset in DatePreset.values) {
        if (preset == DatePreset.custom) continue;
        final TransactionFilters f = TransactionFilters(
          date: DateFilter(preset),
        );
        expect(TransactionFilters.fromJson(f.toJson()), f);
      }
    });

    test('ignores keys it does not know', () {
      expect(
        TransactionFilters.fromJson(const {
          'tags': ['work'],
          'pending': true,
          'sort': {'by': 'amount'},
        }),
        const TransactionFilters(tags: {'work'}),
      );
    });

    test('refuses a known key of the wrong shape', () {
      for (final Map<String, Object?> bad in [
        {'text': 3},
        {'tags': 'work'},
        {
          'account_ids': [1],
        },
        {
          'date': {'preset': 'next_week'},
        },
        {
          'date': {'preset': 'custom', 'start': '2026-01-01'},
        },
        {
          'min_amount': {'minor_units': 1.5, 'currency': 'USD'},
        },
        {'show_hidden': 'yes'},
      ]) {
        expect(
          () => TransactionFilters.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('the applied saved filter', () {
    test('is the first saved filter equal to the list\'s filters', () async {
      const TransactionFilters coffee = TransactionFilters(text: 'coffee');
      final InMemorySavedFilterRepository saved = InMemorySavedFilterRepository(
        initial: [
          SavedFilter(
            id: 's2',
            name: 'Later',
            position: 1,
            filters: coffee.toJson(),
          ),
          SavedFilter(
            id: 's1',
            name: 'Coffee',
            position: 0,
            filters: coffee.toJson(),
          ),
        ],
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [savedFilterRepositoryProvider.overrideWithValue(saved)],
      );
      addTearDown(container.dispose);
      container.listen(appliedSavedFilterProvider, (_, _) {});
      container.listen(savedFiltersProvider, (_, _) {});
      await pumpEventQueue();
      expect(container.read(appliedSavedFilterProvider), isNull);

      final TransactionListController controller = container.read(
        transactionListControllerProvider.notifier,
      );
      controller.setFilters(coffee);
      expect(container.read(appliedSavedFilterProvider)?.id, 's1');
      controller.setText('coffee beans');
      expect(container.read(appliedSavedFilterProvider), isNull);
    });

    test('a saved filter that does not decode is skipped and logged', () async {
      const TransactionFilters coffee = TransactionFilters(text: 'coffee');
      final InMemorySavedFilterRepository saved = InMemorySavedFilterRepository(
        initial: [
          SavedFilter(
            id: 's0',
            name: 'Broken',
            position: 0,
            filters: const {'tags': 'not a list'},
          ),
          SavedFilter(
            id: 's1',
            name: 'Coffee',
            position: 1,
            filters: coffee.toJson(),
          ),
        ],
      );
      final List<LogRecord> logs = [];
      final StreamSubscription<LogRecord> sub = Logger('transactions').onRecord
          .listen(logs.add);
      addTearDown(sub.cancel);
      final ProviderContainer container = ProviderContainer(
        overrides: [savedFilterRepositoryProvider.overrideWithValue(saved)],
      );
      addTearDown(container.dispose);
      container.listen(appliedSavedFilterProvider, (_, _) {});
      container.listen(savedFiltersProvider, (_, _) {});
      await pumpEventQueue();

      expect(
        [
          for (final f in container.read(savedFiltersProvider).value!)
            f.saved.id,
        ],
        ['s1'],
      );
      container
          .read(transactionListControllerProvider.notifier)
          .setFilters(coffee);
      expect(container.read(appliedSavedFilterProvider)?.id, 's1');
      expect(logs.map((r) => r.message), [
        'a saved filter does not decode (FormatException); skipped',
      ]);
    });
  });
}
