/// The demo flavor's [BalanceSnapshotRepository]: the in-memory one, empty at launch
/// (`balanceSnapshotRepositoryProvider`).
library;

import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';

/// The demo's snapshots: the snapshot writer fills the launch day's, `demo`, and they go
/// when the app closes or the persona changes.
final class DemoBalanceSnapshotRepository
    extends InMemoryBalanceSnapshotRepository {}
