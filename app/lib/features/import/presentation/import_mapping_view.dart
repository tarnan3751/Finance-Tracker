/// The import's mapping step (`docs/reference/import.md`, **The mapping screen**): the
/// header row and the field separator, a column for each role with a sample from the
/// file, the amount as one column or money out and in, the date format (each reading of
/// ambiguous dates shown on the file's first samples), the decimal separator, the sign
/// switch, and the account, an existing one or a new manual account.
library;

import 'package:finance_tracker/features/accounts/presentation/account_type_style.dart';
import 'package:finance_tracker/features/accounts/presentation/currency_picker.dart';
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/import_mapping.dart';
import 'package:finance_tracker/features/settings/presentation/settings_section_header.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// How many rows the header row choice offers, the detected one included past them.
const int headerRowChoices = 20;

/// What the mapping step holds.
@immutable
final class MappingDraft {
  const MappingDraft({
    required this.headerRow,
    this.columns = const {},
    this.debitCredit = false,
    this.dateFormat,
    this.dateCandidates = const [],
    this.separator = DecimalSeparator.point,
    this.separatorDetected = true,
    this.outflowsNegative = true,
    this.accountId,
    this.newAccount = false,
    this.newName = '',
    this.newType = AccountType.depository,
    required this.newCurrency,
    this.presetApplied = false,
  });

  /// The index of the header row in the file's rows.
  final int headerRow;

  /// Each mapped role's column.
  final Map<ImportRole, int> columns;
  final bool debitCredit;

  /// The chosen date format; null while none reads the dates.
  final ImportDateFormat? dateFormat;

  /// The formats that read the date column best.
  final List<ImportDateFormat> dateCandidates;
  final DecimalSeparator separator;

  /// Whether the amounts said which separator they use.
  final bool separatorDetected;
  final bool outflowsNegative;

  /// The existing account chosen, unless [newAccount].
  final String? accountId;
  final bool newAccount;
  final String newName;
  final AccountType newType;
  final String newCurrency;

  /// Whether the mapping came from the preset for this header.
  final bool presetApplied;

  static const Object _keep = Object();

  MappingDraft copyWith({
    int? headerRow,
    Map<ImportRole, int>? columns,
    bool? debitCredit,
    Object? dateFormat = _keep,
    List<ImportDateFormat>? dateCandidates,
    DecimalSeparator? separator,
    bool? separatorDetected,
    bool? outflowsNegative,
    Object? accountId = _keep,
    bool? newAccount,
    String? newName,
    AccountType? newType,
    String? newCurrency,
    bool? presetApplied,
  }) => MappingDraft(
    headerRow: headerRow ?? this.headerRow,
    columns: columns ?? this.columns,
    debitCredit: debitCredit ?? this.debitCredit,
    dateFormat: identical(dateFormat, _keep)
        ? this.dateFormat
        : dateFormat as ImportDateFormat?,
    dateCandidates: dateCandidates ?? this.dateCandidates,
    separator: separator ?? this.separator,
    separatorDetected: separatorDetected ?? this.separatorDetected,
    outflowsNegative: outflowsNegative ?? this.outflowsNegative,
    accountId: identical(accountId, _keep)
        ? this.accountId
        : accountId as String?,
    newAccount: newAccount ?? this.newAccount,
    newName: newName ?? this.newName,
    newType: newType ?? this.newType,
    newCurrency: newCurrency ?? this.newCurrency,
    presetApplied: presetApplied ?? this.presetApplied,
  );

  /// The mapping, or null while a required role has no column or no format reads the
  /// dates.
  ImportMapping? get mapping {
    final ImportDateFormat? format = dateFormat;
    if (format == null) return null;
    final ImportMapping m = ImportMapping(
      columns: {
        for (final MapEntry(key: ImportRole role, value: int c)
            in columns.entries)
          if (_rolesFor(debitCredit).contains(role)) role: c,
      },
      debitCredit: debitCredit,
      dateFormat: format,
      separator: separator,
      outflowsNegative: outflowsNegative,
    );
    return m.isComplete ? m : null;
  }
}

/// The roles offered with [debitCredit] or one amount column, in order.
List<ImportRole> _rolesFor(bool debitCredit) => [
  ImportRole.date,
  ImportRole.description,
  if (debitCredit) ...[ImportRole.debit, ImportRole.credit],
  if (!debitCredit) ImportRole.amount,
  ImportRole.merchant,
  ImportRole.notes,
  ImportRole.category,
  ImportRole.tags,
];

bool _required(ImportRole role) => switch (role) {
  ImportRole.date ||
  ImportRole.description ||
  ImportRole.amount ||
  ImportRole.debit ||
  ImportRole.credit => true,
  _ => false,
};

String _roleLabel(AppLocalizations l10n, ImportRole role) => switch (role) {
  ImportRole.date => l10n.importRoleDate,
  ImportRole.amount => l10n.importRoleAmount,
  ImportRole.debit => l10n.importRoleDebit,
  ImportRole.credit => l10n.importRoleCredit,
  ImportRole.description => l10n.importRoleDescription,
  ImportRole.merchant => l10n.importRoleMerchant,
  ImportRole.notes => l10n.importRoleNotes,
  ImportRole.category => l10n.importRoleCategory,
  ImportRole.tags => l10n.importRoleTags,
};

String _delimiterLabel(AppLocalizations l10n, String delimiter) =>
    switch (delimiter) {
      ';' => l10n.importDelimiterSemicolon,
      '\t' => l10n.importDelimiterTab,
      '|' => l10n.importDelimiterPipe,
      _ => l10n.importDelimiterComma,
    };

/// The mapping step over [table].
class ImportMappingView extends StatefulWidget {
  const ImportMappingView({
    super.key,
    required this.table,
    required this.draft,
    required this.accounts,
    required this.busy,
    this.error,
    required this.onChanged,
    required this.onHeaderRow,
    required this.onDelimiter,
    required this.onReview,
  });

  final CsvTable table;
  final MappingDraft draft;

  /// The live accounts the rows may go into.
  final List<Account> accounts;
  final bool busy;

  /// Why the last review failed, or null.
  final String? error;

  /// A change that needs no detection.
  final ValueChanged<MappingDraft> onChanged;

  /// Another header row chosen.
  final ValueChanged<int> onHeaderRow;

  /// Another field separator chosen.
  final ValueChanged<String> onDelimiter;
  final VoidCallback onReview;

  @override
  State<ImportMappingView> createState() => _ImportMappingViewState();
}

class _ImportMappingViewState extends State<ImportMappingView> {
  late final TextEditingController _name = TextEditingController(
    text: widget.draft.newName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  MappingDraft get _draft => widget.draft;

  List<String> get _header => widget.table.rows[_draft.headerRow];

  // The first non-blank value under [column], if any.
  String? _sample(int column) {
    for (final List<String> row in widget.table.rows.skip(
      _draft.headerRow + 1,
    )) {
      if (column < row.length && row[column].trim().isNotEmpty) {
        return row[column].trim();
      }
    }
    return null;
  }

  String _columnName(AppLocalizations l10n, int column) {
    final String name = column < _header.length ? _header[column].trim() : '';
    return name.isEmpty ? l10n.importColumnUnnamed(column + 1) : name;
  }

  void _setColumn(ImportRole role, int? column) {
    final Map<ImportRole, int> columns = {..._draft.columns}..remove(role);
    if (column != null) columns[role] = column;
    widget.onChanged(_draft.copyWith(columns: columns));
  }

  Future<void> _pickCurrency() async {
    final String? code = await showCurrencyPicker(
      context,
      selected: _draft.newCurrency,
    );
    if (code != null && mounted) {
      widget.onChanged(_draft.copyWith(newCurrency: code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    const SizedBox gap = SizedBox(height: 16);
    final int width = _header.length;
    final bool ready =
        _draft.mapping != null &&
        (_draft.newAccount
            ? _draft.newName.trim().isNotEmpty
            : widget.accounts.any((a) => a.id == _draft.accountId));
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_draft.presetApplied)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.importPresetApplied),
          ),
        SettingsSectionHeader(l10n.importFileSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                elevation: 0,
                key: ValueKey('header-${_draft.headerRow}'),
                initialValue: _draft.headerRow,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.importHeaderRow,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (
                    int i = 0;
                    i < widget.table.rows.length - 1 &&
                        (i < headerRowChoices || i <= _draft.headerRow);
                    i++
                  )
                    DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        l10n.importHeaderRowOption(
                          i + 1,
                          widget.table.rows[i]
                              .where((f) => f.trim().isNotEmpty)
                              .take(3)
                              .join(widget.table.delimiter),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: widget.busy
                    ? null
                    : (i) {
                        if (i != null) widget.onHeaderRow(i);
                      },
              ),
              gap,
              DropdownButtonFormField<String>(
                elevation: 0,
                key: ValueKey('delimiter-${widget.table.delimiter}'),
                initialValue: widget.table.delimiter,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.importDelimiter,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final String d in csvDelimiters)
                    DropdownMenuItem<String>(
                      value: d,
                      child: Text(_delimiterLabel(l10n, d)),
                    ),
                ],
                onChanged: widget.busy
                    ? null
                    : (d) {
                        if (d != null) widget.onDelimiter(d);
                      },
              ),
            ],
          ),
        ),
        SettingsSectionHeader(l10n.importMappingSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.importAmountMode, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.importAmountOneColumn),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.importAmountDebitCredit),
                  ),
                ],
                selected: {_draft.debitCredit},
                onSelectionChanged: (s) =>
                    widget.onChanged(_draft.copyWith(debitCredit: s.single)),
              ),
              for (final ImportRole role in _rolesFor(_draft.debitCredit)) ...[
                gap,
                DropdownButtonFormField<int?>(
                  elevation: 0,
                  key: ValueKey(
                    'role-${role.name}-${_draft.headerRow}-'
                    '${_draft.columns[role]}',
                  ),
                  initialValue: _draft.columns[role],
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _roleLabel(l10n, role),
                    helperText: _required(role) ? l10n.importRequired : null,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    if (!_required(role))
                      DropdownMenuItem<int?>(
                        child: Text(l10n.importColumnNone),
                      ),
                    for (int c = 0; c < width; c++)
                      DropdownMenuItem<int?>(
                        value: c,
                        child: Text(switch (_sample(c)) {
                          final String sample => l10n.importColumnOption(
                            _columnName(l10n, c),
                            sample,
                          ),
                          null => _columnName(l10n, c),
                        }, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (c) => _setColumn(role, c),
                ),
              ],
              if (_rolesFor(
                _draft.debitCredit,
              ).any((r) => _required(r) && !_draft.columns.containsKey(r))) ...[
                gap,
                Text(l10n.importMappingIncomplete),
              ],
              gap,
              _DateFormatChoice(
                draft: _draft,
                samples: [
                  for (final List<String> row in widget.table.rows.skip(
                    _draft.headerRow + 1,
                  ))
                    if (_draft.columns[ImportRole.date] case final int c
                        when c < row.length && row[c].trim().isNotEmpty)
                      row[c].trim(),
                ].take(3).toList(),
                onChanged: (f) =>
                    widget.onChanged(_draft.copyWith(dateFormat: f)),
              ),
              gap,
              Text(
                l10n.importDecimalSeparator,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<DecimalSeparator>(
                segments: [
                  ButtonSegment(
                    value: DecimalSeparator.point,
                    label: Text(l10n.importDecimalPoint),
                  ),
                  ButtonSegment(
                    value: DecimalSeparator.comma,
                    label: Text(l10n.importDecimalComma),
                  ),
                ],
                selected: {_draft.separator},
                onSelectionChanged: (s) => widget.onChanged(
                  _draft.copyWith(separator: s.single, separatorDetected: true),
                ),
              ),
              if (!_draft.separatorDetected) ...[
                const SizedBox(height: 8),
                Text(l10n.importSeparatorUnsure),
              ],
            ],
          ),
        ),
        if (!_draft.debitCredit)
          SwitchListTile(
            title: Text(l10n.importOutflowsNegative),
            subtitle: Text(l10n.importOutflowsNegativeSubtitle),
            value: _draft.outflowsNegative,
            onChanged: (v) =>
                widget.onChanged(_draft.copyWith(outflowsNegative: v)),
          ),
        SettingsSectionHeader(l10n.importAccountSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                elevation: 0,
                key: ValueKey(
                  'account-${_draft.newAccount}-${_draft.accountId}',
                ),
                initialValue: _draft.newAccount ? '' : _draft.accountId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.importAccount,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final Account a in widget.accounts)
                    DropdownMenuItem<String?>(
                      value: a.id,
                      child: Text(a.name, overflow: TextOverflow.ellipsis),
                    ),
                  DropdownMenuItem<String?>(
                    value: '',
                    child: Text(l10n.importNewAccount),
                  ),
                ],
                onChanged: (id) => widget.onChanged(
                  id == ''
                      ? _draft.copyWith(newAccount: true, accountId: null)
                      : _draft.copyWith(newAccount: false, accountId: id),
                ),
              ),
              if (_draft.newAccount) ...[
                gap,
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.accountName,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      widget.onChanged(_draft.copyWith(newName: v)),
                ),
                gap,
                Text(l10n.accountType, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final AccountType type in AccountType.values)
                      ChoiceChip(
                        avatar: Icon(accountTypeIcon(type)),
                        showCheckmark: false,
                        label: Text(accountTypeLabel(l10n, type)),
                        selected: type == _draft.newType,
                        onSelected: (_) =>
                            widget.onChanged(_draft.copyWith(newType: type)),
                      ),
                  ],
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.accountCurrency),
                  subtitle: Text(
                    l10n.currencyValue(
                      _draft.newCurrency,
                      currencySymbol(_draft.newCurrency),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickCurrency,
                ),
              ],
              if (widget.error case final String message) ...[
                gap,
                Text(message, style: TextStyle(color: theme.colorScheme.error)),
              ],
              gap,
              FilledButton(
                onPressed: ready && !widget.busy ? widget.onReview : null,
                child: Text(l10n.importReview),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The date format: the readings of ambiguous dates side by side, else a choice of every
/// format, saying so when none reads the column.
class _DateFormatChoice extends StatelessWidget {
  const _DateFormatChoice({
    required this.draft,
    required this.samples,
    required this.onChanged,
  });

  final MappingDraft draft;

  /// The file's first dates as written.
  final List<String> samples;
  final ValueChanged<ImportDateFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (draft.dateCandidates.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.importDateFormat,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(l10n.importDateAmbiguous),
          RadioGroup<ImportDateFormat>(
            groupValue: draft.dateFormat,
            onChanged: (f) {
              if (f != null) onChanged(f);
            },
            child: Column(
              children: [
                for (final ImportDateFormat f in draft.dateCandidates)
                  RadioListTile<ImportDateFormat>(
                    contentPadding: EdgeInsets.zero,
                    value: f,
                    title: Text(f.pattern),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final String s in samples)
                          if (f.parse(s) case final LocalDate d)
                            Text(l10n.importDateSample(s, shortDateLabel(d))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ImportDateFormat>(
          elevation: 0,
          key: ValueKey('date-${draft.dateFormat}'),
          initialValue: draft.dateFormat,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.importDateFormat,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final ImportDateFormat f in ImportDateFormat.values)
              DropdownMenuItem<ImportDateFormat>(
                value: f,
                child: Text(f.pattern),
              ),
          ],
          onChanged: (f) {
            if (f != null) onChanged(f);
          },
        ),
        if (draft.columns.containsKey(ImportRole.date) &&
            draft.dateCandidates.isEmpty) ...[
          const SizedBox(height: 8),
          Text(l10n.importDateNone),
        ],
      ],
    );
  }
}
