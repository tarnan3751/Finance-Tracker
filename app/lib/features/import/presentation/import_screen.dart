/// The import screen (`/settings/import` and `/transactions/import`,
/// `docs/reference/import.md`, **The screen**): one flow in steps on one page. It
/// starts with "Choose a CSV file" and the past imports with their undo; a file read
/// goes to the mapping (`import_mapping_view.dart`), the mapping to the review
/// (`import_review_view.dart`), and the review's Import to the result. Back steps back
/// through the flow before it leaves the screen, and is held while a read or a write
/// runs. After every await the screen checks it is still there: a result that arrives
/// once it is gone is dropped.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/csv_picker_provider.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/section_header.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/import/application/import_providers.dart';
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/header_detection.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/import/domain/import_records.dart';
import 'package:finance_tracker/features/import/presentation/import_mapping_view.dart';
import 'package:finance_tracker/features/import/presentation/import_review_view.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

final Logger _log = Logger('import');

enum _Step { start, mapping, review, done }

/// The import flow.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _Step _step = _Step.start;
  bool _busy = false;
  String? _error;
  PickedCsv? _file;
  CsvTable? _table;
  MappingDraft? _draft;
  ImportReview? _review;
  bool _includeDuplicates = false;
  ImportResult? _result;

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  Future<void> _pick() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ImportActions actions = ref.read(importActionsProvider);
    final BackupPicker picker = ref.read(csvPickerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final PickedCsv? file = await actions.pick(picker);
      if (!mounted) return;
      if (file == null) {
        setState(() => _busy = false);
        return;
      }
      final CsvTable table = await actions.read(file);
      if (!mounted) return;
      final int? header = findHeaderRow(table.rows);
      if (header == null) throw const ImportNoTableException();
      final MappingDraft? draft = await _draftFor(table, header);
      if (draft == null || !mounted) return;
      setState(() {
        _file = file;
        _table = table;
        _draft = draft;
        _step = _Step.mapping;
        _busy = false;
      });
    } on ImportTooLargeException {
      _fail(l10n.importTooLarge);
    } on BackupPickFailedException {
      _fail(l10n.importPickFailed);
    } on FormatException {
      _fail(l10n.importUnreadable);
    } on ImportNoTableException {
      _fail(l10n.importNoTable);
    }
  }

  // The mapping to start with for [table]'s header at [header]: the preset saved for
  // that header, else nothing mapped, with the formats detected; null when the screen
  // has gone meanwhile.
  Future<MappingDraft?> _draftFor(CsvTable table, int header) async {
    final ImportPreset? preset = await ref
        .read(importActionsProvider)
        .presetFor(table.rows[header]);
    if (!mounted) return null;
    final MappingDraft blank = MappingDraft(
      headerRow: header,
      newCurrency: defaultCurrencyCode(),
      separator: table.delimiter == ';'
          ? DecimalSeparator.comma
          : DecimalSeparator.point,
    );
    if (preset == null) return _detected(blank, table);
    final ImportMapping m = preset.mappingFor(table.rows[header]);
    final List<Account> accounts = await ref.read(accountsProvider.future);
    if (!mounted) return null;
    final MappingDraft draft = _detected(
      blank.copyWith(columns: m.columns, debitCredit: m.debitCredit),
      table,
    );
    return draft.copyWith(
      dateFormat: m.dateFormat,
      separator: m.separator,
      separatorDetected: true,
      outflowsNegative: m.outflowsNegative,
      accountId: accounts.any((a) => a.id == preset.accountId)
          ? preset.accountId
          : null,
      presetApplied: true,
    );
  }

  // [draft] with the date formats detected from its date column, and the decimal
  // separator from its amount columns when they say which.
  MappingDraft _detected(MappingDraft draft, CsvTable table) {
    List<String> values(ImportRole role) => switch (draft.columns[role]) {
      final int c => columnValues(table, draft.headerRow, c),
      null => const [],
    };
    final List<ImportDateFormat> candidates = detectDateFormats(
      values(ImportRole.date),
    );
    final ImportDateFormat? format = candidates.contains(draft.dateFormat)
        ? draft.dateFormat
        : preferredDateFormat(
            candidates,
            localePattern: DateFormat.yMd().pattern ?? '',
          );
    final DecimalSeparator? separator = detectDecimalSeparator([
      for (final ImportRole role
          in draft.debitCredit
              ? const [ImportRole.debit, ImportRole.credit]
              : const [ImportRole.amount])
        ...values(role),
    ]);
    return draft.copyWith(
      dateCandidates: candidates,
      dateFormat: format,
      separator: separator ?? draft.separator,
      separatorDetected: separator != null,
    );
  }

  void _changed(MappingDraft next) {
    final MappingDraft? previous = _draft;
    final CsvTable? table = _table;
    if (previous == null || table == null) return;
    bool moved(ImportRole role) => previous.columns[role] != next.columns[role];
    final bool dates = moved(ImportRole.date);
    final bool amounts =
        previous.debitCredit != next.debitCredit ||
        moved(ImportRole.amount) ||
        moved(ImportRole.debit) ||
        moved(ImportRole.credit);
    MappingDraft draft = next;
    if (dates || amounts) {
      final MappingDraft detected = _detected(next, table);
      draft = next.copyWith(
        dateCandidates: dates ? detected.dateCandidates : null,
        dateFormat: dates ? detected.dateFormat : next.dateFormat,
        separator: amounts && detected.separatorDetected
            ? detected.separator
            : null,
        separatorDetected: amounts ? detected.separatorDetected : null,
      );
    }
    setState(() => _draft = draft);
  }

  Future<void> _headerRow(int row) async {
    final CsvTable? table = _table;
    if (table == null) return;
    final MappingDraft? draft = await _draftFor(table, row);
    if (draft != null && mounted) setState(() => _draft = draft);
  }

  Future<void> _delimiter(String delimiter) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PickedCsv? file = _file;
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final CsvTable table = await ref
          .read(importActionsProvider)
          .read(file, delimiter: delimiter);
      if (!mounted) return;
      final int header = findHeaderRow(table.rows) ?? 0;
      if (table.rows.length < 2) throw const ImportNoTableException();
      final MappingDraft? draft = await _draftFor(table, header);
      if (draft == null || !mounted) return;
      setState(() {
        _table = table;
        _draft = draft;
        _busy = false;
        _error = null;
      });
    } on FormatException {
      _fail(l10n.importUnreadable);
    } on ImportNoTableException {
      _fail(l10n.importNoTable);
    }
  }

  Future<void> _toReview() async {
    final PickedCsv? file = _file;
    final CsvTable? table = _table;
    final MappingDraft? draft = _draft;
    final ImportMapping? mapping = draft?.mapping;
    if (file == null || table == null || draft == null || mapping == null) {
      return;
    }
    final ImportTarget target;
    if (draft.newAccount) {
      target = NewAccount(
        name: draft.newName.trim(),
        type: draft.newType,
        currencyCode: draft.newCurrency,
      );
    } else {
      final Account? account = ref.read(accountsByIdProvider)[draft.accountId];
      if (account == null) return;
      target = ExistingAccount(account);
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ImportReview review;
    try {
      review = await ref
          .read(importActionsProvider)
          .review(
            file: file,
            table: table,
            headerRow: draft.headerRow,
            mapping: mapping,
            target: target,
          );
    } on Object catch (e) {
      // Only the type: a message could carry a name or an amount.
      _log.warning('the import was not reviewed: ${e.runtimeType}');
      _fail(l10n.importReviewFailed);
      return;
    }
    if (!mounted) return;
    setState(() {
      _review = review;
      _includeDuplicates = false;
      _step = _Step.review;
      _busy = false;
    });
  }

  Future<void> _import() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ImportReview? review = _review;
    if (review == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ImportResult result = await ref
          .read(importActionsProvider)
          .write(review, includeDuplicates: _includeDuplicates);
      if (!mounted) return;
      ref.invalidate(importHistoryProvider);
      setState(() {
        _result = result;
        _step = _Step.done;
        _busy = false;
      });
    } on Object catch (e) {
      // Only the type: a message could carry a name or an amount.
      _log.warning('the import was not written: ${e.runtimeType}');
      _fail(l10n.importFailed);
    }
  }

  void _restart() => setState(() {
    _step = _Step.start;
    _file = null;
    _table = null;
    _draft = null;
    _review = null;
    _result = null;
    _error = null;
  });

  void _back() {
    switch (_step) {
      case _Step.review:
        setState(() {
          _step = _Step.mapping;
          _error = null;
        });
      case _Step.mapping:
        _restart();
      case _Step.start || _Step.done:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool inFlow = _step == _Step.mapping || _step == _Step.review;
    // Watched for the whole flow, so the preset's account is known when a file is read.
    final List<Account> accounts =
        ref.watch(accountsProvider).value ?? const [];
    return PopScope(
      canPop: !inFlow && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.importTitle),
          bottom: _busy
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: switch (_step) {
          _Step.mapping => ImportMappingView(
            table: _table!,
            draft: _draft!,
            accounts: accounts,
            busy: _busy,
            error: _error,
            onChanged: _changed,
            onHeaderRow: _headerRow,
            onDelimiter: _delimiter,
            onReview: _toReview,
          ),
          _Step.review => ImportReviewView(
            review: _review!,
            includeDuplicates: _includeDuplicates,
            busy: _busy,
            error: _error,
            onIncludeDuplicates: (v) => setState(() => _includeDuplicates = v),
            onImport: _import,
          ),
          _Step.start || _Step.done => _StartView(
            busy: _busy,
            error: _error,
            result: _step == _Step.done ? _result : null,
            onPick: _pick,
            onRestart: _restart,
          ),
        },
      ),
    );
  }
}

/// The start, or the result of an import, over the past imports.
class _StartView extends ConsumerStatefulWidget {
  const _StartView({
    required this.busy,
    required this.error,
    required this.result,
    required this.onPick,
    required this.onRestart,
  });

  final bool busy;
  final String? error;
  final ImportResult? result;
  final VoidCallback onPick;
  final VoidCallback onRestart;

  @override
  ConsumerState<_StartView> createState() => _StartViewState();
}

class _StartViewState extends ConsumerState<_StartView> {
  // The import being undone, whose button waits.
  String? _undoing;

  Future<void> _undo(ImportBatch batch) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final ImportActions actions = ref.read(importActionsProvider);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importUndoTitle),
        content: Text(l10n.importUndoBody(batch.count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: AppTheme.destructive(context),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.importUndoConfirm),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _undoing = batch.id);
    try {
      await actions.undo(batch);
      if (!mounted) return;
      ref.invalidate(importHistoryProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.importUndone)));
    } on Object catch (e) {
      _log.warning('the import was not undone: ${e.runtimeType}');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.importUndoFailed)));
    } finally {
      if (mounted) setState(() => _undoing = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = widget.busy || _undoing != null;
    final String? error = widget.error;
    final VoidCallback onPick = widget.onPick;
    final VoidCallback onRestart = widget.onRestart;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<ImportBatch> history =
        ref.watch(importHistoryProvider).value ?? const [];
    final ImportResult? done = widget.result;
    final tz.Location zone = ref.watch(clockProvider).location;
    return ListView(
      padding: const EdgeInsets.only(bottom: SpendthriftTokens.space24),
      children: [
        Padding(
          padding: const EdgeInsets.all(SpendthriftTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (done == null) ...[
                Text(l10n.importIntro),
                const SizedBox(height: SpendthriftTokens.space16),
                FilledButton.icon(
                  onPressed: busy ? null : onPick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.importChooseFile),
                ),
              ] else ...[
                Text(
                  l10n.importResult(done.batch.count, done.account.name),
                  style: theme.textTheme.titleMedium,
                ),
                if (done.skipped > 0)
                  Text(l10n.importResultSkipped(done.skipped)),
                if (!done.historySaved) Text(l10n.importHistoryNotSaved),
                const SizedBox(height: SpendthriftTokens.space16),
                FilledButton(
                  onPressed: () =>
                      AccountDetailRoute(done.account.id).push<void>(context),
                  child: Text(l10n.importViewAccount),
                ),
                const SizedBox(height: SpendthriftTokens.space8),
                OutlinedButton(
                  onPressed: onRestart,
                  child: Text(l10n.importAnother),
                ),
              ],
              if (error case final String message) ...[
                const SizedBox(height: SpendthriftTokens.space16),
                Text(message, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
        SectionHeader(l10n.importHistorySection),
        if (history.isEmpty)
          EmptyState(
            icon: Icons.history,
            headline: l10n.importHistoryEmpty,
            body: l10n.importHistoryEmptyBody,
          ),
        for (final ImportBatch batch in history)
          ListTile(
            title: Text(batch.fileName ?? l10n.importHistoryUnnamed),
            subtitle: Text(
              batch.undoneAt == null
                  ? l10n.importHistorySubtitle(
                      batch.count,
                      shortDateLabel(_localDate(batch.importedAt, zone)),
                    )
                  : l10n.importHistoryUndoneSubtitle(
                      batch.count,
                      shortDateLabel(_localDate(batch.importedAt, zone)),
                    ),
            ),
            trailing: batch.undoneAt == null && batch.count > 0
                ? TextButton(
                    onPressed: busy ? null : () => _undo(batch),
                    child: Text(l10n.importUndo),
                  )
                : null,
          ),
      ],
    );
  }
}

// The local date in [zone] of the UTC instant [at].
LocalDate _localDate(DateTime at, tz.Location zone) =>
    LocalDate.fromDateTime(tz.TZDateTime.from(at, zone));
