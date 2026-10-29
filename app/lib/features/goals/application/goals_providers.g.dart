// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live goals with their contributions, by creation day, then id.

@ProviderFor(goalEntries)
final goalEntriesProvider = GoalEntriesProvider._();

/// The live goals with their contributions, by creation day, then id.

final class GoalEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalEntry>>,
          List<GoalEntry>,
          Stream<List<GoalEntry>>
        >
    with $FutureModifier<List<GoalEntry>>, $StreamProvider<List<GoalEntry>> {
  /// The live goals with their contributions, by creation day, then id.
  GoalEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<GoalEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GoalEntry>> create(Ref ref) {
    return goalEntries(ref);
  }
}

String _$goalEntriesHash() => r'1cf2ab82f0698451b004e3b37eb04cc18ca214e5';

/// Every live goal as the screens show it today, archived ones included, in
/// [goalEntries]' order; recomputed when the goals, the accounts, their balances or
/// today change.

@ProviderFor(goalViews)
final goalViewsProvider = GoalViewsProvider._();

/// Every live goal as the screens show it today, archived ones included, in
/// [goalEntries]' order; recomputed when the goals, the accounts, their balances or
/// today change.

final class GoalViewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalView>>,
          List<GoalView>,
          FutureOr<List<GoalView>>
        >
    with $FutureModifier<List<GoalView>>, $FutureProvider<List<GoalView>> {
  /// Every live goal as the screens show it today, archived ones included, in
  /// [goalEntries]' order; recomputed when the goals, the accounts, their balances or
  /// today change.
  GoalViewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalViewsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalViewsHash();

  @$internal
  @override
  $FutureProviderElement<List<GoalView>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GoalView>> create(Ref ref) {
    return goalViews(ref);
  }
}

String _$goalViewsHash() => r'0ddb794f86e98840629f10bdc8052bf4a5d364e5';

/// Live goal [id] as the screens show it today, or null when there is none.

@ProviderFor(goalViewById)
final goalViewByIdProvider = GoalViewByIdFamily._();

/// Live goal [id] as the screens show it today, or null when there is none.

final class GoalViewByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalView?>,
          GoalView?,
          FutureOr<GoalView?>
        >
    with $FutureModifier<GoalView?>, $FutureProvider<GoalView?> {
  /// Live goal [id] as the screens show it today, or null when there is none.
  GoalViewByIdProvider._({
    required GoalViewByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalViewByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalViewByIdHash();

  @override
  String toString() {
    return r'goalViewByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GoalView?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GoalView?> create(Ref ref) {
    final argument = this.argument as String;
    return goalViewById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalViewByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalViewByIdHash() => r'96bf4cc5fcc4acc81c64a54bfde4aaa688717949';

/// Live goal [id] as the screens show it today, or null when there is none.

final class GoalViewByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GoalView?>, String> {
  GoalViewByIdFamily._()
    : super(
        retry: null,
        name: r'goalViewByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live goal [id] as the screens show it today, or null when there is none.

  GoalViewByIdProvider call(String id) =>
      GoalViewByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'goalViewByIdProvider';
}

/// The goal actions.

@ProviderFor(goalActions)
final goalActionsProvider = GoalActionsProvider._();

/// The goal actions.

final class GoalActionsProvider
    extends $FunctionalProvider<GoalActions, GoalActions, GoalActions>
    with $Provider<GoalActions> {
  /// The goal actions.
  GoalActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalActionsHash();

  @$internal
  @override
  $ProviderElement<GoalActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalActions create(Ref ref) {
    return goalActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalActions>(value),
    );
  }
}

String _$goalActionsHash() => r'd22d693003e60e53c37c52b319acffe1b2717d1d';
