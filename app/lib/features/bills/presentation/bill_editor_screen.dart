/// The bill editor, for `/bills/new` and `/bills/:id` (`docs/reference/bills.md`,
/// **Screens**): the name, the expected amount in a currency of the accounts, the first
/// due date, how often it repeats, the account it is paid from, the reminders (the days
/// before and the time of day), whether it is active and on autopay. Turning reminders on
/// asks for the notification permission when the app lacks it, and explains a refusal
/// (`notification_permission_sheet.dart`). Deleting from here offers an undo. A new bill
/// opened for a recurring stream or a liability starts from its suggestion (name, amount,
/// cadence, next due date, account and the link), and is saved only by Save.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_suggestions.dart';
import 'package:finance_tracker/features/bills/presentation/notification_permission_sheet.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

final Logger _log = Logger('bills');

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

/// The editor of bill [billId], or of a new bill when it is null: prefilled from the
/// suggestion of stream [streamId] or of the liability on [liabilityAccountId] when there
/// is one.
class BillEditorScreen extends ConsumerWidget {
  const BillEditorScreen({
    super.key,
    this.billId,
    this.streamId,
    this.liabilityAccountId,
  });

  final String? billId;

  /// The recurring stream a new bill is made from.
  final String? streamId;

  /// The account of the liability a new bill is made from.
  final String? liabilityAccountId;

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
    if (id == null) {
      final String? stream = streamId;
      final String? liabilityAccount = liabilityAccountId;
      if (stream == null && liabilityAccount == null) {
        return _BillForm(initial: null, accounts: accounts);
      }
      ref.listen(suggestedBillsProvider, (_, next) {
        if (next case AsyncError(:final error)) {
          _log.warning('bill suggestions not read: ${error.runtimeType}');
        }
      });
      final AsyncValue<List<BillSuggestion>> suggested = ref.watch(
        suggestedBillsProvider,
      );
      // An error leaves the form empty rather than waiting for ever.
      final List<BillSuggestion>? suggestions = suggested.hasError
          ? const []
          : suggested.value;
      if (suggestions == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final BillSuggestion? suggestion = suggestions
          .where(
            (s) => switch (s) {
              StreamBillSuggestion(stream: SourceStream(:final id)) =>
                id == stream,
              LiabilityBillSuggestion(:final liability) =>
                liability.accountId == liabilityAccount,
            },
          )
          .firstOrNull;
      // Built once: the form keeps what the user changes after a suggestion changes.
      return _BillForm(
        key: ValueKey('$stream/$liabilityAccount'),
        initial: null,
        // Its id is not used: Save gives the new bill its own.
        draft: suggestion?.accept(''),
        accounts: accounts,
      );
    }
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
  const _BillForm({
    super.key,
    required this.initial,
    this.draft,
    required this.accounts,
  });

  /// The bill being edited, or null for a new one.
  final BillReminder? initial;

  /// What a new bill starts from, or null for an empty one.
  final BillReminder? draft;

  final List<Account> accounts;

  @override
  ConsumerState<_BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<_BillForm> {
  /// What the form edits: the screen's entity, or once a save has landed, the saved
  /// one, so a later Save rewrites it rather than creating another.
  late BillReminder? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  /// What the fields start from: the bill edited, else the draft.
  late final BillReminder? _start = widget.initial ?? widget.draft;
  late final TextEditingController _name = TextEditingController(
    text: _start?.name,
  );
  late final TextEditingController _amount = TextEditingController(
    text: switch (_start?.amount) {
      final Money m => Money(
        m.minorUnits.abs(),
        m.currencyCode,
      ).format(symbol: false),
      null => null,
    },
  );
  late String _currency = _start?.amount?.currencyCode ?? _currencies.first;
  late LocalDate? _dueDate = _start?.dueDate;
  late RecurringCadence? _cadence = _start == null
      ? RecurringCadence.monthly
      : _start.cadence;
  late String? _accountId = _start?.accountId;
  late final Set<int> _offsets = {
    ..._start?.reminderOffsetDays ?? const [2],
  };
  late int _minutes = _start?.reminderMinutes ?? defaultReminderMinutes;
  late bool _active = _start?.active ?? true;
  late bool _autopay = _start?.autopay ?? false;
  bool _saving = false;

  bool get _isNew => _initial == null;

  /// The bill's id: the edited one's, else one made once for the new bill.
  late final String _id = widget.initial?.id ?? const Uuid().v4();

  /// Whether the bill as edited would remind the user.
  bool get _reminds => _active && _offsets.isNotEmpty;

  /// The accounts' currencies and the bill's own, the device's default when there is
  /// neither.
  List<String> get _currencies {
    final List<String> codes = {
      for (final Account a in widget.accounts) a.currencyCode,
      ?_start?.amount?.currencyCode,
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
    final NotificationPermission permission = ref.read(
      notificationPermissionProvider,
    );
    final BillReminder? initial = _initial;
    final Money? amount = _amount.text.trim().isEmpty
        ? null
        : parseAmountInput(_amount.text, _currency);
    final BillReminder bill = BillReminder(
      id: _id,
      name: _name.text.trim(),
      amount: amount == null
          ? null
          : Money(-amount.minorUnits.abs(), amount.currencyCode),
      dueDate: _dueDate!,
      cadence: _cadence,
      accountId: _accountId,
      streamId: _start?.streamId,
      liabilityAccountId: _start?.liabilityAccountId,
      reminderOffsetDays: [..._offsets]..sort(),
      reminderMinutes: _minutes,
      active: _active,
      autopay: _autopay,
      paidOccurrences: initial?.paidOccurrences ?? const [],
    );
    final OwnPage page = OwnPage.of(context);
    setState(() => _saving = true);
    try {
      // Saved first, so the sheet's "the bill is saved" is true and leaving the screen
      // while the permission is asked keeps the bill. Turning reminders on is the
      // user's action that asks for the permission.
      await actions.save(bill);
      if (mounted) setState(() => _initial = bill);
      // Asked once on this device (`NotificationPermission`), and only while the editor is
      // what the user sees; once refused, the sheet points to the system's settings.
      if (_reminds &&
          page.isTop &&
          !await permission.ask() &&
          mounted &&
          page.isTop) {
        await showNotificationPermissionSheet(context, scheduler);
      }
      page.close();
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
    final String id = _initial!.id;
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
