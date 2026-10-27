// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_planner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The IANA name of the device's zone, read from the platform each time
/// (`core/time/time_zone_setup.dart`); tests override it.

@ProviderFor(deviceZone)
final deviceZoneProvider = DeviceZoneProvider._();

/// The IANA name of the device's zone, read from the platform each time
/// (`core/time/time_zone_setup.dart`); tests override it.

final class DeviceZoneProvider
    extends
        $FunctionalProvider<
          Future<String> Function(),
          Future<String> Function(),
          Future<String> Function()
        >
    with $Provider<Future<String> Function()> {
  /// The IANA name of the device's zone, read from the platform each time
  /// (`core/time/time_zone_setup.dart`); tests override it.
  DeviceZoneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceZoneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceZoneHash();

  @$internal
  @override
  $ProviderElement<Future<String> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String> Function() create(Ref ref) {
    return deviceZone(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String> Function()>(value),
    );
  }
}

String _$deviceZoneHash() => r'5aca77bcb7e642159c35d7cea716b2b7617a3ba0';

/// How long after the last trigger the reminders are planned.

@ProviderFor(reminderDebounce)
final reminderDebounceProvider = ReminderDebounceProvider._();

/// How long after the last trigger the reminders are planned.

final class ReminderDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long after the last trigger the reminders are planned.
  ReminderDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return reminderDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$reminderDebounceHash() => r'0f3a379f918e34f6585a129f6c8aa08ff3459dc0';

/// Plans the reminders, through [reminderScheduler] and [appNotifier].

@ProviderFor(reminderPlanner)
final reminderPlannerProvider = ReminderPlannerProvider._();

/// Plans the reminders, through [reminderScheduler] and [appNotifier].

final class ReminderPlannerProvider
    extends
        $FunctionalProvider<ReminderPlanner, ReminderPlanner, ReminderPlanner>
    with $Provider<ReminderPlanner> {
  /// Plans the reminders, through [reminderScheduler] and [appNotifier].
  ReminderPlannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderPlannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderPlannerHash();

  @$internal
  @override
  $ProviderElement<ReminderPlanner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReminderPlanner create(Ref ref) {
    return reminderPlanner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderPlanner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderPlanner>(value),
    );
  }
}

String _$reminderPlannerHash() => r'fb2593682452d471ac68428b7baa72357559efd3';

/// Plans the reminders [reminderDebounce] after the last trigger, outside any build,
/// while something listens: `bootstrap` does, from the first frame, for the life of the
/// app.

@ProviderFor(ReminderWatcher)
final reminderWatcherProvider = ReminderWatcherProvider._();

/// Plans the reminders [reminderDebounce] after the last trigger, outside any build,
/// while something listens: `bootstrap` does, from the first frame, for the life of the
/// app.
final class ReminderWatcherProvider
    extends $NotifierProvider<ReminderWatcher, void> {
  /// Plans the reminders [reminderDebounce] after the last trigger, outside any build,
  /// while something listens: `bootstrap` does, from the first frame, for the life of the
  /// app.
  ReminderWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderWatcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderWatcherHash();

  @$internal
  @override
  ReminderWatcher create() => ReminderWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reminderWatcherHash() => r'fbe2e58363f5c38a30f7f25e9c3349b9cd5522ce';

/// Plans the reminders [reminderDebounce] after the last trigger, outside any build,
/// while something listens: `bootstrap` does, from the first frame, for the life of the
/// app.

abstract class _$ReminderWatcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
