/// The budget editor, for `/budgets/new` and `/budgets/:id`: the category (any category,
/// a parent budgeting its whole group), the amount per period in a currency of the
/// accounts (the device's default when there is none), the day each period starts (1 to
/// 28), carry-over, and the first period, from which carry-over counts (the current
/// period by default; it can move earlier, never later). Deleting from here offers an
/// undo.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

/// The editor of budget [budgetId], or of a new budget when it is null.
class BudgetEditorScreen extends ConsumerWidget {
  const BudgetEditorScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Budget>? budgets = ref.watch(budgetsProvider).value;
    final List<Account>? accounts = ref.watch(accountsProvider).value;
    if (budgets == null || accounts == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final String? id = budgetId;
    if (id == null) return _BudgetForm(initial: null, accounts: accounts);
    final Budget? budget = budgets.where((b) => b.id == id).firstOrNull;
    if (budget == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.budgetNotFound)),
      );
    }
    return _BudgetForm(key: ValueKey(id), initial: budget, accounts: accounts);
  }
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({super.key, required this.initial, required this.accounts});

  /// The budget being edited, or null for a new one.
  final Budget? initial;
  final List<Account> accounts;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  /// What the form edits: the screen's entity, or once a save has landed, the saved
  /// one, so a later Save rewrites it rather than creating another.
  late Budget? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _amount = TextEditingController(
    text: _initial?.amount.format(symbol: false),
  );
  late final TextEditingController _startDay = TextEditingController(
    text: '${_initial?.periodStartDay ?? 1}',
  );
  late String? _categoryId = _initial?.categoryId;
  late bool _rollover = _initial?.rollover ?? false;
  late String _currency = _initial?.amount.currencyCode ?? _currencies.first;

  /// The first period the user picked, or null for the budget's own (the current
  /// period's for a new budget).
  LocalDate? _startDate;
  bool _saving = false;

  bool get _isNew => _initial == null;

  /// The budget's id: the edited one's, else one made once for the new budget.
  late final String _id = widget.initial?.id ?? const Uuid().v4();

  /// The accounts' currencies and the budget's own, the device's default when there is
  /// neither.
  List<String> get _currencies {
    final List<String> codes = {
      for (final Account a in widget.accounts) a.currencyCode,
      ?_initial?.amount.currencyCode,
    }.toList()..sort();
    return codes.isEmpty ? [defaultCurrencyCode()] : codes;
  }

  /// The start day typed, when it is 1 to 28.
  int? get _day {
    final int? day = int.tryParse(_startDay.text.trim());
    return day != null && day >= 1 && day <= 28 ? day : null;
  }

  /// The first day of the first period: the one containing the date picked (or the
  /// budget's own), no later than the current period's.
  LocalDate _firstPeriodStart(LocalDate today) {
    final int day = _day ?? _initial?.periodStartDay ?? 1;
    final LocalDate latest = periodContaining(today, day).start;
    final LocalDate chosen = _startDate ?? _initial?.startDate ?? latest;
    final LocalDate start = periodContaining(chosen, day).start;
    return start.isAfter(latest) ? latest : start;
  }

  @override
  void dispose() {
    _amount.dispose();
    _startDay.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate(LocalDate today) async {
    final LocalDate latest = periodContaining(
      today,
      _day ?? _initial?.periodStartDay ?? 1,
    ).start;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstPeriodStart(today).toDateTime(),
      firstDate: DateTime(2000),
      lastDate: latest.toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BudgetRepository repository = ref.read(budgetRepositoryProvider);
    final OwnPage page = OwnPage.of(context);
    final Budget budget = Budget(
      id: _id,
      categoryId: _categoryId!,
      period: BudgetPeriodKind.monthly,
      periodStartDay: _day!,
      amount: parseAmountInput(_amount.text, _currency)!,
      rollover: _rollover,
      startDate: _firstPeriodStart(ref.read(todayProvider)),
    );
    final bool isNew = _initial == null;
    final NotificationPermission permission = ref.read(
      notificationPermissionProvider,
    );
    setState(() => _saving = true);
    try {
      await repository.upsert(budget);
      if (mounted) setState(() => _initial = budget);
      // A new budget turns its alerts on: the moment to ask, once, for the permission
      // to notify, while the editor is what the user sees.
      if (isNew && page.isTop) await permission.ask();
      page.close();
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.budgetNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BudgetRepository repository = ref.read(budgetRepositoryProvider);
    final String id = _initial!.id;
    // Back to the list: the budget's detail would show it missing.
    const BudgetsRoute().go(context);
    await repository.delete(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.budgetDeleted),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => repository.restore(id),
        ),
      ),
    );
  }

  // A field that opens a picker: [label], [value] or [placeholder], and the
  // [validator]'s error.
  Widget _pickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
    FormFieldValidator<String>? validator,
  }) => FormField<String>(
    key: ValueKey('$label/$value'),
    initialValue: value,
    validator: validator,
    builder: (state) => InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: state.errorText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final LocalDate today = ref.watch(todayProvider);
    final List<String> currencies = _currencies;
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    const SizedBox gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.budgetNewTitle : l10n.budgetEditTitle),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _pickerField(
              label: l10n.budgetCategory,
              value:
                  categories.byId[_categoryId]?.name ??
                  l10n.budgetChooseCategory,
              validator: (_) => categories.byId[_categoryId] == null
                  ? l10n.budgetChooseCategory
                  : null,
              onTap: () async {
                final CategoryChoice? choice = await showCategoryPicker(
                  context,
                  selectedId: _categoryId,
                  allowNone: false,
                );
                if (choice?.categoryId case final String id when mounted) {
                  setState(() => _categoryId = id);
                }
              },
            ),
            caption(l10n.budgetCategoryCaption),
            gap,
            if (currencies.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final String code in currencies)
                    ChoiceChip(
                      label: Text(code),
                      selected: code == _currency,
                      onSelected: (_) => setState(() => _currency = code),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.budgetAmount,
                prefixText: currencySymbol(_currency),
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => amountInputError(
                l10n,
                v ?? '',
                _currency,
                required: true,
                signed: false,
                nonZero: true,
              ),
            ),
            gap,
            TextFormField(
              controller: _startDay,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.budgetStartDay,
                helperText: l10n.budgetStartDayHelper,
                helperMaxLines: 3,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              validator: (_) =>
                  _day == null ? l10n.budgetStartDayInvalid : null,
            ),
            gap,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.budgetRollover),
              subtitle: Text(l10n.budgetRolloverCaption),
              value: _rollover,
              onChanged: (value) => setState(() => _rollover = value),
            ),
            gap,
            _pickerField(
              label: l10n.budgetStartDate,
              value: shortDateLabel(_firstPeriodStart(today)),
              onTap: () => _pickStartDate(today),
            ),
            caption(l10n.budgetStartDateCaption),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
