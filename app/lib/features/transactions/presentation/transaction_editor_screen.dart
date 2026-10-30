/// The transaction editor, which is also a transaction's detail: expense or income, the
/// amount (parsed in the device locale for the account's currency, never rounded), the
/// account, the date (today by default, in the device zone), the description, the
/// category, the splits, notes and tags. A new transaction is `manual`; an edited one
/// keeps its source. With no category of the user's own, the category row shows the one
/// its Plaid code resolves to, captioned as the bank's. Splits (category and unsigned
/// amount rows, signed like the transaction) must add up to its amount before Save
/// takes them, unless no row was edited and the amount is as stored, when the stored
/// splits are saved back as they are; "Distribute evenly" divides it with the larger
/// parts last; with splits the category row reads "Split across N categories" and Save
/// clears the single category, which removing every split brings back. A receipt photo
/// is taken or chosen through the image source, shown as a thumbnail (a tap opens it
/// full screen), replaced or removed, and saved with Save; one whose photo is on another
/// device says so. Deleting from here offers an undo for five seconds, after which the
/// receipt photo goes too; a Plaid transaction has no Delete, since only the bank
/// removes one. "Run rules on this transaction" (the overflow menu) applies the user's
/// rules to the values in the form, which Save then keeps like any edit. "Hidden" (the
/// overflow menu, checked when on) hides the transaction from the list, budgets and
/// reports, saved with Save.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/router/own_page.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/split_math.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:finance_tracker/features/transactions/presentation/amount_input.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
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
  /// What the form edits: the screen's entity, or once a save has landed, the saved
  /// one, so a later Save rewrites it rather than creating another.
  late Transaction? _initial = widget.initial;

  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late bool _income = _initial?.amount.isPositive ?? false;
  late final TextEditingController _amount = TextEditingController(
    text: _initial?.amount.abs().format(symbol: false),
  );
  late String _accountId = widget.accountId;
  late LocalDate _date = _initial?.date ?? ref.read(todayProvider);
  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  late String? _categoryId = _initial?.userCategoryId;
  late final TextEditingController _notes = TextEditingController(
    text: _initial?.notes,
  );
  late List<String> _tags = [...?_initial?.tags];
  late final List<_SplitRow> _splits = [
    for (final TransactionSplit split
        in _initial?.splits ?? const <TransactionSplit>[])
      _SplitRow(
        categoryId: split.categoryId,
        amount: split.amount.abs().format(symbol: false),
        note: split.note,
      ),
  ];
  final GlobalKey<FormFieldState<void>> _splitsField =
      GlobalKey<FormFieldState<void>>();
  // Whether a split row was edited, added or removed.
  bool _splitsEdited = false;
  late bool _hidden = _initial?.hidden ?? false;
  ReceiptChange _receipt = const KeepReceipt();
  final TextEditingController _tagInput = TextEditingController();
  bool _saving = false;

  bool get _isNew => _initial == null;

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
    for (final _SplitRow row in _splits) {
      row.amount.dispose();
    }
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

  // The transaction's magnitude as typed, or null while it is not a valid amount.
  Money? get _magnitude {
    final Money? amount = parseAmountInput(_amount.text, _currency);
    return amount == null || amount.isNegative ? null : amount;
  }

  // Row [row]'s magnitude as typed, or null while it is not a valid amount.
  Money? _splitMagnitude(_SplitRow row) {
    final Money? amount = parseAmountInput(row.amount.text, _currency);
    return amount == null || amount.isNegative ? null : amount;
  }

  // The transaction's amount as typed, signed, or null while it is not valid.
  Money? get _signedAmount {
    final Money? magnitude = _magnitude;
    return magnitude == null || _income ? magnitude : -magnitude;
  }

  // Whether Save keeps the stored splits as they are: no row was edited, added or
  // removed and the amount is the stored one (its currency included). They are then
  // not held to the sum rule, so splits of mixed signs (synced or imported) or a gap
  // the bank's amount change left never block an unrelated edit.
  bool get _keepsStoredSplits {
    final Transaction? initial = _initial;
    return !_splitsEdited &&
        initial != null &&
        initial.splits.isNotEmpty &&
        _signedAmount == initial.amount;
  }

  // Applies [change] to the splits and, once Save has shown an error on them, checks
  // them again so the error follows the edit. [edit] is false when only the amount
  // they are measured against changed.
  void _editSplits(VoidCallback change, {bool edit = true}) {
    if (edit) _splitsEdited = true;
    setState(change);
    if (_splitsField.currentState?.hasError ?? false) {
      _splitsField.currentState!.validate();
    }
  }

  void _addSplit() => _editSplits(() => _splits.add(_SplitRow()));

  void _removeSplit(_SplitRow row) {
    _editSplits(() => _splits.remove(row));
    // Its field is still mounted until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.amount.dispose());
  }

  Future<void> _pickSplitCategory(_SplitRow row) async {
    final CategoryChoice? choice = await showCategoryPicker(
      context,
      selectedId: row.categoryId,
      allowNone: false,
    );
    if (choice != null && mounted) {
      _editSplits(() => row.categoryId = choice.categoryId);
    }
  }

  // Divides the amount across the rows, the larger parts last.
  void _distributeEvenly() {
    final Money? total = _magnitude;
    if (total == null) return;
    final List<Money> parts = distributeEvenly(total, _splits.length);
    _editSplits(() {
      for (int i = 0; i < _splits.length; i++) {
        _splits[i].amount.text = parts[i].format(symbol: false);
      }
    });
  }

  // The split section's error: a row without a category, or splits that do not add up.
  // A row whose amount does not parse shows its own error.
  String? _splitsError(AppLocalizations l10n) {
    if (_splits.isEmpty || _keepsStoredSplits) return null;
    if (_splits.any((row) => row.categoryId == null)) {
      return l10n.splitCategoryRequired;
    }
    final Money? total = _magnitude;
    final List<Money?> parts = [
      for (final row in _splits) _splitMagnitude(row),
    ];
    if (total == null || parts.contains(null)) return null;
    return splitsBalance(total, parts.cast<Money>())
        ? null
        : l10n.splitMustBalance(total.format());
  }

  // What [initial]'s stored splits leave of its amount, in the amount's direction.
  static Money _storedGap(Transaction initial) {
    final Money gap =
        initial.amount -
        Money.sum(
          initial.splits.map((s) => s.amount),
          currencyCode: initial.amount.currencyCode,
        );
    return initial.amount.isNegative ? -gap : gap;
  }

  // Takes or chooses a photo through the image source; it becomes the receipt on Save.
  Future<void> _pickReceipt({required bool camera}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ImageSource source = ref.read(imageSourceProvider);
    try {
      // The camera and the picker are activities of their own: the lock stays open.
      final PickedImage? image = await ref
          .read(lockHoldProvider)
          .holdOpen(
            () => camera ? source.pickFromCamera() : source.pickFromGallery(),
          );
      if (image != null && mounted) {
        setState(() => _receipt = AttachReceipt(image.bytes));
      }
    } on NoCameraException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.receiptNoCamera)));
    } on ImagePickFailedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.receiptPickFailed)));
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
    Money signed(Money magnitude) => _income ? magnitude : -magnitude;
    final Money magnitude = parseAmountInput(_amount.text, _currency)!;
    final String notes = _notes.text.trim();
    final List<TransactionSplit> splits = _keepsStoredSplits
        ? _initial!.splits
        : [
            for (final _SplitRow row in _splits)
              TransactionSplit(
                categoryId: row.categoryId!,
                amount: signed(parseAmountInput(row.amount.text, _currency)!),
                note: row.note,
              ),
          ];
    return (
      accountId: _accountId,
      amount: signed(magnitude),
      date: _date,
      name: _name.text.trim(),
      // A split transaction is categorized by its splits.
      categoryId: splits.isEmpty ? _categoryId : null,
      notes: notes.isEmpty ? null : notes,
      tags: _tags,
      splits: splits,
      hidden: _hidden,
      receipt: _receipt,
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
        (_initial ??
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
              splits: draft.splits,
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
        // A rule sets no category on a split transaction; the earlier choice stays.
        if (_splits.isEmpty) _categoryId = changed.userCategoryId;
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
    final OwnPage page = OwnPage.of(context);
    final TransactionDraft draft = _draft();
    setState(() => _saving = true);
    try {
      final Transaction? initial = _initial;
      final Transaction stored = initial == null
          ? await actions.create(draft)
          : await actions.update(initial, draft);
      if (mounted) {
        setState(() => _initial = stored);
        // A replaced photo keeps its path: the next read must not be the old one.
        if (draft.receipt is! KeepReceipt) {
          ref
            ..invalidate(localReceiptProvider)
            ..invalidate(receiptProvider);
        }
        page.close();
      }
    } on FileSystemException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.receiptSaveFailed)));
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
    final String id = _initial!.id;
    final bool hasReceipt = _initial!.receiptPath != null;
    context.pop();
    await actions.delete(id);
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> undo =
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
    // The photo goes once the delete is final: the undo closed by anything but Undo.
    if (hasReceipt) {
      unawaited(
        undo.closed.then((reason) async {
          if (reason != SnackBarClosedReason.action) {
            await actions.discardReceiptOf(id);
          }
        }),
      );
    }
  }

  // The split section: "Add split" alone while there are none; else the rows, the
  // running unallocated line (or the error that refuses Save), and the actions.
  Widget _buildSplits(
    AppLocalizations l10n,
    ThemeData theme,
    CategoryLookup categories,
  ) => FormField<void>(
    key: _splitsField,
    validator: (_) => _splitsError(l10n),
    builder: (field) {
      final Widget add = TextButton.icon(
        onPressed: _addSplit,
        icon: const Icon(Icons.add),
        label: Text(l10n.splitAdd),
      );
      if (_splits.isEmpty) {
        return Align(alignment: AlignmentDirectional.centerStart, child: add);
      }
      final Money? total = _magnitude;
      final Transaction? initial = _initial;
      final Money? left = _keepsStoredSplits
          // The stored splits as signed: what they leave of the amount, positive when
          // they fall short of it.
          ? _storedGap(initial!)
          : total == null
          ? null
          : unallocated(total, [
              for (final _SplitRow row in _splits)
                _splitMagnitude(row) ?? Money.zero(_currency),
            ]);
      final String? error = field.errorText;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(l10n.splitsTitle, style: theme.textTheme.titleSmall),
          for (final _SplitRow row in _splits)
            _SplitRowFields(
              key: ObjectKey(row),
              row: row,
              category: categories.byId[row.categoryId],
              currency: _currency,
              onPickCategory: () => _pickSplitCategory(row),
              onChanged: () => _editSplits(() {}),
              onRemove: () => _removeSplit(row),
            ),
          const SizedBox(height: 8),
          if (error != null || left != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error ??
                    (left!.isNegative
                        ? l10n.splitOverAllocated((-left).format())
                        : l10n.splitUnallocated(left.format())),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              add,
              TextButton.icon(
                onPressed: total == null || total.isZero
                    ? null
                    : _distributeEvenly,
                icon: const Icon(Icons.balance),
                label: Text(l10n.splitDistribute),
              ),
            ],
          ),
        ],
      );
    },
  );

  // The receipt section: the photo picked in this session, else the stored one (fetched
  // from the server on this first view when only its hash is here, or that it is on
  // another device), else the buttons to add one.
  Widget _buildReceipt() {
    final ReceiptChange change = _receipt;
    final Transaction? initial = _initial;
    final String? stored = initial?.receiptPath;
    final String? hash = initial?.receiptSha256;
    final bool kept = change is KeepReceipt && stored != null;
    // The photo here first; only when it is not (and its hash is known), the fetch.
    final AsyncValue<Uint8List?>? local = kept
        ? ref.watch(localReceiptProvider(initial!.id, hash))
        : null;
    final ReceiptProvider? fetch =
        kept && hash != null && local!.hasValue && local.value == null
        ? receiptProvider(initial!.id, hash)
        : null;
    final AsyncValue<Uint8List?>? fetched = fetch == null
        ? null
        : ref.watch(fetch);
    final AsyncValue<Uint8List?>? read = fetched ?? local;
    final bool localFailed =
        local != null && !local.isLoading && local.hasError;
    return ReceiptSection(
      bytes: switch (change) {
        AttachReceipt(:final Uint8List bytes) => bytes,
        KeepReceipt() => read?.value,
        RemoveReceipt() => null,
      },
      // Without a hash, a photo that cannot be read is as good as not on this device.
      missing:
          hash == null &&
          local != null &&
          (local.hasError || local.hasValue && local.value == null),
      // A retry shows the spinner again, not the last failure.
      loading: read != null && read.isLoading,
      downloading: fetched != null,
      // A failed read of the file here, when the hash says what it should be, is a
      // failure to retry like a failed fetch.
      fetchFailure: hash != null && local != null && localFailed
          ? ReceiptFetchFailure.failed
          : fetched == null || fetched.isLoading || !fetched.hasError
          ? null
          : fetched.error is NotFound
          ? ReceiptFetchFailure.notOnServer
          : ReceiptFetchFailure.failed,
      onRetry: () => fetch == null
          ? ref.invalidate(localReceiptProvider(initial!.id, hash))
          : ref.invalidate(fetch),
      onTakePhoto: () => _pickReceipt(camera: true),
      onChoosePhoto: () => _pickReceipt(camera: false),
      onRemove: () => setState(
        () => _receipt = stored == null
            ? const KeepReceipt()
            : const RemoveReceipt(),
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
    final Transaction? initial = _initial;
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
              // The splits' unallocated line follows the amount.
              onChanged: (_) {
                if (_splits.isNotEmpty) _editSplits(() {}, edit: false);
              },
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
            if (_splits.isNotEmpty)
              // The splits are the category; the section below edits them.
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.call_split,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(l10n.transactionCategory),
                subtitle: Text(l10n.transactionSplitAcross(_splits.length)),
              )
            else
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
            _buildSplits(l10n, theme, categories),
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
            const SizedBox(height: 8),
            _buildReceipt(),
          ],
        ),
      ),
    );
  }
}

// One split row of the form: its category, its amount as typed, and its note, which the
// editor keeps without showing it.
final class _SplitRow {
  _SplitRow({this.categoryId, String amount = '', this.note})
    : amount = TextEditingController(text: amount);

  String? categoryId;
  final TextEditingController amount;
  final String? note;
}

// A split row's fields: the category (the picker) above the unsigned amount, and the
// row's remove button.
class _SplitRowFields extends StatelessWidget {
  const _SplitRowFields({
    super.key,
    required this.row,
    required this.category,
    required this.currency,
    required this.onPickCategory,
    required this.onChanged,
    required this.onRemove,
  });

  final _SplitRow row;

  /// The row's category when it names a live one.
  final Category? category;
  final String currency;
  final VoidCallback onPickCategory;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Category? category = this.category;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  title: Text(
                    category?.name ??
                        (row.categoryId == null
                            ? l10n.splitChooseCategory
                            : l10n.uncategorized),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onPickCategory,
                ),
                TextFormField(
                  controller: row.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.splitAmount,
                    prefixText: currencySymbol(currency),
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => amountInputError(
                    l10n,
                    value ?? '',
                    currency,
                    required: true,
                    signed: false,
                    nonZero: true,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.splitRemove,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
