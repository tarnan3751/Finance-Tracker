/// "Worth a look": the anomaly flags of a window as a hint list (`PLAN.md` §12 "6c plan
/// rulings"), each with what makes it stand out, a tap to the transaction and Dismiss
/// (with Undo), which hides it on this device.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/reports/application/anomaly_providers.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// What [flag] says, in words: "Usually $12.00 here" or "New here in six months".
String anomalyReason(AppLocalizations l10n, AnomalyFlag flag) =>
    switch (flag.kind) {
      AnomalyKind.unusualAmount => switch (flag.basis) {
        AnomalyBasis.category => l10n.anomalyUsualCategory(
          flag.median!.format(),
        ),
        _ => l10n.anomalyUsualMerchant(flag.median!.format()),
      },
      AnomalyKind.newMerchant => l10n.anomalyNewMerchant,
    };

/// The flags of the rows dated in [window], or a line saying there are none.
class AnomalyList extends ConsumerWidget {
  const AnomalyList({super.key, required this.window});

  final LocalDateRange window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<AnomalyFlag>> flags = ref.watch(
      anomaliesProvider(window),
    );
    return switch (flags) {
      AsyncValue(value: final List<AnomalyFlag> list) when list.isEmpty =>
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(l10n.anomaliesNone),
        ),
      AsyncValue(value: final List<AnomalyFlag> list) => Column(
        children: [for (final AnomalyFlag f in list) _AnomalyTile(f)],
      ),
      AsyncValue(hasError: true) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.loadFailed),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _AnomalyTile extends ConsumerWidget {
  const _AnomalyTile(this.flag);

  final AnomalyFlag flag;

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DismissedAnomalies dismissed = ref.read(
      dismissedAnomaliesProvider.notifier,
    );
    await dismissed.dismiss(flag.transactionId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.anomalyDismissed),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => dismissed.restore(flag.transactionId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Transaction t = flag.transaction;
    final String name = EnrichedMerchant.resolve(t).displayName;
    final String date = DateFormat.MMMd().format(t.date.toDateTime());
    final String reason = anomalyReason(l10n, flag);
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(name),
      subtitle: Text(
        '${l10n.captionPair(date, flag.amount.format())}\n$reason',
      ),
      isThreeLine: true,
      onTap: () => TransactionRoute(t.id).push<void>(context),
      trailing: IconButton(
        tooltip: l10n.anomalyDismissTooltip(name),
        icon: const Icon(Icons.close),
        onPressed: () => _dismiss(context, ref),
      ),
    );
  }
}
