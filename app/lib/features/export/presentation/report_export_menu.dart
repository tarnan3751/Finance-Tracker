/// The Reports segment's menu (`docs/reference/export.md`, **Screens**): "Export this
/// month as PDF" opens a sheet with the period shown, Save as and Share, and the
/// privacy note. The sheet stays, its buttons off, while its export runs, and closes
/// when it is done.
library;

import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_period_selector.dart';
import 'package:finance_tracker/features/export/application/export_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/export/presentation/export_runner.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Reports segment's app bar menu.
class ReportExportMenu extends ConsumerWidget {
  const ReportExportMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return PopupMenuButton<void>(
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          onTap: () => _openSheet(context, ref),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: Text(l10n.exportReportMenu),
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    // The page's messenger, which its scaffold shows snack bars through; the sheet sits
    // above it, in the root navigator.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int offset = ref.read(reportPeriodOffsetProvider);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        // Scrolls, so the sheet fits at a large text size.
        isScrollControlled: true,
        builder: (sheet) => _ReportExportSheet(
          offset: offset,
          onExport: (data, {required share}) => runExport(
            ref,
            messenger: messenger,
            l10n: l10n,
            bytes: () async => monthlyReportPdf(
              data,
              l10n,
              await ref.read(reportFontsProvider.future),
            ),
            fileName: monthlyReportFileName(data.report.current.range),
            mimeType: pdfMimeType,
            share: share,
          ),
        ),
      ),
    );
  }
}

class _ReportExportSheet extends ConsumerStatefulWidget {
  const _ReportExportSheet({required this.offset, required this.onExport});

  final int offset;
  final Future<void> Function(MonthlyReportData data, {required bool share})
  onExport;

  @override
  ConsumerState<_ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends ConsumerState<_ReportExportSheet> {
  bool _busy = false;

  Future<void> _export(MonthlyReportData data, {required bool share}) async {
    setState(() => _busy = true);
    try {
      await widget.onExport(data, share: share);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final MonthlyReportData? data = ref
        .watch(monthlyReportDataProvider(widget.offset))
        .value;
    final bool ready = data != null && !_busy;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.exportReportSection,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (data != null)
              Text(budgetPeriodLabel(l10n, data.report.current.range)),
            const SizedBox(height: 12),
            if (_busy)
              LinearProgressIndicator(semanticsLabel: l10n.exportPreparing)
            else
              const SizedBox(height: 4),
            const SizedBox(height: 12),
            ExportButtons(
              saveLabel: l10n.exportSaveReport,
              shareLabel: l10n.exportShareReport,
              onSave: ready
                  ? () => unawaited(_export(data, share: false))
                  : null,
              onShare: ready
                  ? () => unawaited(_export(data, share: true))
                  : null,
            ),
            const SizedBox(height: 16),
            ExportPrivacyNote(
              demo: ref.watch(appConfigProvider).flavor == Flavor.demo,
            ),
          ],
        ),
      ),
    );
  }
}
