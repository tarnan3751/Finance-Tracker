// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anomaly_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ids of the transactions whose flags were dismissed, kept in `app_meta` on this
/// device and never synced. Kept alive, so an Undo pressed after its screen has gone
/// still finds it.

@ProviderFor(DismissedAnomalies)
final dismissedAnomaliesProvider = DismissedAnomaliesProvider._();

/// The ids of the transactions whose flags were dismissed, kept in `app_meta` on this
/// device and never synced. Kept alive, so an Undo pressed after its screen has gone
/// still finds it.
final class DismissedAnomaliesProvider
    extends $AsyncNotifierProvider<DismissedAnomalies, Set<String>> {
  /// The ids of the transactions whose flags were dismissed, kept in `app_meta` on this
  /// device and never synced. Kept alive, so an Undo pressed after its screen has gone
  /// still finds it.
  DismissedAnomaliesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedAnomaliesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedAnomaliesHash();

  @$internal
  @override
  DismissedAnomalies create() => DismissedAnomalies();
}

String _$dismissedAnomaliesHash() =>
    r'0d1c8dd929b2f7b50bd711eb0c0bab46215c6d5c';

/// The ids of the transactions whose flags were dismissed, kept in `app_meta` on this
/// device and never synced. Kept alive, so an Undo pressed after its screen has gone
/// still finds it.

abstract class _$DismissedAnomalies extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The flags on the live, visible transactions dated in [window], less the dismissed
/// ones: judged on every live transaction, with the merged recurring streams' members as
/// the scheduled payments and the live rules.

@ProviderFor(anomalies)
final anomaliesProvider = AnomaliesFamily._();

/// The flags on the live, visible transactions dated in [window], less the dismissed
/// ones: judged on every live transaction, with the merged recurring streams' members as
/// the scheduled payments and the live rules.

final class AnomaliesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnomalyFlag>>,
          List<AnomalyFlag>,
          FutureOr<List<AnomalyFlag>>
        >
    with
        $FutureModifier<List<AnomalyFlag>>,
        $FutureProvider<List<AnomalyFlag>> {
  /// The flags on the live, visible transactions dated in [window], less the dismissed
  /// ones: judged on every live transaction, with the merged recurring streams' members as
  /// the scheduled payments and the live rules.
  AnomaliesProvider._({
    required AnomaliesFamily super.from,
    required LocalDateRange super.argument,
  }) : super(
         retry: null,
         name: r'anomaliesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$anomaliesHash();

  @override
  String toString() {
    return r'anomaliesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AnomalyFlag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnomalyFlag>> create(Ref ref) {
    final argument = this.argument as LocalDateRange;
    return anomalies(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnomaliesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$anomaliesHash() => r'194c636709f88285453633938ca5f612cce54916';

/// The flags on the live, visible transactions dated in [window], less the dismissed
/// ones: judged on every live transaction, with the merged recurring streams' members as
/// the scheduled payments and the live rules.

final class AnomaliesFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<AnomalyFlag>>, LocalDateRange> {
  AnomaliesFamily._()
    : super(
        retry: null,
        name: r'anomaliesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The flags on the live, visible transactions dated in [window], less the dismissed
  /// ones: judged on every live transaction, with the merged recurring streams' members as
  /// the scheduled payments and the live rules.

  AnomaliesProvider call(LocalDateRange window) =>
      AnomaliesProvider._(argument: window, from: this);

  @override
  String toString() => r'anomaliesProvider';
}
