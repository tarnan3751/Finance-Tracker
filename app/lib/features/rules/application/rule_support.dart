/// The owned-field guard every application of the rules shares
/// (`docs/reference/rules.md`, **The guard**): on arrival (`rule_runner.dart`) and on the
/// existing transactions (`rule_preview.dart`).
library;

import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// The override fields of [transaction] a sync clock already covers, on a `plaid` row:
/// set by a person, or by a rule on another device, so the rules leave them alone. Read
/// through [store], the sync store the recorder writes to (null where nothing syncs, which
/// owns nothing); empty for any other source.
Future<Set<String>> ruleOwnedFields(
  SyncStore? store,
  Transaction transaction,
) async {
  if (store == null || transaction.source != DataSource.plaid) return const {};
  final EntityRecord? record = await store.read(
    EntityType.transaction,
    transaction.id,
  );
  if (record == null) return const {};
  return {
    for (final String f in const [
      ruleCategoryField,
      ruleTagsField,
      ruleHiddenField,
    ])
      if (record.fieldClocks.containsKey(f)) f,
  };
}
