// What the backup tests share: the tests' Argon2id cost, a database seeded with data of
// every kind through the dev flavor's repositories, and the outbox's states.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/backup/domain/backup_format.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../helpers/bill_seed.dart';
import '../../helpers/budget_seed.dart';
import '../../helpers/goal_seed.dart';
import '../../helpers/rule_seed.dart';

/// The tests' Argon2id cost: 8 MiB, one pass, one lane.
const KdfParameters testKdf = KdfParameters(
  memoryKiB: 8 * 1024,
  iterations: 1,
  parallelism: 1,
);

/// The receipt photo the seeded transactions carry.
Uint8List receiptPhoto() =>
    File('test/fixtures/receipts/plain.jpg').readAsBytesSync();

DateTime _at(int minutes) =>
    DateTime.utc(2026, 10, 24, 12).add(Duration(minutes: minutes));

Transaction _manual(
  String id,
  String account,
  int cents,
  LocalDate date,
  String name, {
  List<String> tags = const [],
  List<TransactionSplit> splits = const [],
  String? notes,
  String? receiptPath,
  int minutes = 0,
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(cents, 'USD'),
  date: date,
  pending: false,
  name: name,
  userCategoryId: systemCategoryId('FOOD_AND_DRINK'),
  tags: tags,
  splits: splits,
  notes: notes,
  receiptPath: receiptPath,
  source: DataSource.manual,
  createdAt: _at(minutes),
  updatedAt: _at(minutes),
  syncVersion: 0,
);

/// Fills [container]'s database (the dev wiring, signed in to its fake server with the
/// user's Items linked): the Plaid pull, then manual data of every kind, receipts in
/// [receipts], device bookkeeping, a held record, and an outbox of synced, rejected and
/// unsynced entries.
Future<void> seedEverything(
  ProviderContainer container,
  ReceiptStore receipts,
) async {
  final AppDatabase db = container.read(databaseProvider);
  await container.read(categoryRepositoryProvider).ensureSeeded();
  await container.read(plaidPullProvider).run();
  // An Item's logo, the one BLOB column.
  await db.customStatement(
    'UPDATE items SET institution_logo = ? WHERE id = (SELECT min(id) FROM items)',
    [Uint8List.fromList(List<int>.generate(300, (i) => (i * 7) % 256))],
  );

  const String cash = 'manual-cash';
  await container
      .read(accountRepositoryProvider)
      .create(
        const Account(
          id: cash,
          type: AccountType.depository,
          name: 'Cash jar',
          currencyCode: 'USD',
          isHidden: false,
          displayOrder: 20,
        ),
        openingBalance: _manual(
          'manual-cash-opening',
          cash,
          50000,
          LocalDate(2026, 9, 1),
          'Opening balance',
        ),
      );
  final String lunchReceipt = await receipts.commit(
    await receipts.stage('manual-lunch', receiptPhoto()),
  );
  final String trainReceipt = await receipts.commit(
    await receipts.stage('manual-train', receiptPhoto().sublist(0, 400)),
  );
  final transactions = container.read(transactionRepositoryProvider);
  await transactions.upsert(
    _manual(
      'manual-lunch',
      cash,
      -2450,
      LocalDate(2026, 10, 22),
      'Lunch in Lisbon',
      tags: const ['travel', 'food', 'café'],
      splits: [
        TransactionSplit(
          categoryId: systemCategoryId('FOOD_AND_DRINK'),
          amount: Money(-2000, 'USD'),
          note: 'Food',
        ),
        TransactionSplit(
          categoryId: systemCategoryId('ENTERTAINMENT'),
          amount: Money(-450, 'USD'),
        ),
      ],
      notes: 'With "Ana"\nand Rui',
      receiptPath: lunchReceipt,
      minutes: 1,
    ),
  );
  await transactions.upsert(
    _manual(
      'manual-train',
      cash,
      -1200,
      LocalDate(2026, 10, 23),
      'Train',
      receiptPath: trainReceipt,
      minutes: 2,
    ),
  );
  await transactions.upsert(
    _manual(
      'manual-gone',
      cash,
      -100,
      LocalDate(2026, 10, 23),
      'Gone',
      minutes: 3,
    ),
  );
  await transactions.delete('manual-gone');

  await container.read(ruleRepositoryProvider).upsert(everyKindRule);
  for (final Budget b in testBudgets()) {
    await container.read(budgetRepositoryProvider).upsert(b);
  }
  for (final BillReminder b in testBills()) {
    await container.read(billRepositoryProvider).upsert(b);
  }
  for (final Goal g in testGoals()) {
    await container.read(goalRepositoryProvider).create(g);
  }
  for (final GoalContribution c in testContributions()) {
    await container.read(goalRepositoryProvider).addContribution(c);
  }
  await container
      .read(settingsRepositoryProvider)
      .save(
        const Settings(themeMode: AppThemeMode.dark, useDynamicColor: false),
      );
  await container.read(savedFilterRepositoryProvider).save('Lisbon', {
    'text': 'lisbon',
  });

  final AppMetaStore meta = container.read(appMetaStoreProvider);
  await meta.write(AppMetaKeys.remindersZone, 'Europe/Lisbon');
  await meta.write(
    AppMetaKeys.remindersScheduledAt,
    '2026-10-24T12:00:00.000Z',
  );
  await meta.write(AppMetaKeys.snapshotsWrittenOn, '2026-10-24');
  await meta.write(AppMetaKeys.dismissedAnomalies, '["manual-train"]');
  await meta.write(AppMetaKeys.installDate, '2026-09-01');

  final int raised = _at(5).millisecondsSinceEpoch;
  for (final String sql in [
    'INSERT INTO budget_alerts (budget_id, period_start, threshold_bp, raised_at) '
        "VALUES ('budget-food', '2026-10-01', 8000, $raised)",
    'INSERT INTO bill_alerts (bill_id, due_date, raised_at) '
        "VALUES ('phone', '2026-10-27', $raised)",
    'INSERT INTO dismissed_pairs (id_a, id_b, dismissed_at) '
        "VALUES ('manual-lunch', 'manual-train', $raised)",
    'INSERT INTO balance_snapshots (account_id, date, current_minor, '
        'available_minor, limit_minor, currency, source, written_at) '
        "VALUES ('$cash', '2026-10-24', 26350, NULL, NULL, 'USD', 'derived', $raised)",
  ]) {
    await db.customStatement(sql);
  }

  // A record sync could not store whole: a goal's fields with no create.
  await container
      .read(driftSyncStoreProvider)
      .write(
        EntityRecord(
          type: EntityType.goal,
          id: 'held-goal',
          fields: const {'name': 'Held'},
          fieldClocks: {'name': Hlc(_at(6).millisecondsSinceEpoch, 0, 'other')},
        ),
      );

  // The outbox: the oldest entries synced, one refused for good, the rest unsynced.
  await db.customStatement(
    'UPDATE change_log SET synced = 1 WHERE seq <= '
    '(SELECT max(seq) / 2 FROM change_log)',
  );
  await db.customStatement(
    "UPDATE change_log SET rejected_reason = 'invalid' WHERE seq = "
    '(SELECT max(seq) / 2 + 1 FROM change_log)',
  );
}

/// How many outbox entries of [db] are `synced`, `rejected` and `unsynced`.
Future<Map<String, int>> outboxStates(AppDatabase db) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT sum(synced) AS synced, '
        'sum(rejected_reason IS NOT NULL) AS rejected, '
        'sum(synced = 0 AND rejected_reason IS NULL) AS unsynced FROM change_log',
      )
      .getSingle();
  return {
    for (final String k in ['synced', 'rejected', 'unsynced'])
      k: row.read<int?>(k) ?? 0,
  };
}
