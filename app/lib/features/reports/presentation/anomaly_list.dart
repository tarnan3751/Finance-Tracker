/// "Worth a look": the anomaly flags of a window as a hint list (`PLAN.md` §12 "6c plan
/// rulings"), each with what makes it stand out, a tap to the transaction and Dismiss
/// (with Undo), which hides it on this device. The Undo snackbar lasts the app's undo
/// window. It is taken down at once when the list is disposed (another Insights
/// segment, the weekly summary closed, the report reloading); a bottom-tab switch or a
/// pushed route keeps the list mounted, so there the snackbar stays for the rest of its
/// window.
library;

import 'dart:async';

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/reports/application/anomaly_providers.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
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
class AnomalyList extends ConsumerStatefulWidget {
  const AnomalyList({super.key, required this.window});

  final LocalDateRange window;

  @override
  ConsumerState<AnomalyList> createState() => _AnomalyListState();
}

class _AnomalyListState extends ConsumerState<AnomalyList> {
  late ScaffoldMessengerState _messenger;
  // The Undo snackbar of the last dismissal while it is up; the tiles do not own it,
  // since a dismissed tile leaves the list at once.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    if (_undo != null) {
      // The tree is locked while it is disposed; the messenger is told after the frame.
      final ScaffoldMessengerState messenger = _messenger;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messenger.mounted) messenger.clearSnackBars();
      });
    }
    super.dispose();
  }

  Future<void> _dismiss(AnomalyFlag flag) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DismissedAnomalies dismissed = ref.read(
      dismissedAnomaliesProvider.notifier,
    );
    await dismissed.dismiss(flag.transactionId);
    if (!mounted) return;
    _messenger.hideCurrentSnackBar();
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> undo =
        _messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.anomalyDismissed),
            duration: undoDuration,
            persist: false,
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => dismissed.restore(flag.transactionId),
            ),
          ),
        );
    _undo = undo;
    unawaited(
      undo.closed.whenComplete(() {
        if (_undo == undo) _undo = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<AnomalyFlag>> flags = ref.watch(
      anomaliesProvider(widget.window),
    );
    return switch (flags) {
      AsyncValue(value: final List<AnomalyFlag> list) when list.isEmpty =>
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(l10n.anomaliesNone),
        ),
      AsyncValue(value: final List<AnomalyFlag> list) => Column(
        children: [
          for (final AnomalyFlag f in list)
            _AnomalyTile(f, onDismiss: () => _dismiss(f)),
        ],
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

class _AnomalyTile extends StatelessWidget {
  const _AnomalyTile(this.flag, {required this.onDismiss});

  final AnomalyFlag flag;

  // Dismisses [flag] and offers Undo.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
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
        onPressed: onDismiss,
      ),
    );
  }
}
