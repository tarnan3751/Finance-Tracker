// The export on the report household (report_seed.dart), as of 24 October 2026: the
// Settings entry opens the screen; the PDF of the period chosen is shared or saved
// through the file exporter (the fake here), "Saved <name>" after a save, nothing after
// a cancel, the failure told; the CSV holds the transactions of every date and account
// by default (through a manual row dated ahead of today), the account chips narrow it and
// none disables the buttons; a file that cannot be made is told too; the Reports menu's
// "Export this month as PDF" shares the period shown, its sheet staying, buttons off,
// until the export is done; and the privacy note, with its demo line only in the demo.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/platform/fake_file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/features/export/domain/transactions_csv.dart';
import 'package:finance_tracker/features/export/presentation/export_runner.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';
import '../../../helpers/seed.dart';

const String _privacy =
    "A file you save or share leaves the app's encrypted storage. Anyone who has "
    'the file can read it.';

// An exporter whose shares wait for [release], recording each when it starts.
final class _HeldExporter implements FileExporter {
  final Completer<void> release = Completer<void>();
  final List<String> shared = [];

  @override
  Future<SaveOutcome> saveAs(Uint8List b, String name, String type) async =>
      SaveOutcome.saved;

  @override
  Future<void> share(Uint8List b, String name, String type) async {
    shared.add(name);
    await release.future;
  }
}

Future<FakeFileExporter> _open(
  WidgetTester tester, {
  String location = '/settings/export',
  FakeFileExporter? exporter,
  FileExporter? other,
  InMemoryStore? store,
  AppConfig? config,
}) async {
  final FakeFileExporter fake = exporter ?? FakeFileExporter();
  await pumpApp(
    tester,
    overrides: [
      ...reportOverrides(store: store),
      fileExporterProvider.overrideWithValue(other ?? fake),
    ],
    initialLocation: location,
    config: config,
  );
  return fake;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  // The PDF's bytes are made on the event loop, with the fonts from the bundle.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _settle(
  WidgetTester tester,
  FakeFileExporter fake,
  int calls,
) async {
  for (int i = 0; i < 100 && fake.calls.length < calls; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.bySemanticsLabel(label);

void main() {
  testWidgets('Settings opens the export', (tester) async {
    await _open(tester, location: '/settings');

    await _tap(tester, find.text('Export'));

    expect(find.text('Monthly report (PDF)'), findsOneWidget);
    expect(find.text('Transactions (CSV)'), findsOneWidget);
    expect(find.text(_privacy), findsOneWidget);
  });

  testWidgets('share the PDF of the period chosen', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeFileExporter fake = await _open(tester);

    await _tap(tester, find.byTooltip('Previous period'));
    await _tap(tester, _button('Share the monthly report as a PDF'));
    await _settle(tester, fake, 1);

    final ExportCall call = fake.calls.single;
    expect(call.kind, ExportKind.share);
    expect(call.fileName, 'report-2026-09.pdf');
    expect(call.mimeType, 'application/pdf');
    expect(latin1.decode(call.bytes.sublist(0, 8)), '%PDF-1.5');
    expect(find.byType(SnackBar), findsNothing);
    semantics.dispose();
  });

  testWidgets('a saved PDF is told, a cancel is not', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeFileExporter fake = await _open(tester);

    await _tap(tester, _button('Save the monthly report as a PDF'));
    await _settle(tester, fake, 1);
    expect(fake.calls.single.fileName, 'report-2026-10.pdf');
    expect(find.text('Saved report-2026-10.pdf'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(ListView).first))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    fake.outcome = SaveOutcome.cancelled;
    await _tap(tester, _button('Save the monthly report as a PDF'));
    await _settle(tester, fake, 2);
    expect(fake.calls, hasLength(2));
    expect(find.byType(SnackBar), findsNothing);
    semantics.dispose();
  });

  testWidgets('a failure is told', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeFileExporter fake = await _open(
      tester,
      exporter: FakeFileExporter(failure: const ExportFailedException()),
    );

    await _tap(tester, _button('Save the transactions as a CSV'));
    await _settle(tester, fake, 1);

    expect(
      find.text('The file could not be exported. Try again.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the CSV holds every date and account by default', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeFileExporter fake = await _open(tester);

    // Fourteen months from August 2025 to today.
    expect(find.text('Aug 1, 2025 – Oct 24, 2026'), findsOneWidget);
    await _tap(tester, _button('Save the transactions as a CSV'));
    await _settle(tester, fake, 1);

    final ExportCall call = fake.calls.single;
    expect(call.fileName, 'transactions-2025-08-01-to-2026-10-24.csv');
    expect(call.mimeType, 'text/csv');
    final List<String> lines = utf8.decode(call.bytes).split('\r\n');
    expect(lines.first, transactionsCsvHeader.join(','));
    expect(lines.last, isEmpty);
    expect(
      find.text('${lines.length - 2} transactions'),
      findsOneWidget,
      reason: 'the count shown is the records written',
    );
    expect(
      find.text('Saved transactions-2025-08-01-to-2026-10-24.csv'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every date by default reaches a row dated ahead of today', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final InMemoryStore store = reportStore()
      ..upsertTransactions([
        testTransaction(
          'future-rent',
          accountId: reportCheckingId,
          daysAgo: -62,
          name: 'Rent paid ahead',
        ),
      ]);
    final FakeFileExporter fake = await _open(tester, store: store);

    expect(find.text('Aug 1, 2025 – Dec 25, 2026'), findsOneWidget);
    await _tap(tester, _button('Save the transactions as a CSV'));
    await _settle(tester, fake, 1);

    final ExportCall call = fake.calls.single;
    expect(call.fileName, 'transactions-2025-08-01-to-2026-12-25.csv');
    final List<String> lines = utf8.decode(call.bytes).split('\r\n');
    expect(lines[lines.length - 2], startsWith('2026-12-25,'));
    expect(lines[lines.length - 2], endsWith(',future-rent'));
    semantics.dispose();
  });

  testWidgets('a file that cannot be made is told, and nothing exported', (
    tester,
  ) async {
    final FakeFileExporter fake = FakeFileExporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [fileExporterProvider.overrideWithValue(fake)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => runExport(
                  ref,
                  messenger: ScaffoldMessenger.of(context),
                  l10n: AppLocalizations.of(context),
                  bytes: () async => throw StateError('no document id'),
                  fileName: 'report-2026-10.pdf',
                  mimeType: 'application/pdf',
                  share: false,
                ),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(
      find.text('The file could not be exported. Try again.'),
      findsOneWidget,
    );
    expect(fake.calls, isEmpty);
  });

  testWidgets(
    'the Reports sheet stays, buttons off, until its export is done',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _HeldExporter held = _HeldExporter();
      await _open(tester, location: '/reports', other: held);

      await _tap(tester, find.byTooltip('Show menu'));
      await _tap(tester, find.text('Export this month as PDF'));
      // Not settled: the progress bar runs until the export is done.
      await tester.tap(_button('Share the monthly report as a PDF'));
      await tester.pump();
      for (int i = 0; i < 100 && held.shared.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(held.shared, ['report-2026-10.pdf']);
      expect(find.text('Monthly report (PDF)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final FilledButton share = tester.widget(
        find.widgetWithText(FilledButton, 'Share…'),
      );
      expect(share.onPressed, isNull);

      held.release.complete();
      await tester.pumpAndSettle();
      expect(find.text('Monthly report (PDF)'), findsNothing);
      expect(held.shared, hasLength(1));
      semantics.dispose();
    },
  );

  testWidgets('no account chosen disables the CSV', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _open(tester);

    await _tap(tester, find.widgetWithText(FilterChip, 'Everyday Checking'));

    expect(
      find.text('No transactions in these dates and accounts'),
      findsOneWidget,
    );
    final OutlinedButton save = tester.widget(
      find.widgetWithText(OutlinedButton, 'Save as…').last,
    );
    expect(save.onPressed, isNull);
    semantics.dispose();
  });

  testWidgets('the Reports menu shares the period shown', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FakeFileExporter fake = await _open(tester, location: '/reports');

    await _tap(tester, find.byTooltip('Previous period'));
    await _tap(tester, find.byTooltip('Show menu'));
    await _tap(tester, find.text('Export this month as PDF'));
    expect(find.text('Sep 1 – Sep 30, 2026'), findsWidgets);
    expect(find.text(_privacy), findsOneWidget);

    await _tap(tester, _button('Share the monthly report as a PDF'));
    await _settle(tester, fake, 1);

    expect(fake.calls.single.kind, ExportKind.share);
    expect(fake.calls.single.fileName, 'report-2026-09.pdf');
    expect(find.text('Export this month as PDF'), findsNothing);
    semantics.dispose();
  });

  testWidgets('the demo says nothing is saved or shared', (tester) async {
    await _open(tester, config: AppConfig.demo());

    expect(
      find.text('$_privacy In the demo, nothing is saved or shared.'),
      findsOneWidget,
    );
  });
}
