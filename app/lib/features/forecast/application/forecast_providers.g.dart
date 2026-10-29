// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which accounts the forecast covers and which currency it shows, as the user's changes
/// from the default (`ForecastSelection`), kept on this device only under
/// `AppMetaKeys.forecastSelection` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.

@ProviderFor(ForecastSelectionController)
final forecastSelectionControllerProvider =
    ForecastSelectionControllerProvider._();

/// Which accounts the forecast covers and which currency it shows, as the user's changes
/// from the default (`ForecastSelection`), kept on this device only under
/// `AppMetaKeys.forecastSelection` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.
final class ForecastSelectionControllerProvider
    extends
        $AsyncNotifierProvider<ForecastSelectionController, ForecastSelection> {
  /// Which accounts the forecast covers and which currency it shows, as the user's changes
  /// from the default (`ForecastSelection`), kept on this device only under
  /// `AppMetaKeys.forecastSelection` (never synced). The changes are applied one at a time,
  /// in the order they are made: the state is updated, then written; when the write fails
  /// the state goes back and the change's Future fails.
  ForecastSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forecastSelectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forecastSelectionControllerHash();

  @$internal
  @override
  ForecastSelectionController create() => ForecastSelectionController();
}

String _$forecastSelectionControllerHash() =>
    r'10b9ebeea2666720bd36045b8ff240b3d8579931';

/// Which accounts the forecast covers and which currency it shows, as the user's changes
/// from the default (`ForecastSelection`), kept on this device only under
/// `AppMetaKeys.forecastSelection` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.

abstract class _$ForecastSelectionController
    extends $AsyncNotifier<ForecastSelection> {
  FutureOr<ForecastSelection> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ForecastSelection>, ForecastSelection>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ForecastSelection>, ForecastSelection>,
              AsyncValue<ForecastSelection>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// What the series shown is projected from: the covered accounts in the currency shown,
/// their balance as each is shown (reported, else derived: `shownBalance`), their active,
/// unmuted streams with their live members, the bills (`forecastBills`) over the longest
/// horizon, and the allowance; null when no account is covered.

@ProviderFor(forecastPlan)
final forecastPlanProvider = ForecastPlanProvider._();

/// What the series shown is projected from: the covered accounts in the currency shown,
/// their balance as each is shown (reported, else derived: `shownBalance`), their active,
/// unmuted streams with their live members, the bills (`forecastBills`) over the longest
/// horizon, and the allowance; null when no account is covered.

final class ForecastPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastPlan?>,
          ForecastPlan?,
          FutureOr<ForecastPlan?>
        >
    with $FutureModifier<ForecastPlan?>, $FutureProvider<ForecastPlan?> {
  /// What the series shown is projected from: the covered accounts in the currency shown,
  /// their balance as each is shown (reported, else derived: `shownBalance`), their active,
  /// unmuted streams with their live members, the bills (`forecastBills`) over the longest
  /// horizon, and the allowance; null when no account is covered.
  ForecastPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forecastPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forecastPlanHash();

  @$internal
  @override
  $FutureProviderElement<ForecastPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastPlan?> create(Ref ref) {
    return forecastPlan(ref);
  }
}

String _$forecastPlanHash() => r'f5a1f56ab6b401bf9a3b6f234f32365f147779e6';

/// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
/// account is covered.

@ProviderFor(forecast)
final forecastProvider = ForecastFamily._();

/// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
/// account is covered.

final class ForecastProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastSeries?>,
          ForecastSeries?,
          FutureOr<ForecastSeries?>
        >
    with $FutureModifier<ForecastSeries?>, $FutureProvider<ForecastSeries?> {
  /// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
  /// account is covered.
  ForecastProvider._({
    required ForecastFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'forecastProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forecastHash();

  @override
  String toString() {
    return r'forecastProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ForecastSeries?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastSeries?> create(Ref ref) {
    final argument = this.argument as int;
    return forecast(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ForecastProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forecastHash() => r'2aea16cc6e72ee61ae157f9637ed2e18e1559310';

/// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
/// account is covered.

final class ForecastFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ForecastSeries?>, int> {
  ForecastFamily._()
    : super(
        retry: null,
        name: r'forecastProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
  /// account is covered.

  ForecastProvider call(int horizonDays) =>
      ForecastProvider._(argument: horizonDays, from: this);

  @override
  String toString() => r'forecastProvider';
}
