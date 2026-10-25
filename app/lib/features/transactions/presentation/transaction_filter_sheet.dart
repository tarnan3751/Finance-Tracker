/// The transaction list's filter sheet: the saved filters, first, then whether hidden
/// transactions are shown, then accounts, categories, a date range (this month, last
/// month, the last 90 days, this year, or a custom range), an amount range in one
/// currency, and tags. Nothing changes until "Apply"; "Clear" empties the sheet. "Save these filters" saves what the sheet holds,
/// with the list's search text, under a name; the "Saved" section lists the saved
/// filters, each applied with a tap (closing the sheet), renamed or deleted from its menu.
library;

import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// Shows the sheet over [current]; completes with the filters to apply (the search text
/// kept, or a saved filter's own), or null when it is dismissed.
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

  // Asks for a name, [initial] filled in, under [title]; null when cancelled.
  Future<String?> _askName(
    String title,
    String action, {
    String initial = '',
  }) => showDialog<String>(
    context: context,
    builder: (context) =>
        _NameDialog(title: title, action: action, initial: initial),
  );

  Future<void> _save(TransactionFilters filters) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? name = await _askName(l10n.savedFilterSaveTitle, l10n.save);
    if (name == null || !mounted) return;
    await ref.read(savedFilterActionsProvider).save(name, filters);
  }

  Future<void> _rename(SavedFilter saved) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? name = await _askName(
      l10n.savedFilterRenameTitle,
      l10n.savedFilterRename,
      initial: saved.name,
    );
    if (name == null || !mounted) return;
    await ref.read(savedFilterActionsProvider).rename(saved.id, name);
  }

  Future<void> _delete(SavedFilter saved) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.savedFilterDeleteTitle(saved.name)),
        content: Text(l10n.savedFilterDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(savedFilterActionsProvider).delete(saved.id);
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
    final List<DecodedSavedFilter> saved =
        ref.watch(savedFiltersProvider).value ?? const [];
    final bool valid = minError == null && maxError == null;
    // What the sheet holds, with the list's search text: what Apply and Save take, read
    // when pressed, so a selection made in the same frame is not lost.
    TransactionFilters chosen() => TransactionFilters(
      text: widget.initial.text,
      accountIds: _accounts,
      categoryIds: _categories,
      date: _date,
      minAmount: parseAmountInput(_min.text, currency),
      maxAmount: parseAmountInput(_max.text, currency),
      tags: _tags,
      showHidden: _showHidden,
    );
    final TransactionFilters shown = chosen();
    final bool canSave =
        valid && (shown.hasFilters || shown.text.trim().isNotEmpty);

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
                if (saved.isNotEmpty) ...[
                  section(l10n.filterSaved),
                  for (final (:saved, :filters) in saved)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bookmark_outline),
                      title: Text(saved.name),
                      onTap: () => Navigator.of(context).pop(filters),
                      trailing: PopupMenuButton<void>(
                        tooltip: l10n.savedFilterOptions(saved.name),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () => _rename(saved),
                            child: Text(l10n.savedFilterRename),
                          ),
                          PopupMenuItem(
                            onTap: () => _delete(saved),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    ),
                ],
                // Under the saved filters, so both are on screen whatever the sections
                // below hold.
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canSave ? () => _save(chosen()) : null,
                      child: Text(
                        l10n.filterSaveThese,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: valid
                          ? () => Navigator.of(context).pop(chosen())
                          : null,
                      child: Text(l10n.filterApply),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for a saved filter's name; pops with it, trimmed, or null.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initial,
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _name.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.savedFilterNameLabel),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _name.text.trim().isEmpty ? null : _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
