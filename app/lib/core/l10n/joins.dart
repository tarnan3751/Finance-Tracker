/// Lists of strings shown on one line, joined through the ARB's templates rather than
/// with a separator in code, so a translation chooses its own punctuation and order:
/// [captionLine] with `captionPair` ("{first} · {second}"), [listLine] with `listPair`
/// ("{first}, {second}"), [sentenceLine] with `sentencePair` ("{first} {second}"). Each
/// folds from the start, the first piece being the line so far.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';

/// [parts] as one caption line, `a · b · c` in English; empty for none.
String captionLine(AppLocalizations l10n, Iterable<String> parts) =>
    parts.isEmpty ? '' : parts.reduce(l10n.captionPair);

/// [parts] as one list, `a, b, c` in English; empty for none.
String listLine(AppLocalizations l10n, Iterable<String> parts) =>
    parts.isEmpty ? '' : parts.reduce(l10n.listPair);

/// [parts], sentences, as one paragraph, `A. B. C.` in English; empty for none.
String sentenceLine(AppLocalizations l10n, Iterable<String> parts) =>
    parts.isEmpty ? '' : parts.reduce(l10n.sentencePair);
