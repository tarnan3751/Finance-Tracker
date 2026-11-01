// The privacy page and PRIVACY.md at the repository's root say the same: the file's
// title, headings, paragraphs and bullets, in order, are the ARB's privacy messages; and
// the page's body lays out every one of those messages, in that order, as the same kind
// of block (heading, paragraph or bullet) as the file, so a message the body drops or
// moves fails here.
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/features/help/presentation/help_widgets.dart';
import 'package:finance_tracker/features/help/presentation/privacy_content.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A block of the page: its kind and its text.
typedef _Block = ({String kind, String text});

// PRIVACY.md as blocks, its title apart (flutter test runs in app/).
({String title, List<_Block> body}) _file() {
  String title = '';
  final List<_Block> body = [];
  for (final String line in File('../PRIVACY.md').readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    if (line.startsWith('# ')) {
      title = line.substring(2);
    } else if (line.startsWith('## ')) {
      body.add((kind: 'heading', text: line.substring(3)));
    } else if (line.startsWith('- ')) {
      body.add((kind: 'bullet', text: line.substring(2)));
    } else {
      body.add((kind: 'paragraph', text: line));
    }
  }
  return (title: title, body: body);
}

void main() {
  test('PRIVACY.md and the privacy messages carry the same paragraphs', () {
    final Map<String, dynamic> arb = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final List<String> messages = [
      for (final MapEntry(:key, :value) in arb.entries)
        if (RegExp(r'^privacy\d+$').hasMatch(key)) value as String,
    ];
    final file = _file();
    expect(file.title, arb['privacyTitle']);
    expect([for (final _Block b in file.body) b.text], messages);
    expect(messages.length, greaterThan(10));
  });

  test('the page lays out every message in order, as the file does', () {
    final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));
    final List<_Block> page = [
      for (final Widget w in privacyBody(l10n))
        ...switch (w) {
          HelpHeading(:final String text) => [(kind: 'heading', text: text)],
          HelpParagraph(:final String text) => [
            (kind: 'paragraph', text: text),
          ],
          HelpBullets(:final List<String> items) => [
            for (final String item in items) (kind: 'bullet', text: item),
          ],
          _ => throw StateError('$w'),
        },
    ];
    expect(l10n.privacyTitle, _file().title);
    expect(page, _file().body);
  });
}
