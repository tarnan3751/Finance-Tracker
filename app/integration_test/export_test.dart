// The export on a device, in the demo flavor. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// First, the monthly report's fixture (test/helpers/monthly_report_fixture.dart) drawn
// on the device, with the fonts from the APK's assets, hashes to the same SHA-256 as on
// the host: the bytes depend on nothing the device brings. Then the demo starts as
// main_demo.dart does; Settings, Export, Share of this period's PDF reaches the file
// exporter, which in the demo is the fake: it records a PDF named for the period, and
// nothing leaves the app.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/export/application/export_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report_pdf.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_models/shared_models.dart';

import '../test/helpers/monthly_report_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('export: the fixture\'s PDF hashes as on the host', (
    tester,
  ) async {
    final Uint8List pdf = await buildMonthlyReportPdf(
      monthlyReportFixture(),
      monthlyReportFixtureStrings(),
      fonts: (
        regular: await rootBundle.load(reportRegularFontAsset),
        bold: await rootBundle.load(reportBoldFontAsset),
      ),
      locale: monthlyReportFixtureLocale,
    );

    expect(sha256.convert(pdf).toString(), monthlyReportFixtureSha256);
  });

  testWidgets('export: demo, Settings shares this period\'s PDF', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final FakeFileExporter exporter =
        container.read(fileExporterProvider) as FakeFileExporter;
    final LocalDateRange period = periodAt(
      container.read(todayProvider),
      await container.read(reportStartDayProvider.future),
      0,
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Export'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('In the demo, nothing is saved or shared.'),
      findsOneWidget,
    );
    final Finder share = find.widgetWithText(FilledButton, 'Share…').first;
    // The report's data comes from the demo's whole ledger.
    for (int i = 0; i < 600; i++) {
      if (tester.widget<FilledButton>(share).onPressed != null) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(share);
    for (int i = 0; i < 600 && exporter.calls.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ExportCall call = exporter.calls.single;
    expect(call.kind, ExportKind.share);
    expect(call.fileName, monthlyReportFileName(period));
    expect(call.mimeType, pdfMimeType);
    expect(latin1.decode(call.bytes.sublist(0, 8)), '%PDF-1.5');
    expect(
      latin1.decode(call.bytes),
      contains('/ID[<${'0' * 64}><${'0' * 64}>]'),
    );
  });
}
