/// Where a file's table starts (`docs/reference/import.md`, **The mapping**). Pure Dart.
///
/// Bank exports often open with a preamble (an account summary, a title, a blank line),
/// so the header is the first row with at least three non-empty fields that is followed
/// by a row of the same width, or wider only by blank fields (Chase ends every record but
/// the header with a comma). The mapping screen lets the user pick another row.
library;

/// The index of the header row of [rows], or null when no row is one.
int? findHeaderRow(List<List<String>> rows) {
  for (int i = 0; i + 1 < rows.length; i++) {
    final List<String> row = rows[i];
    final int filled = row.where((f) => f.trim().isNotEmpty).length;
    if (filled >= 3 && _sameWidth(row, rows[i + 1])) return i;
  }
  return null;
}

bool _sameWidth(List<String> header, List<String> next) =>
    next.length >= header.length &&
    next.skip(header.length).every((f) => f.trim().isEmpty);
