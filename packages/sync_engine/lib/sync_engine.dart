/// The Finance Tracker sync engine: user-authored data synced between devices through the
/// change log (`PLAN.md` §6.4). A hybrid logical clock stamps every local change; changes
/// merge last-writer-wins per field, with tombstones that win over concurrent edits.
///
/// Pure Dart; no Flutter, no IO. How to use it: `docs/reference/sync.md`.
library;

export 'src/diff.dart';
export 'src/entity_record.dart' show EntityKey, EntityRecord;
export 'src/hlc_clock.dart';
export 'src/in_memory_sync_relay.dart';
export 'src/in_memory_sync_store.dart';
export 'src/local_editor.dart';
export 'src/merge.dart';
export 'src/sync_relay.dart';
export 'src/sync_session.dart';
export 'src/sync_store.dart';
