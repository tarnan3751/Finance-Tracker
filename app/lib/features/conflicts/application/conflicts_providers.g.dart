// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conflicts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This device's conflicts, the most recently seen first.

@ProviderFor(conflicts)
final conflictsProvider = ConflictsProvider._();

/// This device's conflicts, the most recently seen first.

final class ConflictsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SyncConflict>>,
          List<SyncConflict>,
          Stream<List<SyncConflict>>
        >
    with
        $FutureModifier<List<SyncConflict>>,
        $StreamProvider<List<SyncConflict>> {
  /// This device's conflicts, the most recently seen first.
  ConflictsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictsHash();

  @$internal
  @override
  $StreamProviderElement<List<SyncConflict>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SyncConflict>> create(Ref ref) {
    return conflicts(ref);
  }
}

String _$conflictsHash() => r'ea5e9c5a3f6f1384c3757f40dabd72d21baf94fa';

/// How many conflicts there are (0 until they load): Settings → Sync's count.

@ProviderFor(conflictCount)
final conflictCountProvider = ConflictCountProvider._();

/// How many conflicts there are (0 until they load): Settings → Sync's count.

final class ConflictCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// How many conflicts there are (0 until they load): Settings → Sync's count.
  ConflictCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return conflictCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$conflictCountHash() => r'e44fceaf6482a13a30f70afa92454173d8a19e92';

/// The names of the user's devices by id, for the conflicts' "from" lines; empty when
/// the list cannot be had (offline, signed out), when the screen shows node ids instead.

@ProviderFor(conflictDeviceNames)
final conflictDeviceNamesProvider = ConflictDeviceNamesProvider._();

/// The names of the user's devices by id, for the conflicts' "from" lines; empty when
/// the list cannot be had (offline, signed out), when the screen shows node ids instead.

final class ConflictDeviceNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// The names of the user's devices by id, for the conflicts' "from" lines; empty when
  /// the list cannot be had (offline, signed out), when the screen shows node ids instead.
  ConflictDeviceNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictDeviceNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictDeviceNamesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return conflictDeviceNames(ref);
  }
}

String _$conflictDeviceNamesHash() =>
    r'96eb4a9d3b84da016186ac913aaa13612eb95b49';

/// The conflicts' actions.

@ProviderFor(conflictActions)
final conflictActionsProvider = ConflictActionsProvider._();

/// The conflicts' actions.

final class ConflictActionsProvider
    extends
        $FunctionalProvider<ConflictActions, ConflictActions, ConflictActions>
    with $Provider<ConflictActions> {
  /// The conflicts' actions.
  ConflictActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictActionsHash();

  @$internal
  @override
  $ProviderElement<ConflictActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConflictActions create(Ref ref) {
    return conflictActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConflictActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConflictActions>(value),
    );
  }
}

String _$conflictActionsHash() => r'9fb5fcd524e51e501ac8568566436ed27970eb24';
