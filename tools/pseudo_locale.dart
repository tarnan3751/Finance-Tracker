// Writes the pseudo-locale, app/lib/l10n/app_en_XA.arb, from the English template
// app/lib/l10n/app_en.arb: every message accented, lengthened by 40 percent and wrapped in
// brackets, so a screen shown in it (Settings → Appearance → Language → Pseudo, in the
// dev and demo flavors) shows where a translation would be cut off, overflow or be
// concatenated from pieces. Placeholders and the plural and select syntax are kept as
// they are; only the text between them changes. `en_XA` is Android's own pseudo-locale
// name; gen-l10n accepts no made-up language code such as `xx`.
//
//   dart run tools/pseudo_locale.dart
//
// Run it after changing app_en.arb, then `flutter gen-l10n` in app/ (the gate's codegen
// step regenerates the Dart and checks it is current); tools/check_strings.dart, run by
// the gate, prints how many keys the pseudo-locale is behind.
import 'dart:convert';
import 'dart:io';

/// Where the template is, from the repository root.
const String templatePath = 'app/lib/l10n/app_en.arb';

/// Where the pseudo-locale goes, from the repository root.
const String pseudoPath = 'app/lib/l10n/app_en_XA.arb';

void main() {
  final File template = File(templatePath);
  if (!template.existsSync()) {
    stderr.writeln('Run from the repository root: $templatePath not found.');
    exit(2);
  }
  File(pseudoPath).writeAsStringSync(pseudoArb(template.readAsStringSync()));
  stdout.writeln('wrote $pseudoPath');
}

/// The pseudo-locale ARB of the English template [arb].
String pseudoArb(String arb) {
  final Map<String, Object?> source = jsonDecode(arb) as Map<String, Object?>;
  final Map<String, Object?> out = {'@@locale': 'en_XA'};
  for (final MapEntry(:key, :value) in source.entries) {
    if (key.startsWith('@')) continue;
    out[key] = pseudoMessage(value! as String);
  }
  return '${const JsonEncoder.withIndent('  ').convert(out)}\n';
}

/// [message] accented, lengthened and bracketed, its ICU syntax intact.
String pseudoMessage(String message) => '[${_transform(message)}]';

const Map<String, String> _accents = {
  'a': 'å', 'b': 'ƀ', 'c': 'ç', 'd': 'ð', 'e': 'é', 'f': 'ƒ', 'g': 'ĝ', //
  'h': 'ĥ', 'i': 'î', 'j': 'ĵ', 'k': 'ķ', 'l': 'ļ', 'm': 'ɱ', 'n': 'ñ', //
  'o': 'ö', 'p': 'þ', 'q': 'ǫ', 'r': 'ŕ', 's': 'š', 't': 'ţ', 'u': 'û', //
  'v': 'ṽ', 'w': 'ŵ', 'x': 'ẋ', 'y': 'ý', 'z': 'ž', 'A': 'Å', 'B': 'Ɓ', //
  'C': 'Ç', 'D': 'Ð', 'E': 'É', 'F': 'Ƒ', 'G': 'Ĝ', 'H': 'Ĥ', 'I': 'Î', //
  'J': 'Ĵ', 'K': 'Ķ', 'L': 'Ļ', 'M': 'Ṁ', 'N': 'Ñ', 'O': 'Ö', 'P': 'Þ', //
  'Q': 'Ǫ', 'R': 'Ŕ', 'S': 'Š', 'T': 'Ţ', 'U': 'Û', 'V': 'Ṽ', 'W': 'Ŵ', //
  'X': 'Ẋ', 'Y': 'Ý', 'Z': 'Ž',
};

/// [message] with its literal text accented and padded: a placeholder `{name}` is kept,
/// and each case of a `{name, plural, …}` or `{name, select, …}` is transformed in turn.
String _transform(String message) {
  final StringBuffer out = StringBuffer();
  int letters = 0;
  int i = 0;
  while (i < message.length) {
    final String c = message[i];
    if (c != '{') {
      out.write(_accents[c] ?? c);
      if (_accents.containsKey(c)) letters++;
      i++;
      continue;
    }
    final int end = _closing(message, i);
    final String inner = message.substring(i + 1, end);
    final int comma = inner.indexOf(',');
    if (comma < 0) {
      out.write('{$inner}');
    } else {
      out.write('{${_transformCases(inner)}}');
    }
    i = end + 1;
  }
  return '$out${_padding(letters)}';
}

/// `name, plural, =1{…} other{…}` with each case's message transformed.
String _transformCases(String argument) {
  final int first = argument.indexOf(',');
  final int second = argument.indexOf(',', first + 1);
  final StringBuffer out = StringBuffer(argument.substring(0, second + 1));
  int i = second + 1;
  while (i < argument.length) {
    final int open = argument.indexOf('{', i);
    if (open < 0) {
      out.write(argument.substring(i));
      break;
    }
    out.write(argument.substring(i, open));
    final int end = _closing(argument, open);
    out.write('{${_transform(argument.substring(open + 1, end))}}');
    i = end + 1;
  }
  return out.toString();
}

/// The index of the brace that closes the one at [open].
int _closing(String text, int open) {
  int depth = 0;
  for (int i = open; i < text.length; i++) {
    if (text[i] == '{') depth++;
    if (text[i] == '}' && --depth == 0) return i;
  }
  throw FormatException('Unbalanced braces', text, open);
}

/// Forty percent of [letters] in tildes, in groups of five a space apart so the padded
/// text still wraps.
String _padding(int letters) {
  final int count = (letters * 0.4).ceil();
  if (count == 0) return '';
  final StringBuffer out = StringBuffer(' ');
  for (int i = 0; i < count; i++) {
    if (i > 0 && i % 5 == 0) out.write(' ');
    out.write('~');
  }
  return out.toString();
}
