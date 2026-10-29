/// The goal editor (`docs/reference/goals.md`, **Screens**), at `/goals/new` and
/// `/goals/:id/edit`: the name, the target amount in a currency of the accounts, what the
/// progress is from (account balances or contributions), the accounts a balance goal
/// counts (those in another currency marked as not counted), the optional target date
/// (today or later for a new goal; an existing goal keeps the date it has) and a note.
/// The currency is fixed once a goal has contributions or linked accounts. An existing
/// goal can be archived (or brought back) and deleted, each with an undo.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

/// The editor of goal [goalId], or of a new goal when it is null.
class GoalEditorScreen extends ConsumerWidget {
  const GoalEditorScreen({super.key, this.goalId});

  final String? goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<GoalView>? goals = ref.watch(goalViewsProvider).value;
    final List<Account>? accounts = ref.watch(accountsProvider).value;
    if (goals == null || accounts == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final String? id = goalId;
    if (id == null) return _GoalForm(initial: null, accounts: accounts);
    final GoalView? view = goals.where((v) => v.goal.id == id).firstOrNull;
    final Goal? goal = view?.goal;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.goalNotFound)),
      );
    }
    return _GoalForm(
      key: ValueKey(id),
      initial: goal,
      accounts: accounts,
      // Contributions or accounts already counted in its currency fix the currency.
      currencyLocked:
          view!.contributions.isNotEmpty || goal.linkedAccountIds.isNotEmpty,
    );
  }
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({
    super.key,
    required this.initial,
    required this.accounts,
    this.currencyLocked = false,
  });

  /// The goal being edited, or null for a new one.
  final Goal? initial;

  final List<Account> accounts;

  /// Whether the target's currency can no longer change.
  final bool currencyLocked;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  /// What the form edits: the screen's goal, or once a save has landed, the saved one,
  /// so a later Save updates it rather than creating another.
  late Goal? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late final TextEditingController _target = TextEditingController(
    text: widget.initial?.target.format(symbol: false),
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.initial?.note,
  );
  late String _currency =
      widget.initial?.target.currencyCode ?? _currencies.first;
  late GoalKind _kind = widget.initial?.kind ?? GoalKind.balance;
  late final Set<String> _accountIds = {...?widget.initial?.linkedAccountIds};
  late LocalDate? _targetDate = widget.initial?.targetDate;
  bool _saving = false;

  bool get _isNew => _initial == null;

  /// The goal's id: the edited one's, else one made once for the new goal.
  late final String _id = widget.initial?.id ?? const Uuid().v4();

  /// The accounts' currencies and the goal's own, the device's default when there is
  /// neither.
  List<String> get _currencies {
    final List<String> codes = {
      for (final Account a in widget.accounts) a.currencyCode,
      ?widget.initial?.target.currencyCode,
    }.toList()..sort();
    return codes.isEmpty ? [defaultCurrencyCode()] : codes;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The earliest target date the form takes: today, or an existing goal's own date when
  /// that is earlier, so the goal keeps it.
  LocalDate _firstDate(LocalDate today) => switch (_initial?.targetDate) {
    final LocalDate kept when kept.isBefore(today) => kept,
    _ => today,
  };

  Future<void> _pickTargetDate(LocalDate today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (_targetDate ?? today.addMonths(12)).toDateTime(),
      firstDate: _firstDate(today).toDateTime(),
      lastDate: DateTime(today.year + 50, 12, 31),
      currentDate: today.toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _targetDate = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save(LocalDate today) async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoalActions actions = ref.read(goalActionsProvider);
    final Goal? initial = _initial;
    final String note = _note.text.trim();
    final Goal goal = Goal(
      id: _id,
      name: _name.text.trim(),
      target: parseAmountInput(_target.text, _currency)!,
      kind: _kind,
      // Kept in the order of the accounts list.
      linkedAccountIds: _kind == GoalKind.balance
          ? [
              for (final Account a in widget.accounts)
                if (_accountIds.contains(a.id)) a.id,
              for (final String id in initial?.linkedAccountIds ?? const [])
                if (_accountIds.contains(id) &&
                    !widget.accounts.any((a) => a.id == id))
                  id,
            ]
          : const [],
      targetDate: _targetDate,
      createdOn: initial?.createdOn ?? today,
      note: note.isEmpty ? null : note,
      archivedAt: initial?.archivedAt,
    );
    final OwnPage page = OwnPage.of(context);
    setState(() => _saving = true);
    try {
      if (initial == null) {
        await actions.create(goal);
      } else {
        await actions.update(goal);
      }
      if (mounted) setState(() => _initial = goal);
      page.close();
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.goalNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Back to the goals, whose messenger shows the Undo, then [write].
  Future<void> _leaveAnd(
    Future<void> Function(GoalActions actions, String id) write,
    String message,
    Future<void> Function(GoalActions actions, String id) undo,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoalActions actions = ref.read(goalActionsProvider);
    final String id = _initial!.id;
    const GoalsRoute().go(context);
    await write(actions, id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => undo(actions, id),
        ),
      ),
    );
  }

  Future<void> _toggleArchive() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_initial!.archivedAt == null) {
      await _leaveAnd(
        (a, id) => a.setArchived(id, archived: true),
        l10n.goalArchivedMessage,
        (a, id) => a.setArchived(id, archived: false),
      );
    } else {
      final OwnPage page = OwnPage.of(context);
      await ref
          .read(goalActionsProvider)
          .setArchived(_initial!.id, archived: false);
      page.close();
    }
  }

  Future<void> _delete() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _leaveAnd(
      (a, id) => a.delete(id),
      l10n.goalDeleted,
      (a, id) => a.restore(id),
    );
  }

  // A field that opens a picker: [label], [value], and the [validator]'s error.
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
    final LocalDate today = ref.watch(todayProvider);
    final List<String> currencies = _currencies;
    final Goal? initial = _initial;
    final LocalDate? targetDate = _targetDate;
    const SizedBox gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.goalNewTitle : l10n.goalEditTitle),
        actions: [
          if (initial != null) ...[
            IconButton(
              tooltip: initial.archivedAt == null
                  ? l10n.goalArchive
                  : l10n.goalUnarchive,
              icon: Icon(
                initial.archivedAt == null
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined,
              ),
              onPressed: _saving ? null : _toggleArchive,
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
          ],
          TextButton(
            onPressed: _saving ? null : () => _save(today),
            child: Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.goalName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.goalNameRequired : null,
            ),
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
                      onSelected: widget.currencyLocked
                          ? null
                          : (_) => setState(() => _currency = code),
                    ),
                ],
              ),
              if (widget.currencyLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.goalCurrencyLocked,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.goalTarget,
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
            Text(l10n.goalKind, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<GoalKind>(
              segments: [
                ButtonSegment(
                  value: GoalKind.balance,
                  label: Text(l10n.goalKindBalance),
                ),
                ButtonSegment(
                  value: GoalKind.contribution,
                  label: Text(l10n.goalKindContribution),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _kind = s.single),
            ),
            const SizedBox(height: 4),
            Text(
              _kind == GoalKind.balance
                  ? l10n.goalKindBalanceCaption
                  : l10n.goalKindContributionCaption,
              style: theme.textTheme.bodySmall,
            ),
            if (_kind == GoalKind.balance) ...[
              gap,
              FormField<Set<String>>(
                validator: (_) =>
                    widget.accounts.any(
                      (a) =>
                          _accountIds.contains(a.id) &&
                          a.currencyCode == _currency,
                    )
                    ? null
                    : l10n.goalAccountsRequired,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.goalAccounts, style: theme.textTheme.titleSmall),
                    for (final Account a in widget.accounts)
                      CheckboxListTile(
                        key: ValueKey('goal-account/${a.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(a.name),
                        subtitle: a.currencyCode == _currency
                            ? null
                            : Text(
                                l10n.goalAccountOtherCurrency(a.currencyCode),
                              ),
                        value: _accountIds.contains(a.id),
                        onChanged: (on) => setState(
                          () => on!
                              ? _accountIds.add(a.id)
                              : _accountIds.remove(a.id),
                        ),
                      ),
                    if (state.errorText case final String error)
                      Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            gap,
            _pickerField(
              label: l10n.goalTargetDate,
              value: targetDate == null
                  ? l10n.goalNoTargetDate
                  : shortDateLabel(targetDate),
              validator: (_) =>
                  targetDate != null && targetDate.isBefore(_firstDate(today))
                  ? l10n.goalTargetDatePast
                  : null,
              onTap: () => _pickTargetDate(today),
            ),
            if (targetDate != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _targetDate = null),
                  child: Text(l10n.goalClearTargetDate),
                ),
              ),
            gap,
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                labelText: l10n.goalNote,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
