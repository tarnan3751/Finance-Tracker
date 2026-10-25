/// The transaction editor, which is also a transaction's detail: expense or income, the
/// amount (parsed in the device locale for the account's currency, never rounded), the
/// account, the date (today by default, in the device zone), the description, the
/// category, notes and tags. A new transaction is `manual`; an edited one keeps its
/// source. With no category of the user's own, the category row shows the one its Plaid
/// code resolves to, captioned as the bank's. Deleting from here offers an undo for five
/// seconds; a Plaid transaction has no Delete, since only the bank removes one. "Run
/// rules on this transaction" (the overflow menu) applies the user's rules to the values
/// in the form, which Save then keeps like any edit. "Hidden" (the overflow menu, checked
/// when on) hides the transaction from the list, budgets and reports, saved with Save.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

/// How long the undo of a delete is offered.
const Duration undoDuration = Duration(seconds: 5);

/// The editor of transaction [transactionId], or of a new transaction (on
/// [initialAccountId] when given) when it is null.
class TransactionEditorScreen extends ConsumerWidget {
  const TransactionEditorScreen({
    super.key,
    this.transactionId,
    this.initialAccountId,
  });

  final String? transactionId;
  final String? initialAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? id = transactionId;
    final List<Account>? accounts = ref.watch(accountsProvider).value;
    final AsyncValue<TransactionUsage> usage = ref.watch(
      transactionUsageProvider,
    );
    final AsyncValue<Transaction?>? existing = id == null
        ? null
        : ref.watch(transactionProvider(id));
    if (accounts == null || !usage.hasValue || existing?.hasValue == false) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (existing != null) {
      final Transaction? transaction = existing.value;
      if (transaction == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(l10n.transactionNotFound)),
        );
      }
      if (!accounts.any((a) => a.id == transaction.accountId)) {
        // Its account was deleted (another device may have recorded it meanwhile) or
        // has not synced yet: nothing to edit it against. Restoring the account brings
        // it back.
        return Scaffold(
          appBar: AppBar(title: Text(transaction.name)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.accountNotFound, textAlign: TextAlign.center),
            ),
          ),
        );
      }
      return _TransactionForm(
        key: ValueKey(transaction.id),
        initial: transaction,
        accounts: accounts,
        accountId: transaction.accountId,
      );
    }
    if (accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.transactionNewTitle)),
        body: EmptyState(
          icon: Icons.account_balance_outlined,
          headline: l10n.transactionNeedsAccountHeadline,
          body: l10n.transactionNeedsAccountBody,
          action: FilledButton.icon(
            onPressed: () => const NewAccountRoute().push<void>(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.accountAdd),
          ),
        ),
      );
    }
    bool live(String? id) => accounts.any((a) => a.id == id);
    final String? lastUsed = usage.value!.recentAccountIds.firstOrNull;
    return _TransactionForm(
      initial: null,
      accounts: accounts,
      accountId: live(initialAccountId)
          ? initialAccountId!
          : accounts.length == 1
          ? accounts.single.id
          : live(lastUsed)
          ? lastUsed!
          : accounts.first.id,
    );
  }
}

class _TransactionForm extends ConsumerStatefulWidget {
  const _TransactionForm({
    super.key,
    required this.initial,
    required this.accounts,
    required this.accountId,
  });

  /// The transaction being edited, or null for a new one.
  final Transaction? initial;
  final List<Account> accounts;

  /// The account the form starts on.
  final String accountId;

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late bool _income = widget.initial?.amount.isPositive ?? false;
  late final TextEditingController _amount = TextEditingController(
    text: widget.initial?.amount.abs().format(symbol: false),
  );
  late String _accountId = widget.accountId;
  late LocalDate _date = widget.initial?.date ?? ref.read(todayProvider);
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late String? _categoryId = widget.initial?.userCategoryId;
  late final TextEditingController _notes = TextEditingController(
    text: widget.initial?.notes,
  );
  late List<String> _tags = [...?widget.initial?.tags];
  late bool _hidden = widget.initial?.hidden ?? false;
  final TextEditingController _tagInput = TextEditingController();
  bool _saving = false;

  bool get _isNew => widget.initial == null;

  String get _currency => widget.accounts
      .firstWhere(
        (a) => a.id == _accountId,
        orElse: () => widget.accounts.first,
      )
      .currencyCode;

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _notes.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      currentDate: ref.read(todayProvider).toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _date = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickCategory() async {
    final CategoryChoice? choice = await showCategoryPicker(
      context,
      selectedId: _categoryId,
    );
    if (choice != null && mounted) {
      setState(() => _categoryId = choice.categoryId);
    }
  }

  void _addTag(String text) {
    final String tag = text.trim();
    _tagInput.clear();
    if (tag.isEmpty || _tags.contains(tag)) {
      setState(() {});
      return;
    }
    setState(() => _tags = [..._tags, tag]);
  }

  // What the form holds; call it once the form validates.
  TransactionDraft _draft() {
    final Money magnitude = parseAmountInput(_amount.text, _currency)!;
    final String notes = _notes.text.trim();
    return (
      accountId: _accountId,
      amount: _income ? magnitude : -magnitude,
      date: _date,
      name: _name.text.trim(),
      categoryId: _categoryId,
      notes: notes.isEmpty ? null : notes,
      tags: _tags,
      hidden: _hidden,
    );
  }

  // Applies the rules to the values in the form; Save keeps what they change.
  Future<void> _runRules() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    // Watched in build, so loaded unless the editor has only just opened.
    final List<Rule> rules = await ref.read(rulesProvider.future);
    if (!mounted) return;
    final TransactionDraft draft = _draft();
    final DateTime now = ref.read(clockProvider).nowUtc();
    final Transaction form =
        (widget.initial ??
                Transaction(
                  id: '',
                  accountId: draft.accountId,
                  amount: draft.amount,
                  date: draft.date,
                  pending: false,
                  name: draft.name,
                  source: DataSource.manual,
                  createdAt: now,
                  updatedAt: now,
                  syncVersion: 0,
                ))
            .copyWith(
              accountId: draft.accountId,
              amount: draft.amount,
              date: draft.date,
              name: draft.name,
              userCategoryId: draft.categoryId,
              notes: draft.notes,
              tags: draft.tags,
              hidden: draft.hidden,
            );
    final RuleOutcome outcome = applyRules(
      rules,
      form,
      lookup: ref.read(transactionCategoryLookupProvider),
    );
    final Transaction? changed = outcome.changed;
    if (changed != null) {
      setState(() {
        _name.text = changed.name;
        _categoryId = changed.userCategoryId;
        _tags = changed.tags;
        _hidden = changed.hidden;
      });
    }
    final String? name = outcome.rule?.name;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          name == null
              ? l10n.transactionRulesNoMatch
              : changed == null
              ? l10n.transactionRulesUnchanged(name)
              : l10n.transactionRulesApplied(name),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TransactionActions actions = ref.read(transactionActionsProvider);
    final TransactionDraft draft = _draft();
    setState(() => _saving = true);
    try {
      final Transaction? initial = widget.initial;
      if (initial == null) {
        await actions.create(draft);
      } else {
        await actions.update(initial, draft);
      }
      if (mounted) context.pop();
    } on AccountNotFoundException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountNotFound)));
    } on CurrencyMismatchException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transactionCurrencyMismatch)),
      );
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.transactionNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TransactionActions actions = ref.read(transactionActionsProvider);
    final String id = widget.initial!.id;
    context.pop();
    await actions.delete(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.transactionDeleted),
        duration: undoDuration,
        // A snack bar with an action stays until dismissed unless told otherwise.
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            try {
              await actions.restore(id);
            } on AccountNotFoundException {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.transactionRestoreNoAccount)),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    // Kept loaded for "Run rules on this transaction".
    ref.watch(rulesProvider);
    final Transaction? initial = widget.initial;
    // The user's choice, else what the bank's category resolves to (shown, not chosen).
    final Category? chosen = categories.byId[_categoryId];
    final Category? fromBank = chosen != null || initial == null
        ? null
        : plaidCategoryOf(initial, categories.byPlaidCode);
    final Category? category = chosen ?? fromBank;
    final List<String> knownTags =
        ref.watch(transactionUsageProvider).value?.tags ?? const [];
    final String typed = _tagInput.text.trim().toLowerCase();
    final List<String> suggestions = [
      for (final String tag in knownTags)
        if (!_tags.contains(tag) && tag.toLowerCase().contains(typed)) tag,
    ].take(8).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.transactionNewTitle : l10n.transactionTitle),
        actions: [
          // Only the bank removes a Plaid transaction.
          if (!_isNew && initial?.source != DataSource.plaid)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
          PopupMenuButton<void>(
            tooltip: l10n.transactionMoreOptions,
            enabled: !_saving,
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _runRules,
                child: Text(l10n.transactionRunRules),
              ),
              CheckedPopupMenuItem(
                checked: _hidden,
                onTap: () => setState(() => _hidden = !_hidden),
                child: Semantics(
                  checked: _hidden,
                  child: Text(l10n.transactionHiddenOption),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.transactionExpense),
                  icon: const Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.transactionIncome),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_income},
              onSelectionChanged: (selection) =>
                  setState(() => _income = selection.single),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: _isNew,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.transactionAmount,
                prefixText: currencySymbol(_currency),
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => amountInputError(
                l10n,
                value ?? '',
                _currency,
                required: true,
                signed: false,
                nonZero: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.transactionAccount,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final Account account in widget.accounts)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) {
                if (id != null) setState(() => _accountId = id);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.transactionDate),
              subtitle: Text(shortDateLabel(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.transactionDescription,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.transactionDescriptionRequired
                  : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                category == null
                    ? fallbackCategoryIcon
                    : categoryIconFor(category.icon),
                color: category == null
                    ? theme.colorScheme.outline
                    : categoryColor(context, category.color),
              ),
              title: Text(l10n.transactionCategory),
              subtitle: fromBank == null
                  ? Text(category?.name ?? l10n.uncategorized)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fromBank.name),
                        Text(
                          l10n.transactionCategoryFromBank,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCategory,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.transactionNotes,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagInput,
              decoration: InputDecoration(
                labelText: l10n.transactionTags,
                helperText: l10n.transactionTagsHelper,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.endsWith(',')) {
                  _addTag(value.substring(0, value.length - 1));
                } else {
                  setState(() {});
                }
              },
              onSubmitted: _addTag,
            ),
            if (_tags.isNotEmpty || suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final String tag in _tags)
                    InputChip(
                      label: Text(l10n.tagLabel(tag)),
                      onDeleted: () =>
                          setState(() => _tags = [..._tags]..remove(tag)),
                      deleteButtonTooltipMessage: l10n.tagRemove(tag),
                    ),
                  for (final String tag in suggestions)
                    ActionChip(
                      avatar: const Icon(Icons.add),
                      label: Text(l10n.tagLabel(tag)),
                      tooltip: l10n.tagAdd(tag),
                      onPressed: () => _addTag(tag),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
