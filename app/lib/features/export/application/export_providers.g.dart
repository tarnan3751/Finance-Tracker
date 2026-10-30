// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The fonts the monthly report embeds, loaded once from the assets.

@ProviderFor(reportFonts)
final reportFontsProvider = ReportFontsProvider._();

/// The fonts the monthly report embeds, loaded once from the assets.

final class ReportFontsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportFonts>,
          ReportFonts,
          FutureOr<ReportFonts>
        >
    with $FutureModifier<ReportFonts>, $FutureProvider<ReportFonts> {
  /// The fonts the monthly report embeds, loaded once from the assets.
  ReportFontsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportFontsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportFontsHash();

  @$internal
  @override
  $FutureProviderElement<ReportFonts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReportFonts> create(Ref ref) {
    return reportFonts(ref);
  }
}

String _$reportFontsHash() => r'50ea805c498e7db433755ef319e2d38a62fe1785';

/// The monthly report of the period [offset] periods after today's (the Reports
/// segment's periods): its report, the category names, the flags in it less the
/// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
/// them, and the budgets in their period of that offset.

@ProviderFor(monthlyReportData)
final monthlyReportDataProvider = MonthlyReportDataFamily._();

/// The monthly report of the period [offset] periods after today's (the Reports
/// segment's periods): its report, the category names, the flags in it less the
/// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
/// them, and the budgets in their period of that offset.

final class MonthlyReportDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthlyReportData>,
          MonthlyReportData,
          FutureOr<MonthlyReportData>
        >
    with
        $FutureModifier<MonthlyReportData>,
        $FutureProvider<MonthlyReportData> {
  /// The monthly report of the period [offset] periods after today's (the Reports
  /// segment's periods): its report, the category names, the flags in it less the
  /// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
  /// them, and the budgets in their period of that offset.
  MonthlyReportDataProvider._({
    required MonthlyReportDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'monthlyReportDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyReportDataHash();

  @override
  String toString() {
    return r'monthlyReportDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MonthlyReportData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MonthlyReportData> create(Ref ref) {
    final argument = this.argument as int;
    return monthlyReportData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyReportDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyReportDataHash() => r'828dfe9955a0ed606efa388104073e7653c289fa';

/// The monthly report of the period [offset] periods after today's (the Reports
/// segment's periods): its report, the category names, the flags in it less the
/// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
/// them, and the budgets in their period of that offset.

final class MonthlyReportDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MonthlyReportData>, int> {
  MonthlyReportDataFamily._()
    : super(
        retry: null,
        name: r'monthlyReportDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The monthly report of the period [offset] periods after today's (the Reports
  /// segment's periods): its report, the category names, the flags in it less the
  /// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
  /// them, and the budgets in their period of that offset.

  MonthlyReportDataProvider call(int offset) =>
      MonthlyReportDataProvider._(argument: offset, from: this);

  @override
  String toString() => r'monthlyReportDataProvider';
}
