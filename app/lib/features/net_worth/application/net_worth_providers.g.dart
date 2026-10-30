// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every stored balance snapshot, by date, then account.

@ProviderFor(balanceSnapshots)
final balanceSnapshotsProvider = BalanceSnapshotsProvider._();

/// Every stored balance snapshot, by date, then account.

final class BalanceSnapshotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BalanceSnapshot>>,
          List<BalanceSnapshot>,
          Stream<List<BalanceSnapshot>>
        >
    with
        $FutureModifier<List<BalanceSnapshot>>,
        $StreamProvider<List<BalanceSnapshot>> {
  /// Every stored balance snapshot, by date, then account.
  BalanceSnapshotsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceSnapshotsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceSnapshotsHash();

  @$internal
  @override
  $StreamProviderElement<List<BalanceSnapshot>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BalanceSnapshot>> create(Ref ref) {
    return balanceSnapshots(ref);
  }
}

String _$balanceSnapshotsHash() => r'07acc6dc901050c0318ba85590a077a340e9cf4d';

/// The net worth history per currency code (`netWorthHistory`): the prefix
/// reconstructed from the live transactions (`recurringLedgerProvider`, every live
/// one), then the series of the stored snapshots, typed by the live accounts.

@ProviderFor(netWorthSeries)
final netWorthSeriesProvider = NetWorthSeriesProvider._();

/// The net worth history per currency code (`netWorthHistory`): the prefix
/// reconstructed from the live transactions (`recurringLedgerProvider`, every live
/// one), then the series of the stored snapshots, typed by the live accounts.

final class NetWorthSeriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<NetWorthPoint>>>,
          Map<String, List<NetWorthPoint>>,
          FutureOr<Map<String, List<NetWorthPoint>>>
        >
    with
        $FutureModifier<Map<String, List<NetWorthPoint>>>,
        $FutureProvider<Map<String, List<NetWorthPoint>>> {
  /// The net worth history per currency code (`netWorthHistory`): the prefix
  /// reconstructed from the live transactions (`recurringLedgerProvider`, every live
  /// one), then the series of the stored snapshots, typed by the live accounts.
  NetWorthSeriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'netWorthSeriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$netWorthSeriesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<NetWorthPoint>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<NetWorthPoint>>> create(Ref ref) {
    return netWorthSeries(ref);
  }
}

String _$netWorthSeriesHash() => r'd4f89aeea3b3d1683d68b26afc9ad1dade930e4a';

/// The payoff entries by account id (`PayoffEntry`), kept on this device only under
/// `AppMetaKeys.payoffEntries` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.

@ProviderFor(PayoffEntriesController)
final payoffEntriesControllerProvider = PayoffEntriesControllerProvider._();

/// The payoff entries by account id (`PayoffEntry`), kept on this device only under
/// `AppMetaKeys.payoffEntries` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.
final class PayoffEntriesControllerProvider
    extends
        $AsyncNotifierProvider<
          PayoffEntriesController,
          Map<String, PayoffEntry>
        > {
  /// The payoff entries by account id (`PayoffEntry`), kept on this device only under
  /// `AppMetaKeys.payoffEntries` (never synced). The changes are applied one at a time,
  /// in the order they are made: the state is updated, then written; when the write fails
  /// the state goes back and the change's Future fails.
  PayoffEntriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payoffEntriesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payoffEntriesControllerHash();

  @$internal
  @override
  PayoffEntriesController create() => PayoffEntriesController();
}

String _$payoffEntriesControllerHash() =>
    r'88d35e6720aa65997d022e5850a1cb8269032ce7';

/// The payoff entries by account id (`PayoffEntry`), kept on this device only under
/// `AppMetaKeys.payoffEntries` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.

abstract class _$PayoffEntriesController
    extends $AsyncNotifier<Map<String, PayoffEntry>> {
  FutureOr<Map<String, PayoffEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Map<String, PayoffEntry>>,
              Map<String, PayoffEntry>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, PayoffEntry>>,
                Map<String, PayoffEntry>
              >,
              AsyncValue<Map<String, PayoffEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The live credit and loan accounts that owe something, hidden ones included (net worth
/// counts them), in the accounts' order, each with its payoff from today.

@ProviderFor(liabilityPayoffs)
final liabilityPayoffsProvider = LiabilityPayoffsProvider._();

/// The live credit and loan accounts that owe something, hidden ones included (net worth
/// counts them), in the accounts' order, each with its payoff from today.

final class LiabilityPayoffsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LiabilityPayoff>>,
          List<LiabilityPayoff>,
          FutureOr<List<LiabilityPayoff>>
        >
    with
        $FutureModifier<List<LiabilityPayoff>>,
        $FutureProvider<List<LiabilityPayoff>> {
  /// The live credit and loan accounts that owe something, hidden ones included (net worth
  /// counts them), in the accounts' order, each with its payoff from today.
  LiabilityPayoffsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liabilityPayoffsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liabilityPayoffsHash();

  @$internal
  @override
  $FutureProviderElement<List<LiabilityPayoff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LiabilityPayoff>> create(Ref ref) {
    return liabilityPayoffs(ref);
  }
}

String _$liabilityPayoffsHash() => r'ace437cda1f1abcebcccb261053693ed309c5f8c';
