// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The day of the month report periods start: the start day every live budget shares,
/// else 1 (calendar months).

@ProviderFor(reportStartDay)
final reportStartDayProvider = ReportStartDayProvider._();

/// The day of the month report periods start: the start day every live budget shares,
/// else 1 (calendar months).

final class ReportStartDayProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// The day of the month report periods start: the start day every live budget shares,
  /// else 1 (calendar months).
  ReportStartDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportStartDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportStartDayHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return reportStartDay(ref);
  }
}

String _$reportStartDayHash() => r'cc3be100927159405c039b11093371007674775a';

/// The currency the reports are in: the device's default currency when an account holds
/// it, else the first account's in display order, else the default.

@ProviderFor(reportCurrency)
final reportCurrencyProvider = ReportCurrencyProvider._();

/// The currency the reports are in: the device's default currency when an account holds
/// it, else the first account's in display order, else the default.

final class ReportCurrencyProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The currency the reports are in: the device's default currency when an account holds
  /// it, else the first account's in display order, else the default.
  ReportCurrencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportCurrencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportCurrencyHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return reportCurrency(ref);
  }
}

String _$reportCurrencyHash() => r'01452865940cef77d746b0445bb280cb42c1ad1b';

/// The live credit accounts' ids, whose inflows pair the credit card payments
/// (`pairedCardPayments`).

@ProviderFor(reportCreditAccountIds)
final reportCreditAccountIdsProvider = ReportCreditAccountIdsProvider._();

/// The live credit accounts' ids, whose inflows pair the credit card payments
/// (`pairedCardPayments`).

final class ReportCreditAccountIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// The live credit accounts' ids, whose inflows pair the credit card payments
  /// (`pairedCardPayments`).
  ReportCreditAccountIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportCreditAccountIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportCreditAccountIdsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return reportCreditAccountIds(ref);
  }
}

String _$reportCreditAccountIdsHash() =>
    r'0d873368aa5ef83bec23d91096e86159891a3459';

/// Which period the Reports segment shows: 0 for the current one, -1 for the one before.
/// Its own, apart from the budgets'.

@ProviderFor(ReportPeriodOffset)
final reportPeriodOffsetProvider = ReportPeriodOffsetProvider._();

/// Which period the Reports segment shows: 0 for the current one, -1 for the one before.
/// Its own, apart from the budgets'.
final class ReportPeriodOffsetProvider
    extends $NotifierProvider<ReportPeriodOffset, int> {
  /// Which period the Reports segment shows: 0 for the current one, -1 for the one before.
  /// Its own, apart from the budgets'.
  ReportPeriodOffsetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportPeriodOffsetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportPeriodOffsetHash();

  @$internal
  @override
  ReportPeriodOffset create() => ReportPeriodOffset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$reportPeriodOffsetHash() =>
    r'67e434718458086ae68614ecf9716f0a65cc2e81';

/// Which period the Reports segment shows: 0 for the current one, -1 for the one before.
/// Its own, apart from the budgets'.

abstract class _$ReportPeriodOffset extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The report of the period [offset] periods after today's, over every live
/// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
/// payment paired against the live credit accounts' inflows.

@ProviderFor(report)
final reportProvider = ReportFamily._();

/// The report of the period [offset] periods after today's, over every live
/// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
/// payment paired against the live credit accounts' inflows.

final class ReportProvider
    extends $FunctionalProvider<AsyncValue<Report>, Report, FutureOr<Report>>
    with $FutureModifier<Report>, $FutureProvider<Report> {
  /// The report of the period [offset] periods after today's, over every live
  /// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
  /// payment paired against the live credit accounts' inflows.
  ReportProvider._({
    required ReportFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'reportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reportHash();

  @override
  String toString() {
    return r'reportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Report> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Report> create(Ref ref) {
    final argument = this.argument as int;
    return report(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reportHash() => r'0114022dfd108cc13fecfe07cdbae88bf3b14ddc';

/// The report of the period [offset] periods after today's, over every live
/// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
/// payment paired against the live credit accounts' inflows.

final class ReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Report>, int> {
  ReportFamily._()
    : super(
        retry: null,
        name: r'reportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The report of the period [offset] periods after today's, over every live
  /// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
  /// payment paired against the live credit accounts' inflows.

  ReportProvider call(int offset) =>
      ReportProvider._(argument: offset, from: this);

  @override
  String toString() => r'reportProvider';
}
