/// What the import flow does (`docs/reference/import.md`): picks and reads the file,
/// offers the preset for its header, reviews what its rows will be, writes them, and
/// keeps and undoes the record of each import. The screen holds the flow's state; this
/// is its work.
///
/// Logs carry counts and exception types only: never a file name, a name or an amount.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart'
    show ArrivalProcessor;
import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_duplicates.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/import/domain/import_records.dart';
import 'package:finance_tracker/features/import/domain/row_conversion.dart';
import 'package:finance_tracker/features/lock/application/lock_hold.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

part 'import_providers.g.dart';

final Logger _log = Logger('import');

/// The largest file an import reads, bytes.
const int maxImportBytes = 20 * 1024 * 1024;

/// Files larger than this, bytes, are parsed in an isolate.
const int importIsolateThreshold = 256 * 1024;

/// How long a `pending` import whose rows have not landed is left for its write to
/// finish before the history drops it.
const Duration pendingGrace = Duration(minutes: 2);

/// How much of the picked file one read takes, bytes.
const int importReadChunk = 1024 * 1024;

/// The picked file is over [maxImportBytes].
final class ImportTooLargeException implements Exception {
  /// The exception.
  const ImportTooLargeException();

  @override
  String toString() => 'ImportTooLargeException';
}

/// The file holds no table: no row is a header ([findHeaderRow]).
final class ImportNoTableException implements Exception {
  /// The exception.
  const ImportNoTableException();

  @override
  String toString() => 'ImportNoTableException';
}

/// A file picked for an import, read whole.
final class PickedCsv {
  /// The file [name]d, of [bytes], whose SHA-256 is [sha256].
  const PickedCsv({
    required this.bytes,
    required this.name,
    required this.sha256,
  });

  final Uint8List bytes;
  final String? name;

  /// Its SHA-256, lower-case hex.
  final String sha256;
}

/// Where the rows go: an existing account, or a new manual one.
sealed class ImportTarget {
  const ImportTarget();

  /// The account's currency, the import's.
  String get currencyCode;
}

/// The live account [account].
final class ExistingAccount extends ImportTarget {
  const ExistingAccount(this.account);

  final Account account;

  @override
  String get currencyCode => account.currencyCode;
}

/// A manual account to create, [name]d, of [type], in [currencyCode].
final class NewAccount extends ImportTarget {
  const NewAccount({
    required this.name,
    required this.type,
    required this.currencyCode,
  });

  final String name;
  final AccountType type;

  @override
  final String currencyCode;
}

/// What an import will write: the rows as transactions, which of them are likely
/// duplicates, the rows skipped, and whether this file was imported before.
final class ImportReview {
  /// The review, its summaries with and without the duplicates computed once.
  ImportReview({
    required this.file,
    required this.target,
    required this.incoming,
    required this.duplicates,
    required this.failures,
    required this.importedBefore,
    required this.lossy,
    required this.preset,
  }) : _withDuplicates = _summarize(incoming, const {}, target.currencyCode),
       _withoutDuplicates = _summarize(
         incoming,
         duplicates,
         target.currencyCode,
       );

  final PickedCsv file;
  final ImportTarget target;

  /// The rows as transactions, in the file's order, on the target account (on a new
  /// account, an id it does not have yet).
  final List<Transaction> incoming;

  /// The ids of [incoming] that are likely duplicates.
  final Set<String> duplicates;
  final List<RowFailure> failures;

  /// Whether a live import of a file with this SHA-256 is recorded.
  final bool importedBefore;

  /// Whether the file was read in the 8-bit fallback.
  final bool lossy;

  /// The preset this import saves when it is written.
  final ImportPreset preset;

  final ImportSummary _withDuplicates;
  final ImportSummary _withoutDuplicates;

  /// The transactions written with [includeDuplicates] or without the duplicates.
  List<Transaction> toWrite({required bool includeDuplicates}) => [
    for (final Transaction t in incoming)
      if (includeDuplicates || !duplicates.contains(t.id)) t,
  ];

  /// What [toWrite] gives, summed.
  ImportSummary summary({required bool includeDuplicates}) =>
      includeDuplicates ? _withDuplicates : _withoutDuplicates;
}

/// How many rows an import writes, their first and last dates, and the money in and out.
typedef ImportSummary = ({
  int count,
  LocalDate? first,
  LocalDate? last,
  Money moneyIn,
  Money moneyOut,
});

ImportSummary _summarize(
  List<Transaction> incoming,
  Set<String> left,
  String currencyCode,
) {
  int count = 0;
  LocalDate? first, last;
  Money moneyIn = Money.zero(currencyCode), moneyOut = Money.zero(currencyCode);
  for (final Transaction t in incoming) {
    if (left.contains(t.id)) continue;
    count++;
    if (first == null || t.date.isBefore(first)) first = t.date;
    if (last == null || t.date.isAfter(last)) last = t.date;
    if (t.amount.isNegative) {
      moneyOut += t.amount;
    } else {
      moneyIn += t.amount;
    }
  }
  return (
    count: count,
    first: first,
    last: last,
    moneyIn: moneyIn,
    moneyOut: moneyOut,
  );
}

/// The values under [column] in [table]'s rows after [headerRow], blank ones left out.
List<String> columnValues(CsvTable table, int headerRow, int column) => [
  for (final List<String> row in table.rows.skip(headerRow + 1))
    if (column < row.length && row[column].trim().isNotEmpty) row[column],
];

/// The date format to start with among [candidates] ([detectDateFormats]'s): the only
/// one, or, when the order of day and month is ambiguous, the one ordered as
/// [localePattern] (a locale's numeric date pattern, `M/d/y` or `dd/MM/y`) orders them;
/// null when there is none.
ImportDateFormat? preferredDateFormat(
  List<ImportDateFormat> candidates, {
  required String localePattern,
}) {
  if (candidates.length < 2) return candidates.firstOrNull;
  final int d = localePattern.indexOf('d'), m = localePattern.indexOf('M');
  final ImportDateFormat preferred = d >= 0 && m >= 0 && d < m
      ? ImportDateFormat.day
      : ImportDateFormat.us;
  return candidates.contains(preferred) ? preferred : candidates.first;
}

/// What a written import did; [historySaved] is false when its rows are in but the
/// record of it (and the preset) could not be completed.
typedef ImportResult = ({
  ImportBatch batch,
  Account account,
  int skipped,
  bool historySaved,
});

/// The record of this device's imports, newest first ([ImportActions.history]); empty
/// when the stored value does not decode.
@riverpod
Future<List<ImportBatch>> importHistory(Ref ref) =>
    ref.watch(importActionsProvider).history();

/// The import's work over the flavor's repositories.
@riverpod
ImportActions importActions(Ref ref) => ImportActions(
  transactions: ref.watch(transactionRepositoryProvider),
  accounts: ref.watch(accountRepositoryProvider),
  accountActions: ref.watch(accountActionsProvider),
  transactionActions: ref.watch(transactionActionsProvider),
  categories: ref.watch(categoryRepositoryProvider),
  arrival: ref.watch(arrivalProcessorProvider),
  meta: ref.watch(appMetaStoreProvider),
  clock: ref.watch(clockProvider),
  lockHold: ref.watch(lockHoldProvider),
  // Resolved now: the actions outlive this provider, which may be disposed during
  // their awaits, so nothing reads `ref` later.
  writeSnapshots: ref.watch(snapshotWriterRunnerProvider.notifier).writeNow,
);

/// Picks, reads, reviews, writes and undoes imports. Every collaborator is given when it
/// is made, so a write that outlives its provider (and the screen) still completes.
final class ImportActions {
  ImportActions({
    required this._transactions,
    required this._accounts,
    required this._accountActions,
    required this._transactionActions,
    required this._categories,
    required this._arrival,
    required this._meta,
    required this._clock,
    required this._lockHold,
    required this._writeSnapshots,
  });

  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final AccountActions _accountActions;
  final TransactionActions _transactionActions;
  final CategoryRepository _categories;
  final ArrivalProcessor _arrival;
  final AppMetaStore _meta;
  final Clock _clock;
  final LockHold _lockHold;
  final Future<void> Function() _writeSnapshots;

  static const Uuid _uuid = Uuid();

  /// The file the user picks through [picker], read whole and closed, or null when they
  /// pick none. Throws [ImportTooLargeException] for a file over [maxImportBytes],
  /// unread, and `BackupPickFailedException` when the dialog or the read fails.
  Future<PickedCsv?> pick(BackupPicker picker) async {
    // The file dialog is an activity of its own: the lock stays open.
    final PickedFile? picked = await _lockHold.holdOpen(picker.pick);
    if (picked == null) return null;
    try {
      final int length = picked.length;
      if (length > maxImportBytes) throw const ImportTooLargeException();
      final BytesBuilder bytes = BytesBuilder(copy: false);
      for (int at = 0; at < length; at += importReadChunk) {
        final int end = at + importReadChunk > length
            ? length
            : at + importReadChunk;
        bytes.add(await picked.read(at, end));
      }
      final Uint8List all = bytes.takeBytes();
      return PickedCsv(
        bytes: all,
        name: picked.name,
        sha256: crypto.sha256.convert(all).toString(),
      );
    } finally {
      await picked.close();
    }
  }

  /// [file] read into rows, split on [delimiter] or the one detected; in an isolate when
  /// it is over [isolateThreshold] bytes. A `FormatException` when a file with a byte
  /// order mark does not decode.
  Future<CsvTable> read(
    PickedCsv file, {
    String? delimiter,
    int isolateThreshold = importIsolateThreshold,
  }) {
    final Uint8List bytes = file.bytes;
    return bytes.length > isolateThreshold
        ? compute((_) => readCsv(bytes, delimiter: delimiter), null)
        : readCsv(bytes, delimiter: delimiter);
  }

  /// The preset saved for [header], or null.
  Future<ImportPreset?> presetFor(List<String> header) async {
    final String signature = headerSignature(header);
    for (final ImportPreset p in await _presets()) {
      if (p.signature == signature) return p;
    }
    return null;
  }

  /// What [file]'s [table], with its header at [headerRow], will write into [target]
  /// through [mapping]: the rows as transactions (categories matched by name, ignoring
  /// case, the first in the categories' order), the likely duplicates among them against
  /// the target account's rows from three days before the file's first date to three
  /// after its last, the rows skipped, and whether the file was imported before. The
  /// conversion and the duplicate marking run in an isolate when the file is over
  /// [isolateThreshold] bytes, as its parse does.
  Future<ImportReview> review({
    required PickedCsv file,
    required CsvTable table,
    required int headerRow,
    required ImportMapping mapping,
    required ImportTarget target,
    int isolateThreshold = importIsolateThreshold,
  }) async {
    final bool large = file.bytes.length > isolateThreshold;
    final Map<String, String> categoryIds = {};
    for (final Category c in await currentValue(_categories.watchAll())) {
      categoryIds.putIfAbsent(c.name.trim().toLowerCase(), () => c.id);
    }
    final String accountId = switch (target) {
      ExistingAccount(:final Account account) => account.id,
      NewAccount() => _uuid.v4(),
    };
    final DateTime now = _clock.nowUtc();
    final _Conversion input = (
      rows: table.rows.sublist(headerRow + 1),
      mapping: mapping,
      currencyCode: target.currencyCode,
      firstRow: headerRow + 2,
      categoryIds: categoryIds,
      accountId: accountId,
      now: now,
    );
    final _Converted converted = large
        ? await compute(_convert, input)
        : _convert(input);
    final List<Transaction> incoming = converted.incoming;
    final List<Transaction> existing = target is ExistingAccount
        ? await _around(accountId, incoming)
        : const [];
    final Set<String> duplicates = large
        ? await compute((_) => likelyDuplicates(incoming, existing), null)
        : likelyDuplicates(incoming, existing);
    final List<ImportBatch> history = await _history();
    return ImportReview(
      file: file,
      target: target,
      incoming: incoming,
      duplicates: duplicates,
      failures: converted.failures,
      importedBefore: history.any(
        (b) => b.sha256 == file.sha256 && b.undoneAt == null,
      ),
      lossy: table.lossy,
      preset: ImportPreset.of(
        table.rows[headerRow],
        mapping,
        delimiter: table.delimiter,
        headerRow: headerRow,
        accountId: target is ExistingAccount ? accountId : null,
        savedAt: now,
      ),
    );
  }

  // The live rows of [accountId], hidden ones included, within the duplicates window of
  // [incoming]'s dates.
  Future<List<Transaction>> _around(
    String accountId,
    List<Transaction> incoming,
  ) async {
    if (incoming.isEmpty) return const [];
    LocalDate first = incoming.first.date, last = incoming.first.date;
    for (final Transaction t in incoming) {
      if (t.date.isBefore(first)) first = t.date;
      if (t.date.isAfter(last)) last = t.date;
    }
    return currentValue(
      _transactions.watch(
        TransactionQuery(
          accountIds: {accountId},
          range: LocalDateRange(first.addDays(-3), last.addDays(4)),
        ),
      ),
    );
  }

  /// Writes [review]'s rows, the duplicates only with [includeDuplicates], into its
  /// target, in this order, so that a kill at any point leaves rows only with a record
  /// that undoes them:
  ///
  /// 1. a new account is created when one was asked for;
  /// 2. the import is recorded, `pending`, with the ids of its rows;
  /// 3. the rows are written in one `upsertAll`, stamped now (a refusal removes the
  ///    pending record and the account just created, and rethrows);
  /// 4. the rules run on them, and today's snapshots are rewritten;
  /// 5. the record is marked complete and the preset saved: a failure here is logged and
  ///    reported as [ImportResult.historySaved] false, the rows being in.
  ///
  /// A failure before the rows are written reaches the caller: the repository's
  /// exceptions, `TransactionBatchException` among them, or the store's.
  Future<ImportResult> write(
    ImportReview review, {
    required bool includeDuplicates,
  }) async {
    final ImportTarget target = review.target;
    final Account account;
    bool created = false;
    switch (target) {
      case ExistingAccount(account: final Account a):
        account = a;
      case NewAccount(:final name, :final type, :final currencyCode):
        account = await _accountActions.create(
          existing: await currentValue(_accounts.watchAll()),
          name: name,
          type: type,
          currencyCode: currencyCode,
          openingDate: _clock.today(),
          openingBalanceName: '',
        );
        created = true;
    }
    final DateTime now = _clock.nowUtc();
    final List<Transaction> rows = [
      for (final Transaction t in review.toWrite(
        includeDuplicates: includeDuplicates,
      ))
        t.copyWith(accountId: account.id, createdAt: now, updatedAt: now),
    ];
    final ImportBatch pending = ImportBatch(
      id: _uuid.v4(),
      importedAt: now,
      fileName: review.file.name,
      sha256: review.file.sha256,
      accountId: account.id,
      count: rows.length,
      transactionIds: [for (final Transaction t in rows) t.id],
      pending: true,
    );
    try {
      await _meta.write(
        AppMetaKeys.importHistory,
        encodeHistory(await _history(), pending),
      );
      await _transactions.upsertAll(rows);
    } on Object {
      await _forget(pending);
      if (created) await _accounts.delete(account.id);
      rethrow;
    }
    _log.info('imported ${rows.length} transaction(s)');
    await _arrival.onArrived(rows);
    try {
      await _writeSnapshots();
    } on Object catch (e) {
      _log.warning('balance snapshots not written: ${e.runtimeType}');
    }
    final ImportBatch batch = pending.completed();
    bool saved = true;
    try {
      await _meta.write(
        AppMetaKeys.importHistory,
        encodeHistory(await _history(), batch),
      );
      await _meta.write(
        AppMetaKeys.importPresets,
        encodePresets(await _presets(), review.preset.withAccount(account.id)),
      );
    } on Object catch (e) {
      _log.warning('the import history was not saved: ${e.runtimeType}');
      saved = false;
    }
    return (
      batch: batch,
      account: account,
      skipped: review.incoming.length - rows.length,
      historySaved: saved,
    );
  }

  // Drops [batch]'s record, whose rows were not written; a failure is logged, and the
  // history's next read drops it instead.
  Future<void> _forget(ImportBatch batch) async {
    try {
      await _meta.write(
        AppMetaKeys.importHistory,
        encodeHistoryList([
          for (final ImportBatch b in await _history())
            if (b.id != batch.id) b,
        ]),
      );
    } on Object catch (e) {
      _log.warning('a pending import was not dropped: ${e.runtimeType}');
    }
  }

  /// This device's imports, newest first, with any import cut short sorted out: a
  /// `pending` one whose rows are stored is marked complete, and one whose rows never
  /// landed is dropped once it is older than [pendingGrace] by the clock (a younger one
  /// may be a write still under way, and stays pending); the history is written back.
  Future<List<ImportBatch>> history() async {
    final List<ImportBatch> stored = await _history();
    if (!stored.any((b) => b.pending)) return stored;
    final DateTime now = _clock.nowUtc();
    final List<ImportBatch> next = [
      for (final ImportBatch b in stored)
        if (!b.pending)
          b
        else if (await _landed(b))
          b.completed()
        else if (now.difference(b.importedAt) <= pendingGrace)
          b,
    ];
    await _meta.write(AppMetaKeys.importHistory, encodeHistoryList(next));
    return next;
  }

  // Whether any of [batch]'s rows is stored (the batch is written all or nothing).
  Future<bool> _landed(ImportBatch batch) async {
    for (final String id in batch.transactionIds) {
      if (await currentValue(_transactions.watchById(id)) != null) return true;
    }
    return false;
  }

  /// Deletes [batch]'s transactions that are still live, edited ones too, in one write
  /// (tombstones that sync), rewrites today's snapshots, and marks the import undone.
  Future<void> undo(ImportBatch batch) async {
    await _transactionActions.deleteAll(batch.transactionIds);
    _log.info('undid an import of ${batch.count} transaction(s)');
    try {
      await _writeSnapshots();
    } on Object catch (e) {
      _log.warning('balance snapshots not written: ${e.runtimeType}');
    }
    await _meta.write(
      AppMetaKeys.importHistory,
      encodeHistory(await _history(), batch.undone(_clock.nowUtc())),
    );
  }

  Future<List<ImportPreset>> _presets() async {
    try {
      return decodePresets(await _meta.read(AppMetaKeys.importPresets));
    } on ImportRecordsFormatException catch (e) {
      _log.warning('the import presets did not decode: ${e.runtimeType}');
      return const [];
    }
  }

  Future<List<ImportBatch>> _history() async {
    try {
      return decodeHistory(await _meta.read(AppMetaKeys.importHistory));
    } on ImportRecordsFormatException catch (e) {
      _log.warning('the import history did not decode: ${e.runtimeType}');
      return const [];
    }
  }
}

typedef _Conversion = ({
  List<List<String>> rows,
  ImportMapping mapping,
  String currencyCode,
  int firstRow,
  Map<String, String> categoryIds,
  String accountId,
  DateTime now,
});

typedef _Converted = ({List<Transaction> incoming, List<RowFailure> failures});

// The rows of [input] as transactions on its account, stamped with its instant.
_Converted _convert(_Conversion input) {
  final ImportParse parse = convertRows(
    input.rows,
    input.mapping,
    currencyCode: input.currencyCode,
    firstRow: input.firstRow,
  );
  const Uuid uuid = Uuid();
  return (
    incoming: [
      for (final ImportedRow row in parse.rows)
        Transaction(
          id: uuid.v4(),
          accountId: input.accountId,
          amount: row.amount,
          date: row.date,
          pending: false,
          name: row.name,
          merchantName: row.merchant,
          userCategoryId: input.categoryIds[row.category?.toLowerCase()],
          notes: row.notes,
          tags: row.tags,
          source: DataSource.import,
          createdAt: input.now,
          updatedAt: input.now,
          syncVersion: 0,
        ),
    ],
    failures: parse.failures,
  );
}
