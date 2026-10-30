/// The backup passphrase's rule and its strength hint (`docs/reference/backup.md`, **The
/// key**). A passphrase is used exactly as typed (its UTF-8 bytes, no Unicode
/// normalization or trimming) and is at least [minPassphraseLength] characters (Unicode
/// code points). The hint is a heuristic from the length and the kinds of character; it
/// is advice, not a gate. There is no recovery: a forgotten passphrase loses the backup.
/// Pure Dart, no Flutter import.
library;

/// The fewest characters a backup passphrase may have.
const int minPassphraseLength = 12;

/// How strong a passphrase looks.
enum PassphraseStrength {
  /// Under [minPassphraseLength] characters: not accepted.
  tooShort,

  /// Long enough, little variety.
  weak,

  /// Longer, or of three kinds of character.
  fair,

  /// 20 characters or more, or 16 of three kinds.
  strong,
}

/// The strength of [passphrase].
PassphraseStrength passphraseStrength(String passphrase) {
  final int length = passphrase.runes.length;
  if (length < minPassphraseLength) return PassphraseStrength.tooShort;
  int kinds = 0;
  if (passphrase.contains(RegExp('[a-z]'))) kinds++;
  if (passphrase.contains(RegExp('[A-Z]'))) kinds++;
  if (passphrase.contains(RegExp('[0-9]'))) kinds++;
  if (passphrase.contains(RegExp('[^a-zA-Z0-9]'))) kinds++;
  if (length >= 20 || (length >= 16 && kinds >= 3)) {
    return PassphraseStrength.strong;
  }
  if (length >= 14 || kinds >= 3) return PassphraseStrength.fair;
  return PassphraseStrength.weak;
}
