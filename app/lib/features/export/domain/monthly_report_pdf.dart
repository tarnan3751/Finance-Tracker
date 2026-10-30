/// The monthly report as a PDF whose bytes depend only on its inputs
/// (`docs/reference/export.md`, **The PDF**; `PLAN.md` §12 "Export" and "6f plan
/// rulings"). Pure Dart over the `pdf` package.
///
/// **Layout.** A4 portrait, 40 pt margins, Roboto Regular and Bold embedded. From the
/// top: the title, the period and the currency; the headline (spent, income, net, the
/// share kept) with the comparisons against the period before and a year before;
/// spending by category, as bars and as a table with each group's children; the top ten
/// merchants; income and spending over the last six periods; the top movers; what is
/// worth a look; the bills due in the period; the budgets. "Page x of y" at the foot.
///
/// **Determinism.** No clock and no device enters the drawing: every date comes from the
/// data, every amount is a `Money` formatted in [buildMonthlyReportPdf]'s locale, and the
/// page size is fixed. The document carries no metadata (no `/Info`, no creation date),
/// its streams are written uncompressed, and the trailer's `/ID`, which the package
/// draws from the clock and a random source, is replaced by zeros of the same length
/// ([fixDocumentId]), so the offsets in the cross-reference stay right. The bars'
/// lengths are ratios of minor units as `double`s, for placement only.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_models/shared_models.dart';

/// How many category groups the bars show; the rest are one "Other" bar.
const int reportBarLimit = 10;

/// How many merchants the report lists.
const int reportMerchantLimit = 10;

/// The most pages the report may run to.
const int reportMaxPages = 200;

/// The texts of the report, localized by the caller (the app fills them from its ARB).
/// The amounts, percents and dates in them are formatted by the report.
final class MonthlyReportStrings {
  /// The texts.
  const MonthlyReportStrings({
    required this.title,
    required this.range,
    required this.countedThrough,
    required this.amountsIn,
    required this.spent,
    required this.income,
    required this.net,
    required this.savingsRate,
    required this.noIncome,
    required this.vsPrevious,
    required this.vsYearAgo,
    required this.spending,
    required this.incomeLabel,
    required this.change,
    required this.changeNew,
    required this.percent,
    required this.percentUp,
    required this.byCategory,
    required this.uncategorized,
    required this.other,
    required this.groupOwn,
    required this.category,
    required this.share,
    required this.amount,
    required this.nothingInPeriod,
    required this.topMerchants,
    required this.merchant,
    required this.purchases,
    required this.incomeAndSpending,
    required this.period,
    required this.netLabel,
    required this.topMovers,
    required this.moversCategories,
    required this.moversMerchants,
    required this.before,
    required this.now,
    required this.changeLabel,
    required this.noMovers,
    required this.worthALook,
    required this.date,
    required this.why,
    required this.usualMerchant,
    required this.usualCategory,
    required this.newMerchant,
    required this.noAnomalies,
    required this.bills,
    required this.bill,
    required this.due,
    required this.status,
    required this.billPaid,
    required this.billDue,
    required this.billMissed,
    required this.billUpcoming,
    required this.unnamedBill,
    required this.noBills,
    required this.budgets,
    required this.budget,
    required this.available,
    required this.left,
    required this.noBudgets,
    required this.deletedCategory,
    required this.page,
  });

  /// "Monthly report".
  final String title;

  /// "Oct 1 – Oct 31, 2026", from the formatted first and last days.
  final String Function(String start, String end) range;

  /// "Counted through Oct 24, 2026".
  final String Function(String date) countedThrough;

  /// "Amounts in USD".
  final String Function(String currency) amountsIn;

  /// "Spent $1.00".
  final String Function(String amount) spent;

  /// "Income $1.00".
  final String Function(String amount) income;

  /// "Net $1.00".
  final String Function(String amount) net;

  /// "Kept 41 % of income", from the formatted percent.
  final String Function(String percent) savingsRate;

  /// "No income in this period".
  final String noIncome;

  /// "Against the period before".
  final String vsPrevious;

  /// "Against a year before".
  final String vsYearAgo;

  /// "Spending".
  final String spending;

  /// "Income".
  final String incomeLabel;

  /// "+$12.00 (+15 %)".
  final String Function(String amount, String percent) change;

  /// "+$5.00 (new)".
  final String Function(String amount) changeNew;

  /// "15 %" (also "-15 %").
  final String Function(int percent) percent;

  /// "+15 %".
  final String Function(int percent) percentUp;

  /// "By category".
  final String byCategory;

  /// "Uncategorized".
  final String uncategorized;

  /// "Other".
  final String other;

  /// "Food itself".
  final String Function(String name) groupOwn;

  /// The column "Category".
  final String category;

  /// The column "Share".
  final String share;

  /// The column "Amount".
  final String amount;

  /// "Nothing in this period."
  final String nothingInPeriod;

  /// "Top merchants".
  final String topMerchants;

  /// The column "Merchant".
  final String merchant;

  /// "3 purchases".
  final String Function(int count) purchases;

  /// "Income and spending".
  final String incomeAndSpending;

  /// The column "Period".
  final String period;

  /// The column "Net".
  final String netLabel;

  /// "Top movers".
  final String topMovers;

  /// "Categories".
  final String moversCategories;

  /// "Merchants".
  final String moversMerchants;

  /// The column "Before".
  final String before;

  /// The column "Now".
  final String now;

  /// The column "Change".
  final String changeLabel;

  /// "Nothing changed from the period before."
  final String noMovers;

  /// "Worth a look".
  final String worthALook;

  /// The column "Date".
  final String date;

  /// The column "Why".
  final String why;

  /// "Usually about $45.00 here".
  final String Function(String amount) usualMerchant;

  /// "Usually about $45.00 in this category".
  final String Function(String amount) usualCategory;

  /// "New: not seen in the last six months".
  final String newMerchant;

  /// "Nothing stands out in this period."
  final String noAnomalies;

  /// "Bills".
  final String bills;

  /// The column "Bill".
  final String bill;

  /// The column "Due".
  final String due;

  /// The column "Status".
  final String status;

  /// "Paid".
  final String billPaid;

  /// "Due".
  final String billDue;

  /// "Missed".
  final String billMissed;

  /// "Upcoming".
  final String billUpcoming;

  /// "Bill", the name of a bill without one.
  final String unnamedBill;

  /// "No bills due in this period."
  final String noBills;

  /// "Budgets".
  final String budgets;

  /// The column "Budget".
  final String budget;

  /// The column "Available".
  final String available;

  /// The column "Left".
  final String left;

  /// "No budgets yet."
  final String noBudgets;

  /// "Deleted category", a budget's whose category is gone.
  final String deletedCategory;

  /// "Page 1 of 3".
  final String Function(int page, int count) page;
}

/// The fonts the report embeds: Roboto Regular and Bold, as TrueType bytes.
typedef ReportFonts = ({ByteData regular, ByteData bold});

/// The PDF of [data], in [strings], with [fonts], amounts and dates formatted in
/// [locale]. The same inputs give the same bytes, on any device.
Future<Uint8List> buildMonthlyReportPdf(
  MonthlyReportData data,
  MonthlyReportStrings strings, {
  required ReportFonts fonts,
  required String locale,
}) async {
  final pw.Document document = pw.Document(
    compress: false,
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(fonts.regular),
      bold: pw.Font.ttf(fonts.bold),
    ),
  );
  final _Report r = _Report(data, strings, locale);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      // The package's default stops at 20 pages; a long bill list or many categories
      // must not.
      maxPages: reportMaxPages,
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          strings.page(context.pageNumber, context.pagesCount),
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ),
      build: (_) => r.build(),
    ),
  );
  return fixDocumentId(await document.save());
}

// The document id as the package writes it in the trailer: two binary strings of a
// SHA-256 in hex.
final RegExp _documentId = RegExp(r'/ID\[<[0-9a-f]{64}><[0-9a-f]{64}>\]');

/// [pdf] with the trailer's `/ID`, drawn from the clock and a random source, replaced by
/// zeros of the same length. Throws [StateError] unless there is exactly one.
Uint8List fixDocumentId(Uint8List pdf) {
  // latin1 maps every byte to one code unit and back, so the binary streams survive.
  final String text = latin1.decode(pdf);
  final List<RegExpMatch> ids = _documentId.allMatches(text).toList();
  if (ids.length != 1) {
    throw StateError('expected one document id, found ${ids.length}');
  }
  final String zeros = '0' * 64;
  return latin1.encode(
    text.replaceRange(
      ids.single.start,
      ids.single.end,
      '/ID[<$zeros><$zeros>]',
    ),
  );
}

const PdfColor _muted = PdfColor.fromInt(0xFF5F6368);
const PdfColor _rule = PdfColor.fromInt(0xFFDADCE0);
const PdfColor _bar = PdfColor.fromInt(0xFF1A73E8);
const PdfColor _alert = PdfColor.fromInt(0xFFB3261E);

// The width of the page's text block: A4's 595.28 pt less the margins.
const double _contentWidth = 515;

// One report being drawn.
final class _Report {
  _Report(this.data, this.s, this.locale);

  final MonthlyReportData data;
  final MonthlyReportStrings s;
  final String locale;

  Report get report => data.report;
  ReportPeriod get current => report.current;

  String money(Money m, {bool plus = false}) =>
      m.format(locale: locale, showPlusSign: plus);

  String day(LocalDate d) => DateFormat.yMMMd(locale).format(d.toDateTime());

  String shortDay(LocalDate d) =>
      DateFormat.MMMd(locale).format(d.toDateTime());

  String periodName(LocalDateRange range) =>
      DateFormat.yMMM(locale).format(range.start.toDateTime());

  String categoryName(String? id) =>
      id == null ? s.uncategorized : data.categoryNames[id] ?? s.uncategorized;

  // [change] as "+$12.00 (+15 %)", or "+$5.00 (new)" on a zero base.
  String changeText(Change change) {
    final String amount = money(change.change, plus: true);
    return switch (change.percentBasisPoints) {
      null => s.changeNew(amount),
      final int bp => s.change(
        amount,
        bp > 0 ? s.percentUp(bp ~/ 100) : s.percent(bp ~/ 100),
      ),
    };
  }

  // [part] of [whole] as a whole percent, truncated; empty when [whole] is not positive.
  String shareText(Money part, Money whole) => whole.isPositive
      ? s.percent(
          part
                  .multipliedBy(
                    10000,
                    whole.minorUnits,
                    mode: RoundingMode.floor,
                  )
                  .minorUnits ~/
              100,
        )
      : '';

  List<pw.Widget> build() => [
    ..._header(),
    ..._headline(),
    ..._categories(),
    ..._merchants(),
    ..._trend(),
    ..._movers(),
    ..._anomalies(),
    ..._bills(),
    ..._budgets(),
  ];

  List<pw.Widget> _header() {
    final LocalDateRange range = current.range;
    return [
      pw.Text(
        s.title,
        style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        s.range(day(range.start), day(range.end.addDays(-1))),
        style: const pw.TextStyle(fontSize: 12),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        [
          s.amountsIn(current.currencyCode),
          if (current.partial) s.countedThrough(day(current.through)),
        ].join(' · '),
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    ];
  }

  List<pw.Widget> _headline() {
    final int? rate = current.savingsRateBasisPoints;
    return [
      pw.SizedBox(height: 16),
      pw.Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          for (final String text in [
            s.spent(money(current.spend)),
            s.income(money(current.income)),
            s.net(money(current.net)),
          ])
            pw.Text(
              text,
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        rate == null ? s.noIncome : s.savingsRate(s.percent(rate ~/ 100)),
        style: pw.TextStyle(color: rate != null && rate < 0 ? _alert : null),
      ),
      pw.SizedBox(height: 8),
      ..._table(
        header: ['', s.vsPrevious, s.vsYearAgo],
        widths: const [1, 1.5, 1.5],
        numeric: const {1, 2},
        rows: [
          _Row([
            s.spending,
            changeText(report.spendMonthOverMonth),
            changeText(report.spendYearOverYear),
          ]),
          _Row([
            s.incomeLabel,
            changeText(report.incomeMonthOverMonth),
            changeText(report.incomeYearOverYear),
          ]),
        ],
      ),
    ];
  }

  List<pw.Widget> _categories() {
    final List<CategoryTotal> totals = current.spendByCategory;
    final List<CategoryTotal> groups = ReportPeriod.topLevel(totals);
    if (groups.isEmpty) {
      return _section(s.byCategory, [_empty(s.nothingInPeriod)]);
    }
    final Money total = current.spend;
    final Money zero = Money.zero(current.currencyCode);
    final List<({String name, Money amount})> bars = [
      for (final CategoryTotal g in groups.take(reportBarLimit))
        (name: categoryName(g.categoryId), amount: g.total),
      if (groups.length > reportBarLimit)
        (
          name: s.other,
          amount: Money.sum([
            for (final g in groups.skip(reportBarLimit)) g.total,
          ], currencyCode: current.currencyCode),
        ),
    ];
    final Money largest = bars
        .map((b) => b.amount)
        .fold(zero, (a, b) => b > a ? b : a);
    final List<_Row> rows = [];
    for (final CategoryTotal g in groups) {
      rows.add(
        _Row([
          categoryName(g.categoryId),
          shareText(g.total, total),
          money(g.total),
        ], bold: true),
      );
      final List<CategoryTotal> children = g.categoryId == null
          ? const []
          : ReportPeriod.childrenOf(totals, g.categoryId!);
      if (children.isEmpty) continue;
      if (!g.own.isZero) {
        rows.add(
          _Row([
            s.groupOwn(categoryName(g.categoryId)),
            shareText(g.own, total),
            money(g.own),
          ], indent: true),
        );
      }
      for (final CategoryTotal c in children) {
        rows.add(
          _Row([
            categoryName(c.categoryId),
            shareText(c.total, total),
            money(c.total),
          ], indent: true),
        );
      }
    }
    return [
      ..._section(s.byCategory, [
        for (final b in bars) _barRow(b.name, b.amount, largest),
      ]),
      pw.SizedBox(height: 8),
      ..._table(
        header: [s.category, s.share, s.amount],
        widths: const [3, 1, 1.4],
        numeric: const {1, 2},
        rows: rows,
      ),
    ];
  }

  // A labelled bar: [amount] against [largest], none when either is not positive.
  pw.Widget _barRow(String name, Money amount, Money largest) {
    const double nameWidth = 150;
    const double amountWidth = 95;
    const double barWidth = _contentWidth - nameWidth - amountWidth - 10;
    final double fraction = amount.isPositive && largest.isPositive
        ? amount.minorUnits / largest.minorUnits
        : 0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: nameWidth,
            child: pw.Text(name, maxLines: 1, style: _small),
          ),
          pw.CustomPaint(
            size: const PdfPoint(barWidth, 10),
            painter: (canvas, size) {
              if (fraction <= 0) return;
              canvas
                ..setFillColor(_bar)
                ..drawRect(0, 0, size.x * fraction, size.y)
                ..fillPath();
            },
          ),
          pw.SizedBox(width: 10),
          pw.SizedBox(
            width: amountWidth,
            child: pw.Text(
              money(amount),
              textAlign: pw.TextAlign.right,
              style: _small,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _merchants() {
    final List<MerchantTotal> merchants = current.spendByMerchant
        .take(reportMerchantLimit)
        .toList();
    return merchants.isEmpty
        ? _section(s.topMerchants, [_empty(s.nothingInPeriod)])
        : _table(
            heading: s.topMerchants,
            header: [s.merchant, '', s.amount],
            widths: const [3, 1.4, 1.4],
            numeric: const {1, 2},
            rows: [
              for (final MerchantTotal m in merchants)
                _Row([m.displayName, s.purchases(m.count), money(m.total)]),
            ],
          );
  }

  List<pw.Widget> _trend() => _table(
    heading: s.incomeAndSpending,
    header: [s.period, s.incomeLabel, s.spending, s.netLabel],
    widths: const [1.4, 1, 1, 1],
    numeric: const {1, 2, 3},
    rows: [
      for (final TrendPoint p in report.shortTrend.reversed)
        _Row([
          periodName(p.range),
          money(p.income),
          money(p.spend),
          money(p.net),
        ]),
    ],
  );

  List<pw.Widget> _movers() {
    if (report.categoryMovers.isEmpty && report.merchantMovers.isEmpty) {
      return _section(s.topMovers, [_empty(s.noMovers)]);
    }
    List<pw.Widget> movers(
      String title,
      List<Mover> list,
      String Function(Mover) name, {
      String? heading,
    }) => _table(
      heading: heading,
      header: [title, s.before, s.now, s.changeLabel],
      widths: const [2.4, 1, 1, 1.6],
      numeric: const {1, 2, 3},
      rows: [
        for (final Mover m in list)
          _Row([
            name(m),
            money(m.change.previous),
            money(m.change.current),
            changeText(m.change),
          ]),
      ],
    );
    final bool categories = report.categoryMovers.isNotEmpty;
    return [
      if (categories)
        ...movers(
          s.moversCategories,
          report.categoryMovers,
          (m) => categoryName(m.id),
          heading: s.topMovers,
        ),
      if (categories && report.merchantMovers.isNotEmpty)
        pw.SizedBox(height: 8),
      if (report.merchantMovers.isNotEmpty)
        ...movers(
          s.moversMerchants,
          report.merchantMovers,
          (m) => m.displayName ?? m.id ?? '',
          heading: categories ? null : s.topMovers,
        ),
    ];
  }

  List<pw.Widget> _anomalies() => data.anomalies.isEmpty
      ? _section(s.worthALook, [_empty(s.noAnomalies)])
      : _table(
          heading: s.worthALook,
          header: [s.date, s.merchant, s.amount, s.why],
          widths: const [0.8, 1.6, 1, 2.4],
          numeric: const {2},
          rows: [
            for (final AnomalyFlag f in data.anomalies)
              _Row([
                shortDay(f.transaction.date),
                EnrichedMerchant.resolve(f.transaction).displayName,
                money(f.amount),
                switch (f) {
                  AnomalyFlag(
                    kind: AnomalyKind.unusualAmount,
                    basis: AnomalyBasis.category,
                    :final Money median,
                  ) =>
                    s.usualCategory(money(median)),
                  AnomalyFlag(
                    kind: AnomalyKind.unusualAmount,
                    :final Money median,
                  ) =>
                    s.usualMerchant(money(median)),
                  _ => s.newMerchant,
                },
              ]),
          ],
        );

  List<pw.Widget> _bills() => data.bills.isEmpty
      ? _section(s.bills, [_empty(s.noBills)])
      : _table(
          heading: s.bills,
          header: [s.bill, s.due, s.amount, s.status],
          widths: const [2.4, 1, 1.2, 1],
          numeric: const {2},
          rows: [
            for (final ReportBill b in data.bills)
              _Row([
                b.name ?? s.unnamedBill,
                shortDay(b.due),
                b.amount == null ? '' : money(b.amount!.abs()),
                switch (b.state) {
                  BillState.paid => s.billPaid,
                  BillState.due => s.billDue,
                  BillState.missed => s.billMissed,
                  BillState.upcoming => s.billUpcoming,
                },
              ], alert: b.state == BillState.missed),
          ],
        );

  List<pw.Widget> _budgets() => data.budgets.isEmpty
      ? _section(s.budgets, [_empty(s.noBudgets)])
      : _table(
          heading: s.budgets,
          header: [s.budget, s.period, s.spending, s.available, s.left],
          widths: const [1.8, 1.8, 1, 1, 1],
          numeric: const {2, 3, 4},
          rows: [
            for (final ReportBudget b in data.budgets)
              () {
                final BudgetStatus st = b.status;
                return _Row([
                  b.name ?? s.deletedCategory,
                  s.range(
                    shortDay(st.period.start),
                    shortDay(st.period.end.addDays(-1)),
                  ),
                  money(st.spent),
                  money(st.available),
                  money(st.remaining),
                ], alert: st.remaining.isNegative);
              }(),
          ],
        );

  pw.Widget _heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _empty(String text) =>
      pw.Text(text, style: const pw.TextStyle(color: _muted));

  // [heading] over [content], kept on one page.
  List<pw.Widget> _section(String heading, List<pw.Widget> content) => [
    pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [_heading(heading), ...content],
      ),
    ),
  ];

  // A table: [header] in bold over [rows], the [numeric] columns right-aligned, the
  // columns as wide as [widths] in proportion; under [heading] when given. A table of
  // at most [_keptRows] rows stays on one page with its heading; a longer one keeps its
  // heading with its first [_leadRows] rows, and the rest follows, splitting across
  // pages as it needs.
  List<pw.Widget> _table({
    String? heading,
    required List<String> header,
    required List<double> widths,
    required Set<int> numeric,
    required List<_Row> rows,
  }) {
    pw.Widget cell(
      int column,
      String text,
      pw.TextStyle style, {
      bool indent = false,
    }) => pw.Padding(
      padding: pw.EdgeInsets.fromLTRB(
        column == 0 ? (indent ? 14 : 2) : 8,
        3,
        2,
        3,
      ),
      child: pw.Text(
        text,
        style: style,
        textAlign: numeric.contains(column)
            ? pw.TextAlign.right
            : pw.TextAlign.left,
      ),
    );
    final pw.TextStyle headerStyle = _small.copyWith(
      fontWeight: pw.FontWeight.bold,
      color: _muted,
    );
    pw.Table table(Iterable<_Row> rows, {bool withHeader = true}) => pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rule, width: 0.5),
      ),
      columnWidths: {
        for (int i = 0; i < widths.length; i++)
          i: pw.FlexColumnWidth(widths[i]),
      },
      children: [
        if (withHeader)
          pw.TableRow(
            repeat: true,
            children: [
              for (int i = 0; i < header.length; i++)
                cell(i, header[i], headerStyle),
            ],
          ),
        for (final _Row row in rows)
          pw.TableRow(
            children: [
              for (int i = 0; i < row.cells.length; i++)
                cell(
                  i,
                  row.cells[i],
                  _small.copyWith(
                    fontWeight: row.bold ? pw.FontWeight.bold : null,
                    color: row.alert ? _alert : null,
                  ),
                  indent: row.indent,
                ),
            ],
          ),
      ],
    );
    if (heading == null) return [table(rows)];
    if (rows.length <= _keptRows) return _section(heading, [table(rows)]);
    return [
      ..._section(heading, [table(rows.take(_leadRows))]),
      table(rows.skip(_leadRows), withHeader: false),
    ];
  }
}

// The longest table kept on one page with its heading.
const int _keptRows = 14;

// The rows a longer table keeps with its heading.
const int _leadRows = 3;

const pw.TextStyle _small = pw.TextStyle(fontSize: 9);

// A table row's cells and style.
final class _Row {
  const _Row(
    this.cells, {
    this.bold = false,
    this.indent = false,
    this.alert = false,
  });

  final List<String> cells;
  final bool bold;
  final bool indent;
  final bool alert;
}
