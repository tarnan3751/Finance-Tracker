/// A full-screen, searchable list of the ISO 4217 currencies `Money` knows
/// (`Currency.minorUnitDigits`), each shown with its code and symbol.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// Shows the picker with [selected] marked; completes with the chosen code, or null when
/// the user backs out.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => _CurrencyPicker(selected: selected),
  ),
);

/// The symbol intl prints for [code] in the device locale (the code itself when intl has
/// no symbol for it).
String currencySymbol(String code) =>
    NumberFormat.simpleCurrency(name: code).currencySymbol;

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({required this.selected});

  final String selected;

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  static final List<String> _codes = Currency.minorUnitDigits.keys.toList()
    ..sort();

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String query = _query.trim().toUpperCase();
    final List<String> codes = query.isEmpty
        ? _codes
        : [
            for (final String code in _codes)
              if (code.contains(query) ||
                  currencySymbol(code).toUpperCase().contains(query))
                code,
          ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.currencyPickerTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.currencyPickerSearch,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: codes.length,
              itemBuilder: (context, index) {
                final String code = codes[index];
                final bool selected = code == widget.selected;
                return ListTile(
                  title: Text(code),
                  subtitle: Text(currencySymbol(code)),
                  selected: selected,
                  trailing: selected ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(code),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
