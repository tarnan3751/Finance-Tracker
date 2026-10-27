/// The bill editor, for `/bills/new` and `/bills/:id` (`docs/reference/bills.md`,
/// **Screens**): the name, the expected amount in a currency of the accounts, the first
/// due date, how often it repeats, the account it is paid from, the reminders (the days
/// before and the time of day), whether it is active and on autopay. Turning reminders on
/// asks for the notification permission when the app lacks it, and explains a refusal
/// (`notification_permission_sheet.dart`). Deleting from here offers an undo. The Plan
/// tab's Bills segment (5e) reuses it.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/presentation/notification_permission_sheet.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

/// The reminder offsets the editor offers, in days before the due date.
const List<int> reminderOffsetChoices = [0, 1, 2, 3, 7];

/// The cadences the editor offers; null is once.
const List<RecurringCadence?> cadenceChoices = [
  null,
  RecurringCadence.weekly,
  RecurringCadence.biweekly,
  RecurringCadence.semiMonthly,
  RecurringCadence.monthly,
  RecurringCadence.quarterly,
  RecurringCadence.annually,
];

/// The localized name of [cadence] (null: once).
String cadenceLabel(AppLocalizations l10n, RecurringCadence? cadence) =>
    switch (cadence) {
      null || RecurringCadence.unknown => l10n.billCadenceOnce,
      RecurringCadence.weekly => l10n.billCadenceWeekly,
      RecurringCadence.biweekly => l10n.billCadenceBiweekly,
      RecurringCadence.semiMonthly => l10n.billCadenceSemiMonthly,
      RecurringCadence.monthly => l10n.billCadenceMonthly,
      RecurringCadence.quarterly => l10n.billCadenceQuarterly,
      RecurringCadence.annually => l10n.billCadenceAnnually,
    };

/// The editor of bill [billId], or of a new bill when it is null.
class BillEditorScreen extends ConsumerWidget {
  const BillEditorScreen({super.key, this.billId});

  final String? billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<BillReminder>? bills = ref.watch(billsProvider).value;
    final List<Account>? accounts = ref.watch(accountsProvider).value;
    if (bills == null || accounts == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final String? id = billId;
    if (id == null) return _BillForm(initial: null, accounts: accounts);
    final BillReminder? bill = bills.where((b) => b.id == id).firstOrNull;
    if (bill == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.billNotFound)),
      );
    }
    return _BillForm(key: ValueKey(id), initial: bill, accounts: accounts);
  }
}

class _BillForm extends ConsumerStatefulWidget {
  const _BillForm({super.key, required this.initial, required this.accounts});

  /// The bill being edited, or null for a new one.
  final BillReminder? initial;
  final List<Account> accounts;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name,
  );
  late final TextEditingController _amount = TextEditingController(
    text: switch (widget.initial?.amount) {
      final Money m => Money(
        m.minorUnits.abs(),
        m.currencyCode,
      ).format(symbol: false),
      null => null,
    },
  );
  late String _currency =
      widget.initial?.amount?.currencyCode ?? _currencies.first;
  late LocalDate? _dueDate = widget.initial?.dueDate;
  late RecurringCadence? _cadence = widget.initial == null
      ? RecurringCadence.monthly
      : widget.initial!.cadence;
  late String? _accountId = widget.initial?.accountId;
  late final Set<int> _offsets = {
    ...widget.initial?.reminderOffsetDays ?? const [2],
  };
  late int _minutes = widget.initial?.reminderMinutes ?? defaultReminderMinutes;
  late bool _active = widget.initial?.active ?? true;
  late bool _autopay = widget.initial?.autopay ?? false;
  bool _saving = false;

  bool get _isNew => widget.initial == null;

  /// Whether the bill as edited would remind the user.
  bool get _reminds => _active && _offsets.isNotEmpty;

  /// The accounts' currencies and the bill's own, the device's default when there is
  /// neither.
  List<String> get _currencies {
    final List<String> codes = {
      for (final Account a in widget.accounts) a.currencyCode,
      ?widget.initial?.amount?.currencyCode,
    }.toList()..sort();
    return codes.isEmpty ? [defaultCurrencyCode()] : codes;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(LocalDate today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (_dueDate ?? today).toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 10, 12, 31),
      currentDate: today.toDateTime(),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = LocalDate.fromDateTime(picked));
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (picked != null && mounted) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BillActions actions = ref.read(billActionsProvider);
    final ReminderScheduler scheduler = ref.read(reminderSchedulerProvider);
    final BillReminder? initial = widget.initial;
    final Money? amount = _amount.text.trim().isEmpty
        ? null
        : parseAmountInput(_amount.text, _currency);
    final BillReminder bill = BillReminder(
      id: initial?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      amount: amount == null
          ? null
          : Money(-amount.minorUnits.abs(), amount.currencyCode),
      dueDate: _dueDate!,
      cadence: _cadence,
      accountId: _accountId,
      streamId: initial?.streamId,
      liabilityAccountId: initial?.liabilityAccountId,
      reminderOffsetDays: [..._offsets]..sort(),
      reminderMinutes: _minutes,
      active: _active,
      autopay: _autopay,
      paidOccurrences: initial?.paidOccurrences ?? const [],
    );
    setState(() => _saving = true);
    try {
      // Saved first, so the sheet's "the bill is saved" is true and leaving the screen
      // while the permission is asked keeps the bill. Turning reminders on is the
      // user's action that asks for the permission.
      await actions.save(bill);
      if (_reminds &&
          !await scheduler.ensurePermission(request: true) &&
          mounted) {
        await showNotificationPermissionSheet(context, scheduler);
      }
      if (mounted) context.pop();
    } on EntityDeletedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.billNotFound)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BillActions actions = ref.read(billActionsProvider);
    final String id = widget.initial!.id;
    // Back where the editor was opened from (the bills, or the screen a reminder's tap
    // left), whose messenger is the one on screen, so the Undo shows; a pushed editor
    // can sit on another tab's stack, whose messenger `go` would leave offstage.
    if (context.canPop()) {
      context.pop();
    } else {
      const BillsRoute().go(context);
    }
    await actions.delete(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.billDeleted),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.restore(id),
        ),
      ),
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
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final String time = material.formatTimeOfDay(
      TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    const SizedBox gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.billNewTitle : l10n.billEditTitle),
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
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.billName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.billNameRequired : null,
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
                labelText: l10n.billAmount,
                helperText: l10n.billAmountHelper,
                helperMaxLines: 3,
                prefixText: currencySymbol(_currency),
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  amountInputError(l10n, v ?? '', _currency, signed: false),
            ),
            gap,
            _pickerField(
              label: l10n.billDueDate,
              value: _dueDate == null
                  ? l10n.billChooseDueDate
                  : shortDateLabel(_dueDate!),
              validator: (_) =>
                  _dueDate == null ? l10n.billChooseDueDate : null,
              onTap: () => _pickDueDate(today),
            ),
            gap,
            DropdownButtonFormField<RecurringCadence?>(
              initialValue: cadenceChoices.contains(_cadence) ? _cadence : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.billRepeats,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final RecurringCadence? c in cadenceChoices)
                  DropdownMenuItem<RecurringCadence?>(
                    value: c,
                    child: Text(
                      cadenceLabel(l10n, c),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (c) => setState(() => _cadence = c),
            ),
            gap,
            DropdownButtonFormField<String?>(
              initialValue: widget.accounts.any((a) => a.id == _accountId)
                  ? _accountId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.billAccount,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(child: Text(l10n.billAnyAccount)),
                for (final Account a in widget.accounts)
                  DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (id) => setState(() => _accountId = id),
            ),
            gap,
            Text(l10n.billReminders, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final int days in reminderOffsetChoices)
                  FilterChip(
                    label: Text(l10n.billReminderOffset(days)),
                    selected: _offsets.contains(days),
                    onSelected: (on) => setState(
                      () => on ? _offsets.add(days) : _offsets.remove(days),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _pickerField(
              label: l10n.billReminderTime,
              value: time,
              onTap: _pickTime,
            ),
            gap,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.billActive),
              subtitle: Text(l10n.billActiveCaption),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.billAutopay),
              subtitle: Text(l10n.billAutopayCaption),
              value: _autopay,
              onChanged: (value) => setState(() => _autopay = value),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
