/// The anomaly flags the screens show (`docs/reference/reports.md`, **Anomalies**) and
/// the ones dismissed on this device.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/rules/application/rules_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'anomaly_providers.g.dart';

/// The ids of the transactions whose flags were dismissed, kept in `app_meta` on this
/// device and never synced. Kept alive, so an Undo pressed after its screen has gone
/// still finds it.
@Riverpod(keepAlive: true)
class DismissedAnomalies extends _$DismissedAnomalies {
  @override
  Future<Set<String>> build() async {
    final String? stored = await ref
        .watch(appMetaStoreProvider)
        .read(AppMetaKeys.dismissedAnomalies);
    return stored == null
        ? const {}
        : {...(jsonDecode(stored) as List<dynamic>).cast<String>()};
  }

  /// Stops flagging transaction [id] on this device.
  Future<void> dismiss(String id) async => _write({...await future, id});

  /// Flags transaction [id] again (the Undo of [dismiss]).
  Future<void> restore(String id) async =>
      _write({...await future}..remove(id));

  Future<void> _write(Set<String> next) async {
    state = AsyncData(next);
    await ref
        .read(appMetaStoreProvider)
        .write(
          AppMetaKeys.dismissedAnomalies,
          jsonEncode(next.toList()..sort()),
        );
  }
}

/// The flags on the live, visible transactions dated in [window], less the dismissed
/// ones: judged on every live transaction, with the merged recurring streams' members as
/// the scheduled payments and the live rules.
@riverpod
Future<List<AnomalyFlag>> anomalies(Ref ref, LocalDateRange window) async {
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<StreamView> streams = await ref.watch(
    mergedStreamsProvider.future,
  );
  final List<Rule> rules = await ref.watch(rulesProvider.future);
  final Set<String> dismissed = await ref.watch(
    dismissedAnomaliesProvider.future,
  );
  final CategoryLookup lookup = categoryLookup(categories);
  return [
    for (final AnomalyFlag f in detectAnomalies(
      ledger,
      window: window,
      lookup: lookup,
      scheduledIds: {
        for (final StreamView s in streams) ...s.stream.transactionIds,
      },
      rules: rules,
      excluded: (t) => t.hidden,
    ))
      if (!dismissed.contains(f.transactionId)) f,
  ];
}
