// The import's fixtures: bank exports in the shapes of Chase, Bank of America (with its
// summary preamble), Monzo and a European bank, a UTF-16 and a Windows-1252 file, and the
// app's own export; every name in them is fictional.
import 'dart:io';
import 'dart:typed_data';

/// The bytes of fixture [name] (`test/features/import/fixtures/<name>`).
Uint8List importFixture(String name) =>
    File('test/features/import/fixtures/$name').readAsBytesSync();
