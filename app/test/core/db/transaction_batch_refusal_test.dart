// A transaction batch reports as TransactionBatchException only the refusals of a row
// (the typed exceptions and the two typed argument errors); any other error in the
// write path, here an ArgumentError thrown by the recorder, propagates as itself, in
// the Drift and the in-memory repositories.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../contract/repository_fixture.dart';

/// A recorder that fails as a programming error would, once [failing] is set.
final class _FailingRecorder implements ChangeRecorder {
  bool failing = false;

  @override
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {
    if (failing) throw ArgumentError('recorder bug');
  }
}

void main() {
  test('only the refusals of a row are batch refusals', () {
    expect(isBatchRefusal(const AccountNotFoundException('a')), isTrue);
    expect(
      isBatchRefusal(const CurrencyMismatchException('USD', 'EUR')),
      isTrue,
    );
    expect(isBatchRefusal(const EntityDeletedException('t', 'x')), isTrue);
    expect(
      isBatchRefusal(const BankDataNotDeletableException('t', 'x')),
      isTrue,
    );
    expect(
      isBatchRefusal(AuditInstantError(DateTime(2026), 'createdAt', 'UTC')),
      isTrue,
    );
    expect(
      isBatchRefusal(PlaidOverridesOnlyError('p1', field: 'name')),
      isTrue,
    );
    expect(isBatchRefusal(ArgumentError('anything else')), isFalse);
    expect(isBatchRefusal(StateError('x')), isFalse);
  });

  for (final String name in ['Drift', 'in memory']) {
    test('$name: an unrelated ArgumentError propagates as itself', () async {
      final SteppingClock clock = SteppingClock();
      final _FailingRecorder recorder = _FailingRecorder();
      final AccountRepository accounts;
      final TransactionRepository transactions;
      if (name == 'Drift') {
        final AppDatabase database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        accounts = DriftAccountRepository(database, clock, recorder: recorder);
        transactions = DriftTransactionRepository(
          database,
          clock,
          recorder: recorder,
        );
      } else {
        final InMemoryStore store = InMemoryStore(clock);
        addTearDown(store.close);
        accounts = InMemoryAccountRepository(store, recorder: recorder);
        transactions = InMemoryTransactionRepository(store, recorder: recorder);
      }
      await accounts.upsert(testAccount('a1'));
      recorder.failing = true;
      await expectLater(
        transactions.upsertAll([testTransaction('t1', 'a1', -100)]),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'recorder bug',
          ),
        ),
      );
    });
  }
}
