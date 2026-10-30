// The one-line joins through the ARB's templates: a caption line and a list, folded
// from the start, empty for none, in English and in the pseudo-locale.
import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  test('a caption line and a list join through their templates', () {
    expect(
      captionLine(en, ['Oct 30', 'Rent', r'$1,500.00']),
      r'Oct 30 · Rent · $1,500.00',
    );
    expect(
      listLine(en, ['Checking', 'Savings', 'Card']),
      'Checking, Savings, Card',
    );
    expect(listLine(en, ['Checking']), 'Checking');
    expect(captionLine(en, const []), '');
  });

  test('the pseudo-locale wraps each join, so a joined line shows as one', () {
    final AppLocalizations xa = lookupAppLocalizations(
      const Locale('en', 'XA'),
    );
    expect(listLine(xa, ['a', 'b']), '[a, b]');
  });
}
