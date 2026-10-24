/// The Finance Tracker sync engine: user-authored data synced between devices through the
/// change log (`PLAN.md` §6.4). A hybrid logical clock stamps every local change; changes
/// merge last-writer-wins per field, with tombstones that win over concurrent edits.
///
/// Pure Dart; no Flutter, no IO. How to use it: `docs/reference/sync.md`.
library;

export 'src/hlc_clock.dart';
