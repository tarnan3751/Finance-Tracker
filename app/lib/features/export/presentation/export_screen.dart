/// The export screen (`/settings/export`, `docs/reference/export.md`, **Screens**): the
/// monthly report of a period as a PDF, and the transactions of a date range on chosen
/// accounts as a CSV, each saved through the system's "Save as" dialog or shared, under
/// a note that a file saved or shared leaves the app.
library;

import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_period_selector.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/export/application/export_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/export/presentation/export_runner.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The export screen.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // The report's period, as an offset from today's; its own, apart from the Reports'.
  int _offset = 0;
  // The CSV's dates, null for every transaction's; its accounts, null for all.
  LocalDateRange? _range;
  Set<String>? _accounts;
  bool _busy = false;

  Future<void> _run(Future<void> Function() export) async {
    setState(() => _busy = true);
    try {
      await export();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _exportReport(MonthlyReportData data, {required bool share}) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    unawaited(
      _run(
        () => runExport(
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
    );
  }

  Future<void> _pickRange(LocalDateRange shown) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      currentDate: ref.read(todayProvider).toDateTime(),
      initialDateRange: DateTimeRange(
        start: shown.start.toDateTime(),
        end: shown.end.addDays(-1).toDateTime(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _range = LocalDateRange(
        LocalDate.fromDateTime(picked.start),
        LocalDate.fromDateTime(picked.end).addDays(1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool demo = ref.watch(appConfigProvider).flavor == Flavor.demo;
    final AsyncValue<MonthlyReportData> report = ref.watch(
      monthlyReportDataProvider(_offset),
    );
    final MonthlyReportData? data = report.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_busy)
            LinearProgressIndicator(semanticsLabel: l10n.exportPreparing)
          else
            const SizedBox(height: 4),
          SettingsSectionHeader(l10n.exportReportSection),
          BudgetPeriodSelector(
            offset: _offset,
            dates: data == null
                ? null
                : budgetPeriodLabel(l10n, data.report.current.range),
            onSelected: (offset) => setState(() => _offset = offset),
            showNext: _offset < 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ExportButtons(
              saveLabel: l10n.exportSaveReport,
              shareLabel: l10n.exportShareReport,
              onSave: data == null || _busy
                  ? null
                  : () => _exportReport(data, share: false),
              onShare: data == null || _busy
                  ? null
                  : () => _exportReport(data, share: true),
            ),
          ),
          SettingsSectionHeader(l10n.exportTransactionsSection),
          _TransactionsExport(
            range: _range,
            accounts: _accounts,
            busy: _busy,
            onPickRange: _pickRange,
            onAccounts: (accounts) => setState(() => _accounts = accounts),
            onExport: _run,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: ExportPrivacyNote(demo: demo),
          ),
        ],
      ),
    );
  }
}

/// The CSV's dates, accounts, count and buttons.
class _TransactionsExport extends ConsumerWidget {
  const _TransactionsExport({
    required this.range,
    required this.accounts,
    required this.busy,
    required this.onPickRange,
    required this.onAccounts,
    required this.onExport,
  });

  final LocalDateRange? range;
  final Set<String>? accounts;
  final bool busy;
  final ValueChanged<LocalDateRange> onPickRange;
  final ValueChanged<Set<String>?> onAccounts;
  final Future<void> Function(Future<void> Function()) onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final LocalDate today = ref.watch(todayProvider);
    final List<Transaction>? ledger = ref.watch(recurringLedgerProvider).value;
    final List<Account>? all = ref.watch(accountsProvider).value;
    final List<Category>? categories = ref.watch(categoriesProvider).value;
    if (ledger == null || all == null || categories == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Every transaction's dates by default: the oldest live one's through the later of
    // today and the newest one's (a manual row may be dated ahead).
    LocalDate first = today;
    LocalDate last = today;
    for (final Transaction t in ledger) {
      if (t.date.isBefore(first)) first = t.date;
      if (t.date.isAfter(last)) last = t.date;
    }
    final LocalDateRange shown =
        range ?? LocalDateRange(first, last.addDays(1));
    final Set<String> chosen = accounts ?? {for (final Account a in all) a.id};
    final int count = ledger
        .where((t) => shown.contains(t.date) && chosen.contains(t.accountId))
        .length;
    final DateFormat date = DateFormat.yMMMd();
    void export({required bool share}) {
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      unawaited(
        onExport(
          () => runExport(
            ref,
            messenger: messenger,
            l10n: l10n,
            bytes: () => transactionsCsvFile(
              ledger,
              accounts: all,
              categories: categories,
              range: shown,
              accountIds: chosen,
            ),
            fileName: transactionsFileName(shown),
            mimeType: csvMimeType,
            share: share,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.date_range),
          title: Text(l10n.exportDates),
          subtitle: Text(
            l10n.budgetPeriodRange(
              date.format(shown.start.toDateTime()),
              date.format(shown.end.addDays(-1).toDateTime()),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onPickRange(shown),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Semantics(
            header: true,
            child: Text(
              l10n.exportAccounts,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final Account a in all)
                FilterChip(
                  label: Text(a.name),
                  selected: chosen.contains(a.id),
                  onSelected: (on) => onAccounts(
                    on ? {...chosen, a.id} : ({...chosen}..remove(a.id)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(l10n.exportTransactionCount(count)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ExportButtons(
            saveLabel: l10n.exportSaveTransactions,
            shareLabel: l10n.exportShareTransactions,
            onSave: count == 0 || busy ? null : () => export(share: false),
            onShare: count == 0 || busy ? null : () => export(share: true),
          ),
        ),
      ],
    );
  }
}
