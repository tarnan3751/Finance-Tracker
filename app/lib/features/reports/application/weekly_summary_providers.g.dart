// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_summary_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The last complete week's summary and the current week's to today, hidden rows left
/// out, in the reports' currency.

@ProviderFor(weeklyReport)
final weeklyReportProvider = WeeklyReportProvider._();

/// The last complete week's summary and the current week's to today, hidden rows left
/// out, in the reports' currency.

final class WeeklyReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklyReport>,
          WeeklyReport,
          FutureOr<WeeklyReport>
        >
    with $FutureModifier<WeeklyReport>, $FutureProvider<WeeklyReport> {
  /// The last complete week's summary and the current week's to today, hidden rows left
  /// out, in the reports' currency.
  WeeklyReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyReportHash();

  @$internal
  @override
  $FutureProviderElement<WeeklyReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeeklyReport> create(Ref ref) {
    return weeklyReport(ref);
  }
}

String _$weeklyReportHash() => r'e2b60f27e40084cad4e679a61674a735ceba3289';

/// Raises "Your weekly summary is ready" once a week: on the first day in a week that
/// it is listened to (`bootstrap` does, for the life of the app), it tells the
/// `Notifier` about the week before and records this week's Monday in `app_meta`
/// (`weekly_summary_raised`), so the notice is raised once per week on this device.
/// Only a week that began on or after the install day's week is summarised, so a fresh
/// install waits for the next Monday. The install day is `app_meta` `install_date`; the
/// demo, which has none, counts the day of its first evaluation (its launch).
/// A failure is logged by its type.

@ProviderFor(WeeklySummaryNotice)
final weeklySummaryNoticeProvider = WeeklySummaryNoticeProvider._();

/// Raises "Your weekly summary is ready" once a week: on the first day in a week that
/// it is listened to (`bootstrap` does, for the life of the app), it tells the
/// `Notifier` about the week before and records this week's Monday in `app_meta`
/// (`weekly_summary_raised`), so the notice is raised once per week on this device.
/// Only a week that began on or after the install day's week is summarised, so a fresh
/// install waits for the next Monday. The install day is `app_meta` `install_date`; the
/// demo, which has none, counts the day of its first evaluation (its launch).
/// A failure is logged by its type.
final class WeeklySummaryNoticeProvider
    extends $NotifierProvider<WeeklySummaryNotice, void> {
  /// Raises "Your weekly summary is ready" once a week: on the first day in a week that
  /// it is listened to (`bootstrap` does, for the life of the app), it tells the
  /// `Notifier` about the week before and records this week's Monday in `app_meta`
  /// (`weekly_summary_raised`), so the notice is raised once per week on this device.
  /// Only a week that began on or after the install day's week is summarised, so a fresh
  /// install waits for the next Monday. The install day is `app_meta` `install_date`; the
  /// demo, which has none, counts the day of its first evaluation (its launch).
  /// A failure is logged by its type.
  WeeklySummaryNoticeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklySummaryNoticeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklySummaryNoticeHash();

  @$internal
  @override
  WeeklySummaryNotice create() => WeeklySummaryNotice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$weeklySummaryNoticeHash() =>
    r'4d3a6d8e4aee332308fdd5abecbf0d53dc9c19db';

/// Raises "Your weekly summary is ready" once a week: on the first day in a week that
/// it is listened to (`bootstrap` does, for the life of the app), it tells the
/// `Notifier` about the week before and records this week's Monday in `app_meta`
/// (`weekly_summary_raised`), so the notice is raised once per week on this device.
/// Only a week that began on or after the install day's week is summarised, so a fresh
/// install waits for the next Monday. The install day is `app_meta` `install_date`; the
/// demo, which has none, counts the day of its first evaluation (its launch).
/// A failure is logged by its type.

abstract class _$WeeklySummaryNotice extends $Notifier<void> {
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
