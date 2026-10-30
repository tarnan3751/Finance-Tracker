// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How long the runner waits after a change before it writes: two seconds, so a burst of
/// writes (a pull, a bulk edit) redraws the widgets once.

@ProviderFor(widgetDebounce)
final widgetDebounceProvider = WidgetDebounceProvider._();

/// How long the runner waits after a change before it writes: two seconds, so a burst of
/// writes (a pull, a bulk edit) redraws the widgets once.

final class WidgetDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long the runner waits after a change before it writes: two seconds, so a burst of
  /// writes (a pull, a bulk edit) redraws the widgets once.
  WidgetDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return widgetDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$widgetDebounceHash() => r'01d28f400d8c848937eb2baf218e49e8bda2f7fd';

/// Where the snapshot goes: the fake by default (the tests), `home_widget` in every
/// flavor (`overridesFor`).

@ProviderFor(widgetWriter)
final widgetWriterProvider = WidgetWriterProvider._();

/// Where the snapshot goes: the fake by default (the tests), `home_widget` in every
/// flavor (`overridesFor`).

final class WidgetWriterProvider
    extends $FunctionalProvider<WidgetWriter, WidgetWriter, WidgetWriter>
    with $Provider<WidgetWriter> {
  /// Where the snapshot goes: the fake by default (the tests), `home_widget` in every
  /// flavor (`overridesFor`).
  WidgetWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetWriterHash();

  @$internal
  @override
  $ProviderElement<WidgetWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WidgetWriter create(Ref ref) {
    return widgetWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WidgetWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WidgetWriter>(value),
    );
  }
}

String _$widgetWriterHash() => r'991f5b99224a854f2919eac809bf5ee7e622fd04';

/// The strings the snapshot is written in: the device's locale, resolved against the
/// app's.

@ProviderFor(widgetLocalizations)
final widgetLocalizationsProvider = WidgetLocalizationsProvider._();

/// The strings the snapshot is written in: the device's locale, resolved against the
/// app's.

final class WidgetLocalizationsProvider
    extends
        $FunctionalProvider<
          AppLocalizations,
          AppLocalizations,
          AppLocalizations
        >
    with $Provider<AppLocalizations> {
  /// The strings the snapshot is written in: the device's locale, resolved against the
  /// app's.
  WidgetLocalizationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetLocalizationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetLocalizationsHash();

  @$internal
  @override
  $ProviderElement<AppLocalizations> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLocalizations create(Ref ref) {
    return widgetLocalizations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLocalizations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLocalizations>(value),
    );
  }
}

String _$widgetLocalizationsHash() =>
    r'd04880f7312b949f1903071e79b7c1343e6f0069';

/// The snapshot of what the screens show now (`buildWidgetData`), or the signed-out one
/// in dev and prod while nobody is signed in; recomputed whenever any of it changes, the
/// lock setting included. Whether the lock is enabled is read from `app_meta`, so a
/// container whose lock controller has not restored (the background cycle's) never
/// writes an unlocked snapshot by mistake.

@ProviderFor(widgetData)
final widgetDataProvider = WidgetDataProvider._();

/// The snapshot of what the screens show now (`buildWidgetData`), or the signed-out one
/// in dev and prod while nobody is signed in; recomputed whenever any of it changes, the
/// lock setting included. Whether the lock is enabled is read from `app_meta`, so a
/// container whose lock controller has not restored (the background cycle's) never
/// writes an unlocked snapshot by mistake.

final class WidgetDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<WidgetData>,
          WidgetData,
          FutureOr<WidgetData>
        >
    with $FutureModifier<WidgetData>, $FutureProvider<WidgetData> {
  /// The snapshot of what the screens show now (`buildWidgetData`), or the signed-out one
  /// in dev and prod while nobody is signed in; recomputed whenever any of it changes, the
  /// lock setting included. Whether the lock is enabled is read from `app_meta`, so a
  /// container whose lock controller has not restored (the background cycle's) never
  /// writes an unlocked snapshot by mistake.
  WidgetDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetDataHash();

  @$internal
  @override
  $FutureProviderElement<WidgetData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WidgetData> create(Ref ref) {
    return widgetData(ref);
  }
}

String _$widgetDataHash() => r'9d347367a75ff22bdb46a5d0e4abf4d7d00c04be';

/// Keeps the widgets current while listened to (see the library comment); its state is
/// when it last wrote. Not kept alive: it follows [widgetDataProvider], which follows the
/// screens' providers, so it lives while something listens (`bootstrap`, or
/// [writeWidgetsNow]).

@ProviderFor(WidgetRefreshRunner)
final widgetRefreshRunnerProvider = WidgetRefreshRunnerProvider._();

/// Keeps the widgets current while listened to (see the library comment); its state is
/// when it last wrote. Not kept alive: it follows [widgetDataProvider], which follows the
/// screens' providers, so it lives while something listens (`bootstrap`, or
/// [writeWidgetsNow]).
final class WidgetRefreshRunnerProvider
    extends $NotifierProvider<WidgetRefreshRunner, DateTime?> {
  /// Keeps the widgets current while listened to (see the library comment); its state is
  /// when it last wrote. Not kept alive: it follows [widgetDataProvider], which follows the
  /// screens' providers, so it lives while something listens (`bootstrap`, or
  /// [writeWidgetsNow]).
  WidgetRefreshRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetRefreshRunnerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetRefreshRunnerHash();

  @$internal
  @override
  WidgetRefreshRunner create() => WidgetRefreshRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$widgetRefreshRunnerHash() =>
    r'0a6c636ca846efcb4fe8be5293e7c53e24d8bafd';

/// Keeps the widgets current while listened to (see the library comment); its state is
/// when it last wrote. Not kept alive: it follows [widgetDataProvider], which follows the
/// screens' providers, so it lives while something listens (`bootstrap`, or
/// [writeWidgetsNow]).

abstract class _$WidgetRefreshRunner extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
