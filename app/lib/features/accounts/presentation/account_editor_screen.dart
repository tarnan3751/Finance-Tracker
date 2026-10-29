/// The account editor, for a new account and an existing one: the name, the type, the
/// currency (the device locale's by default; fixed once the account has transactions),
/// and for a new account an optional opening balance, which becomes a `manual`
/// transaction named "Opening balance" on the date picked (today by default).
library;

import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/account_errors.dart';
import 'package:finance_tracker/features/accounts/presentation/account_type_style.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The editor of account [accountId], or of a new account when it is null.
class AccountEditorScreen extends ConsumerWidget {
  const AccountEditorScreen({super.key, this.accountId});

  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? id = accountId;
    if (id == null) {
      return const _AccountForm(initial: null, hasTransactions: false);
    }
    final AsyncValue<Account?> account = ref.watch(accountProvider(id));
    final AsyncValue<int> count = ref.watch(
      accountTransactionCountProvider(id),
    );
    return switch ((account, count)) {
      (
        AsyncValue(value: final Account account),
        AsyncValue(value: final int n),
      ) =>
        _AccountForm(
          key: ValueKey(account.id),
          initial: account,
          hasTransactions: n > 0,
        ),
      (AsyncValue(hasValue: true, value: null), _) ||
      (AsyncError(), _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.accountNotFound)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({
    super.key,
    required this.initial,
    required this.hasTransactions,
  });

  /// The account being edited, or null for a new one.
  final Account? initial;

  /// Whether the account has transactions, which fixes its currency.
  final bool hasTransactions;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  /// What the form edits: the screen's entity, or once a save has landed, the saved
  /// one, so a later Save rewrites it rather than creating another.
  late Account? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  final TextEditingController _opening = TextEditingController();
  late AccountType _type = _initial?.type ?? AccountType.depository;
  late String _currency = _initial?.currencyCode ?? defaultCurrencyCode();
  late LocalDate _openingDate = ref.read(todayProvider);
  bool _saving = false;

  bool get _isNew => _initial == null;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final String? code = await showCurrencyPicker(context, selected: _currency);
    if (code != null && mounted) setState(() => _currency = code);
  }

  Future<void> _pickOpeningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _openingDate.toDateTime(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      currentDate: ref.read(todayProvider).toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _openingDate = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AccountActions actions = ref.read(accountActionsProvider);
    final OwnPage page = OwnPage.of(context);
    final String name = _name.text.trim();
    final Account? initial = _initial;
    setState(() => _saving = true);
    Account? stored;
    final bool saved = await runAccountWrite(messenger, l10n, () async {
      if (initial == null) {
        stored = await actions.create(
          existing: ref.read(accountsProvider).value ?? const [],
          name: name,
          type: _type,
          currencyCode: _currency,
          openingBalance: parseAmountInput(_opening.text, _currency),
          openingDate: _openingDate,
          openingBalanceName: l10n.openingBalanceName,
        );
      } else {
        final Account edited = initial.copyWith(
          name: name,
          type: _type,
          currencyCode: _currency,
        );
        await actions.update(edited);
        stored = edited;
      }
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _initial = stored;
    });
    if (saved) page.close();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool currencyEditable = !widget.hasTransactions;
    // Watched so a new account can go after the existing ones.
    ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.accountNewTitle : l10n.accountEditTitle),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: _isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.accountName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.accountNameRequired
                  : null,
            ),
            const SizedBox(height: 24),
            Text(l10n.accountType, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final AccountType type in AccountType.values)
                  ChoiceChip(
                    avatar: Icon(accountTypeIcon(type)),
                    showCheckmark: false,
                    label: Text(accountTypeLabel(l10n, type)),
                    selected: type == _type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: currencyEditable,
              title: Text(l10n.accountCurrency),
              subtitle: Text(
                currencyEditable
                    ? l10n.currencyValue(_currency, currencySymbol(_currency))
                    : l10n.accountCurrencyFixed(
                        l10n.currencyValue(
                          _currency,
                          currencySymbol(_currency),
                        ),
                      ),
              ),
              trailing: currencyEditable
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: currencyEditable ? _pickCurrency : null,
            ),
            if (_isNew) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _opening,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.openingBalance,
                  helperText: l10n.openingBalanceHelper,
                  prefixText: currencySymbol(_currency),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    amountInputError(l10n, value ?? '', _currency),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.openingBalanceDate),
                subtitle: Text(shortDateLabel(_openingDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickOpeningDate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
