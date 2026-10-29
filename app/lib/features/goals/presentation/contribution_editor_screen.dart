/// A new contribution to a goal (`docs/reference/goals.md`, **Screens**), at
/// `/goals/:id/contribute`: the date (today unless chosen, never after today), the amount in the goal's
/// currency, whether it is a withdrawal, and a note. Contributions are not edited: one
/// is deleted from the goal's detail, with an undo, and added again.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

/// The editor of a new contribution to goal [goalId].
class ContributionEditorScreen extends ConsumerWidget {
  const ContributionEditorScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<GoalView?> view = ref.watch(goalViewByIdProvider(goalId));
    return switch (view.value) {
      null when view.isLoading => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      null => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.goalNotFound)),
      ),
      final GoalView v => _ContributionForm(goal: v.goal),
    };
  }
}

class _ContributionForm extends ConsumerStatefulWidget {
  const _ContributionForm({required this.goal});

  final Goal goal;

  @override
  ConsumerState<_ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends ConsumerState<_ContributionForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  late LocalDate _date = ref.read(todayProvider);
  bool _withdrawal = false;
  bool _saving = false;

  final String _id = const Uuid().v4();

  String get _currency => widget.goal.target.currencyCode;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate(LocalDate today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: today.toDateTime(),
      currentDate: today.toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _date = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final Money amount = parseAmountInput(_amount.text, _currency)!;
    final String note = _note.text.trim();
    final OwnPage page = OwnPage.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(goalActionsProvider)
          .addContribution(
            GoalContribution(
              id: _id,
              goalId: widget.goal.id,
              date: _date,
              amount: _withdrawal ? -amount : amount,
              note: note.isEmpty ? null : note,
            ),
          );
      page.close();
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.goalNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LocalDate today = ref.watch(todayProvider);
    const SizedBox gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.goalAddContribution),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.goal.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            gap,
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.contributionAmount,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.contributionWithdrawal),
              subtitle: Text(l10n.contributionWithdrawalCaption),
              value: _withdrawal,
              onChanged: (value) => setState(() => _withdrawal = value),
            ),
            gap,
            FormField<LocalDate>(
              key: ValueKey(_date),
              initialValue: _date,
              validator: (_) =>
                  _date.isAfter(today) ? l10n.contributionDateFuture : null,
              builder: (state) => InkWell(
                onTap: () => _pickDate(today),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.contributionDate,
                    errorText: state.errorText,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(shortDateLabel(_date)),
                ),
              ),
            ),
            gap,
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.contributionNote,
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
