// The strings check the gate runs (tools/gates.sh, `strings`): every user-facing string
// is in the ARB, and the ARBs agree with the template.
//
//   dart run tools/check_strings.dart
//
// 1. Literals. Every string literal in the app's presentation code (`presentation/` of
//    each feature, and `core/router/`, `core/layout/`, `core/widgets/`, `core/l10n/`)
//    that reads as prose (two letters or more, and a space or a capital letter at its
//    start) is an error, unless it is in an import, a comment, an interpolation-only string, a key or
//    an identifier (`Key(…)`, `ValueKey(…)`, `debugLabel:`, `restorationId:`), a log or
//    an assertion message, or listed in tools/check_strings_allowlist.txt as
//    `path|literal` (a deliberate exception, with a comment line above saying why; the
//    literal JSON-quoted when it is or ends in a space).
//    So is a literal that joins pieces in code: a `.join(' · ')`, `.join(', ')` or
//    `.join(' ')` separator, or an interpolation whose pieces are separated only by ` · `, `, ` or
//    spaces (`'$name ${amount}'`); the ARB's `captionPair`, `listPair`,
//    `sentencePair` or a message of its own does that (`core/l10n/joins.dart`), and a
//    join that is not text for a reader (words of an identifier) goes on the
//    allowlist. A string built with `+` gets past it;
//    review does the rest.
// 2. The template. Every key of app/lib/l10n/app_en.arb has an `@key` entry with a
//    description, and every placeholder a message uses is declared with a type.
// 3. The other locales. A key in another ARB that is not in the template is an error,
//    and so is a translated message whose placeholders differ from the template's; the
//    keys each locale leaves untranslated (it shows them in English) are counted and
//    printed, never an error. The pseudo-locale, app_en_XA.arb, must be exactly what
//    tools/pseudo_locale.dart makes of the template; a missing, extra or stale key is
//    an error naming `dart run tools/pseudo_locale.dart` as the fix.
//
// Exits 1 with a line per problem, else 0 with the counts.
import 'dart:convert';
import 'dart:io';

import 'pseudo_locale.dart' as pseudo;

const String _arbDir = 'app/lib/l10n';
const String _template = '$_arbDir/app_en.arb';
const String _allowlist = 'tools/check_strings_allowlist.txt';

void main() {
  if (!File(_template).existsSync()) {
    stderr.writeln('Run from the repository root: $_template not found.');
    exit(2);
  }
  final List<String> problems = [
    ...checkLiterals(),
    ...checkTemplate(),
    ...checkLocales(),
  ];
  for (final String problem in problems) {
    stdout.writeln(problem);
  }
  exit(problems.isEmpty ? 0 : 1);
}

// ---------------------------------------------------------------------------------------
// 1. Literals

/// The directories whose Dart files hold user-facing strings.
List<Directory> _presentationDirs() => [
  for (final FileSystemEntity e in Directory('app/lib/features').listSync())
    if (e is Directory && Directory('${e.path}/presentation').existsSync())
      Directory('${e.path}/presentation'),
  for (final String d in ['router', 'layout', 'widgets', 'l10n'])
    if (Directory('app/lib/core/$d').existsSync()) Directory('app/lib/core/$d'),
];

Set<String> _allowed() {
  final File file = File(_allowlist);
  if (!file.existsSync()) return {};
  return {
    for (final String line in file.readAsLinesSync())
      if (line.trim().isNotEmpty && !line.startsWith('#')) _entry(line.trim()),
  };
}

/// An allowlist line as `path|literal`: the literal as written, or JSON-quoted
/// (`path|" "`) when it is or ends in a space, which a plain line would lose.
String _entry(String line) {
  final int bar = line.indexOf('|');
  final String literal = line.substring(bar + 1);
  if (bar < 0 || !literal.startsWith('"')) return line;
  return '${line.substring(0, bar)}|${jsonDecode(literal) as String}';
}

/// The prose literals outside the ARB and the allowlist, one line each.
List<String> checkLiterals() {
  final Set<String> allowed = _allowed();
  final Set<String> used = {};
  final List<String> problems = [];
  for (final Directory dir in _presentationDirs()) {
    final List<File> files = [
      for (final FileSystemEntity e in dir.listSync(recursive: true))
        if (e is File &&
            e.path.endsWith('.dart') &&
            !e.path.endsWith('.g.dart') &&
            !e.path.endsWith('.freezed.dart'))
          e,
    ]..sort((a, b) => a.path.compareTo(b.path));
    for (final File file in files) {
      for (final ({int line, String text, String context}) literal
          in stringLiterals(file.readAsStringSync())) {
        final bool join =
            _isJoin(literal.text, literal.context) &&
            !_isExempt(literal.context);
        if (!join && (!_isProse(literal.text) || _isExempt(literal.context))) {
          continue;
        }
        final String entry = '${file.path}|${literal.text}';
        if (allowed.contains(entry)) {
          used.add(entry);
          continue;
        }
        if (join) {
          problems.add(
            'strings: ${file.path}:${literal.line}: "${literal.text}" joins '
            'pieces in code (use captionLine, listLine, sentenceLine or a '
            'message with placeholders)',
          );
          continue;
        }
        problems.add(
          'strings: ${file.path}:${literal.line}: "${literal.text}" is not in '
          'the ARB (add it to app_en.arb, or to $_allowlist with the reason)',
        );
      }
    }
  }
  for (final String stale in allowed.difference(used)) {
    problems.add(
      'strings: $_allowlist: "$stale" matches no literal; remove it',
    );
  }
  return problems;
}

/// Whether [text], with the code [before] it on its line, joins pieces of text in code:
/// a list separator passed to `join`, or interpolations separated only by a separator
/// or spaces.
bool _isJoin(String text, String before) {
  if (RegExp(r'\.join\(\s*$').hasMatch(before)) {
    return const {' · ', ', ', ' ·', '·', ' '}.contains(text);
  }
  final Iterable<RegExpMatch> pieces = RegExp(r'\$\{[^}]*\}|\$\w+')
      .allMatches(text);
  if (pieces.length < 2) return false;
  final String rest = text.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
  return RegExp(r'^[\s·,]*$').hasMatch(rest) &&
      (rest.contains('·') || rest.contains(',') || rest.trim().isEmpty);
}

/// Whether [text] reads as prose a user would see.
bool _isProse(String text) {
  final String bare = text.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
  if (RegExp(r'[A-Za-z]').allMatches(bare).length < 2) return false;
  return bare.contains(' ') || RegExp(r'^[A-Z][a-z]').hasMatch(bare);
}

/// Whether the code before a literal on its line makes it a key, an identifier, a log
/// or an assertion message.
bool _isExempt(String before) => RegExp(
  r'(Key|ValueKey|ObjectKey|PageStorageKey|GlobalKey<[^>]*>|debugLabel:|'
  r'restorationId:|Logger|_log\.\w+|log\.\w+|assert|Error|Exception|'
  r'debugPrint|semanticsIdentifier:|identifier:)\s*\(?\s*$',
).hasMatch(before);

/// The string literals in [source] with their line and the code before them on it:
/// comments and directives skipped, adjacent pieces kept apart.
Iterable<({int line, String text, String context})> stringLiterals(
  String source,
) sync* {
  int i = 0;
  int line = 1;
  int lineStart = 0;
  while (i < source.length) {
    final String c = source[i];
    if (c == '\n') {
      line++;
      lineStart = i + 1;
      i++;
    } else if (source.startsWith('//', i)) {
      final int end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
    } else if (source.startsWith('/*', i)) {
      final int end = source.indexOf('*/', i + 2);
      final int stop = end < 0 ? source.length : end + 2;
      line += '\n'.allMatches(source.substring(i, stop)).length;
      i = stop;
    } else if (c == '"' || c == "'") {
      final bool raw = i > 0 && source[i - 1] == 'r';
      final bool triple = source.startsWith(c * 3, i);
      final String quote = triple ? c * 3 : c;
      final int start = i + quote.length;
      int j = start;
      while (j < source.length && !source.startsWith(quote, j)) {
        if (!raw && source[j] == r'\') j++;
        if (source[j] == r'$' &&
            j + 1 < source.length &&
            source[j + 1] == '{') {
          j = _skipInterpolation(source, j + 1);
          continue;
        }
        j++;
      }
      final String lineText = source.substring(lineStart, i);
      final String text = source.substring(start, j);
      final bool directive = RegExp(r'^\s*(import|export|part|library)\b')
          .hasMatch(lineText);
      if (!directive) {
        yield (line: line, text: text, context: lineText);
      }
      line += '\n'.allMatches(text).length;
      i = j + quote.length;
    } else {
      i++;
    }
  }
}

int _skipInterpolation(String source, int open) {
  int depth = 0;
  for (int i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return i + 1;
  }
  return source.length;
}

// ---------------------------------------------------------------------------------------
// 2. The template

Map<String, Object?> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

/// The placeholder names [message] uses: `{name}` and the argument of each plural and
/// select, in the cases too.
Set<String> placeholdersOf(String message) {
  final Set<String> names = {};
  void scan(String text) {
    int i = 0;
    while (i < text.length) {
      if (text[i] != '{') {
        i++;
        continue;
      }
      int depth = 0;
      int end = i;
      for (; end < text.length; end++) {
        if (text[end] == '{') depth++;
        if (text[end] == '}' && --depth == 0) break;
      }
      final String inner = text.substring(i + 1, end);
      final int comma = inner.indexOf(',');
      if (comma < 0) {
        names.add(inner.trim());
      } else {
        names.add(inner.substring(0, comma).trim());
        final int second = inner.indexOf(',', comma + 1);
        String cases = inner.substring(second + 1);
        int open;
        while ((open = cases.indexOf('{')) >= 0) {
          int d = 0;
          int close = open;
          for (; close < cases.length; close++) {
            if (cases[close] == '{') d++;
            if (cases[close] == '}' && --d == 0) break;
          }
          scan(cases.substring(open + 1, close));
          cases = cases.substring(close + 1);
        }
      }
      i = end + 1;
    }
  }

  scan(message);
  return names;
}

/// The template's missing descriptions and untyped or undeclared placeholders.
List<String> checkTemplate() {
  final Map<String, Object?> arb = _read(_template);
  final List<String> problems = [];
  for (final MapEntry(:key, :value) in arb.entries) {
    if (key.startsWith('@')) continue;
    final Object? meta = arb['@$key'];
    if (meta is! Map<String, Object?> ||
        (meta['description'] as String?)?.trim().isEmpty != false) {
      problems.add('strings: $_template: "$key" has no @$key description');
      continue;
    }
    final Map<String, Object?> declared =
        (meta['placeholders'] as Map<String, Object?>?) ?? const {};
    for (final String name in placeholdersOf(value! as String)) {
      final Object? placeholder = declared[name];
      if (placeholder is! Map<String, Object?> || placeholder['type'] == null) {
        problems.add(
          'strings: $_template: "$key" uses {$name} without a typed placeholder',
        );
      }
    }
  }
  return problems;
}

// ---------------------------------------------------------------------------------------
// 3. The other locales

/// Keys the other locales have that the template has not, placeholders that differ, the
/// pseudo-locale out of step with the template, and (printed, never failing) the
/// untranslated counts.
List<String> checkLocales() {
  final Map<String, Object?> template = _read(_template);
  final Map<String, String> messages = {
    for (final MapEntry(:key, :value) in template.entries)
      if (!key.startsWith('@')) key: value! as String,
  };
  final List<String> problems = [];
  final List<File> others = [
    for (final FileSystemEntity e in Directory(_arbDir).listSync())
      if (e is File && e.path.endsWith('.arb') && e.path != _template) e,
  ]..sort((a, b) => a.path.compareTo(b.path));
  for (final File file in others) {
    if (file.path == pseudo.pseudoPath) {
      problems.addAll(_checkPseudo());
      continue;
    }
    final Map<String, Object?> arb = _read(file.path);
    int translated = 0;
    for (final MapEntry(:key, :value) in arb.entries) {
      if (key.startsWith('@')) continue;
      final String? english = messages[key];
      if (english == null) {
        problems.add('strings: ${file.path}: "$key" is not in $_template');
        continue;
      }
      translated++;
      final Set<String> want = placeholdersOf(english);
      final Set<String> got = placeholdersOf(value! as String);
      if (want.length != got.length || !want.containsAll(got)) {
        problems.add(
          'strings: ${file.path}: "$key" has placeholders $got, the template '
          '$want',
        );
      }
    }
    stdout.writeln(
      'strings: ${file.path}: ${messages.length - translated} of '
      '${messages.length} keys untranslated (shown in English)',
    );
  }
  return problems;
}

/// The pseudo-locale's keys that are missing, extra or not what the template makes.
List<String> _checkPseudo() {
  final Map<String, Object?> want = jsonDecode(
    pseudo.pseudoArb(File(_template).readAsStringSync()),
  ) as Map<String, Object?>;
  final Map<String, Object?> got = _read(pseudo.pseudoPath);
  final int missing = want.keys.where((k) => !got.containsKey(k)).length;
  final int extra = got.keys.where((k) => !want.containsKey(k)).length;
  final int stale = want.keys
      .where((k) => got.containsKey(k) && got[k] != want[k])
      .length;
  if (missing + extra + stale == 0) {
    stdout.writeln('strings: ${pseudo.pseudoPath}: current with the template');
    return const [];
  }
  return [
    'strings: ${pseudo.pseudoPath}: $missing missing, $extra extra and $stale '
        'stale keys against the template; run dart run tools/pseudo_locale.dart, '
        'then flutter gen-l10n in app/',
  ];
}
