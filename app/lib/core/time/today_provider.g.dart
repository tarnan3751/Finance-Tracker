// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clock's local date, kept current: a timer fires at the next local midnight in the
/// clock's zone (rescheduled after it fires), and an app resume re-reads it too.

@ProviderFor(Today)
final todayProvider = TodayProvider._();

/// The clock's local date, kept current: a timer fires at the next local midnight in the
/// clock's zone (rescheduled after it fires), and an app resume re-reads it too.
final class TodayProvider extends $NotifierProvider<Today, LocalDate> {
  /// The clock's local date, kept current: a timer fires at the next local midnight in the
  /// clock's zone (rescheduled after it fires), and an app resume re-reads it too.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  Today create() => Today();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$todayHash() => r'd2c32688fb06d60c550499c177d0b3571355d0fe';

/// The clock's local date, kept current: a timer fires at the next local midnight in the
/// clock's zone (rescheduled after it fires), and an app resume re-reads it too.

abstract class _$Today extends $Notifier<LocalDate> {
  LocalDate build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalDate, LocalDate>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalDate, LocalDate>,
              LocalDate,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
