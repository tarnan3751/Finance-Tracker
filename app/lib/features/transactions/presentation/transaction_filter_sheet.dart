/// The transaction list's filter sheet: whether hidden transactions are shown, first,
/// then accounts, categories, a date range (this month, last month, the last 90 days,
/// this year, or a custom range), an amount range in one currency, and tags. Nothing changes until
/// "Apply"; "Clear" empties the sheet.
library;

import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Shows the sheet over [current]; completes with the filters to apply (the search text
/// kept), or null when it is dismissed.
Future<TransactionFilters?> showTransactionFilterSheet(
  BuildContext context,
  TransactionFilters current,
) => showModalBottomSheet<TransactionFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => TransactionFilterSheet(initial: current),
);

/// The label of [date] on a chip: the preset's name, or the custom range's dates.
String dateFilterLabel(AppLocalizations l10n, DateFilter date) =>
    switch (date.preset) {
      DatePreset.thisMonth => l10n.datePresetThisMonth,
      DatePreset.lastMonth => l10n.datePresetLastMonth,
      DatePreset.last90Days => l10n.datePresetLast90Days,
      DatePreset.thisYear => l10n.datePresetThisYear,
      DatePreset.custom => l10n.dateRangeValue(
        shortDateLabel(date.customRange!.start),
        // The range is half-open; the user picked the day before its end.
        shortDateLabel(date.customRange!.end.addDays(-1)),
      ),
    };

/// The label of an amount range with bounds [min] and [max] (either may be null).
String amountFilterLabel(AppLocalizations l10n, Money? min, Money? max) =>
    switch ((min, max)) {
      (final Money min, final Money max) => l10n.amountRangeBetween(
        min.format(),
        max.format(),
      ),
      (final Money min, null) => l10n.amountRangeAtLeast(min.format()),
      (null, final Money max) => l10n.amountRangeAtMost(max.format()),
      (null, null) => '',
    };

/// The sheet's body.
class TransactionFilterSheet extends ConsumerStatefulWidget {
  const TransactionFilterSheet({super.key, required this.initial});

  final TransactionFilters initial;

  @override
  ConsumerState<TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState
    extends ConsumerState<TransactionFilterSheet> {
  late Set<String> _accounts = {...widget.initial.accountIds};
  late Set<String> _categories = {...widget.initial.categoryIds};
  late Set<String> _tags = {...widget.initial.tags};
  late bool _showHidden = widget.initial.showHidden;
  late DateFilter? _date = widget.initial.date;
  late String? _currency =
      widget.initial.minAmount?.currencyCode ??
      widget.initial.maxAmount?.currencyCode;
  late final TextEditingController _min = TextEditingController(
    text: widget.initial.minAmount?.format(symbol: false),
  );
  late final TextEditingController _max = TextEditingController(
    text: widget.initial.maxAmount?.format(symbol: false),
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _accounts = {};
    _categories = {};
    _tags = {};
    _showHidden = false;
    _date = null;
    _min.clear();
    _max.clear();
  });

  Future<void> _pickCustomRange() async {
    final LocalDateRange? current = _date?.customRange;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      currentDate: ref.read(todayProvider).toDateTime(),
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: current.start.toDateTime(),
              end: current.end.addDays(-1).toDateTime(),
            ),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _date = DateFilter.custom(
        LocalDateRange(
          LocalDate.fromDateTime(picked.start),
          LocalDate.fromDateTime(picked.end).addDays(1),
        ),
      ),
    );
  }

  Future<void> _addCategory() async {
    final CategoryChoice? choice = await showCategoryPicker(
      context,
      allowNone: false,
    );
    final String? id = choice?.categoryId;
    if (id != null && mounted) {
      setState(() => _categories = {..._categories, id});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<Account> accounts =
        ref.watch(accountsProvider).value ?? const [];
    final Map<String, Category> categories = ref.watch(categoriesByIdProvider);
    final List<String> tags = {
      ...?ref.watch(transactionUsageProvider).value?.tags,
      ..._tags,
    }.toList()..sort();
    final List<String> currencies = {
      for (final Account a in accounts) a.currencyCode,
    }.toList()..sort();
    final String currency =
        _currency ??
        (currencies.isEmpty ? defaultCurrencyCode() : currencies.first);
    final String? minError = amountInputError(
      l10n,
      _min.text,
      currency,
      signed: false,
    );
    final Money? min = parseAmountInput(_min.text, currency);
    final Money? max = parseAmountInput(_max.text, currency);
    final String? maxError =
        amountInputError(l10n, _max.text, currency, signed: false) ??
        (min != null && max != null && max < min
            ? l10n.amountRangeInverted
            : null);
    final LocalDate today = ref.watch(todayProvider);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.titleSmall),
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.transactionsFilter,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: _clear, child: Text(l10n.filterClear)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // First, so it is on screen whatever the sections below hold.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.filterShowHidden),
                  subtitle: Text(l10n.filterShowHiddenCaption),
                  value: _showHidden,
                  onChanged: (on) => setState(() => _showHidden = on),
                ),
                section(l10n.navAccounts),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final Account account in accounts)
                      FilterChip(
                        label: Text(account.name),
                        selected: _accounts.contains(account.id),
                        onSelected: (on) => setState(
                          () => _accounts = on
                              ? {..._accounts, account.id}
                              : ({..._accounts}..remove(account.id)),
                        ),
                      ),
                  ],
                ),
                section(l10n.filterCategories),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final String id in _categories)
                      InputChip(
                        label: Text(categories[id]?.name ?? l10n.uncategorized),
                        onDeleted: () => setState(
                          () => _categories = {..._categories}..remove(id),
                        ),
                        deleteButtonTooltipMessage: l10n.filterRemove(
                          categories[id]?.name ?? l10n.uncategorized,
                        ),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add),
                      label: Text(l10n.filterAddCategory),
                      onPressed: _addCategory,
                    ),
                  ],
                ),
                section(l10n.filterDate),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.datePresetAny),
                      selected: _date == null,
                      onSelected: (_) => setState(() => _date = null),
                    ),
                    for (final DatePreset preset in [
                      DatePreset.thisMonth,
                      DatePreset.lastMonth,
                      DatePreset.last90Days,
                      DatePreset.thisYear,
                    ])
                      ChoiceChip(
                        label: Text(dateFilterLabel(l10n, DateFilter(preset))),
                        selected: _date?.preset == preset,
                        onSelected: (_) =>
                            setState(() => _date = DateFilter(preset)),
                      ),
                    ChoiceChip(
                      label: Text(
                        _date?.preset == DatePreset.custom
                            ? dateFilterLabel(l10n, _date!)
                            : l10n.datePresetCustom,
                      ),
                      selected: _date?.preset == DatePreset.custom,
                      onSelected: (_) => _pickCustomRange(),
                    ),
                  ],
                ),
                if (_date case final DateFilter date
                    when date.preset != DatePreset.custom)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dateFilterLabel(
                        l10n,
                        DateFilter.custom(date.rangeOn(today)),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                section(l10n.filterAmount),
                if (currencies.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final String code in currencies)
                          ChoiceChip(
                            label: Text(code),
                            selected: code == currency,
                            onSelected: (_) => setState(() => _currency = code),
                          ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _min,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.filterAmountMin,
                          prefixText: currencySymbol(currency),
                          errorText: minError,
                          errorMaxLines: 3,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _max,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.filterAmountMax,
                          prefixText: currencySymbol(currency),
                          errorText: maxError,
                          errorMaxLines: 3,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                section(l10n.filterTags),
                if (tags.isEmpty)
                  Text(l10n.filterNoTags, style: theme.textTheme.bodyMedium)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final String tag in tags)
                        FilterChip(
                          label: Text(l10n.tagLabel(tag)),
                          selected: _tags.contains(tag),
                          onSelected: (on) => setState(
                            () => _tags = on
                                ? {..._tags, tag}
                                : ({..._tags}..remove(tag)),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: minError != null || maxError != null
                      ? null
                      : () => Navigator.of(context).pop(
                          TransactionFilters(
                            text: widget.initial.text,
                            accountIds: _accounts,
                            categoryIds: _categories,
                            date: _date,
                            minAmount: min,
                            maxAmount: max,
                            tags: _tags,
                            showHidden: _showHidden,
                          ),
                        ),
                  child: Text(l10n.filterApply),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
