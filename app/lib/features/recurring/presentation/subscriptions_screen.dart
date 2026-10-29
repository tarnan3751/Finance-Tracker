/// `/bills/subscriptions`: the subscriptions, opened from the Plan tab's Bills segment
/// (`docs/reference/recurring.md`, **Screens**; `PLAN.md` §12 "5e rulings").
///
/// At the top, what the subscriptions with a known yearly cost cost a year, per currency
/// ("$625.75 a year across 4 subscriptions"). Then one row per subscription
/// (`subscriptionsProvider`), by yearly cost, the irregular ones last: its name, cadence
/// and usual amount ("Monthly, $15.49 each"), its yearly cost, and "Detected from your
/// transactions" when the app found it. Each row's menu mutes it, says it is not a
/// subscription, renames it (blank, or the merchant's name, clears the override), or
/// opens the bill editor prefilled from the stream's suggestion when there is one; each
/// change offers an Undo that restores the earlier choice. Below, folded, the muted streams (Unmute,
/// Rename) and the other active outflow streams the app does not count as subscriptions
/// (Mark as subscription, Rename), so a misclassification can be undone.
library;

import 'dart:async';

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_suggestions.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscriptions.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// What a stream's menu can do.
enum _StreamAction {
  mute,
  unmute,
  notSubscription,
  markSubscription,
  rename,
  createBill,
}

/// The subscriptions screen.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Subscription>> subscriptions = ref.watch(
      subscriptionsProvider,
    );
    final AsyncValue<List<StreamView>> streams = ref.watch(
      mergedStreamsProvider,
    );
    final Set<String> suggested = {
      for (final BillSuggestion s
          in ref.watch(suggestedBillsProvider).value ?? const [])
        if (s case StreamBillSuggestion(:final stream)) stream.id,
    };
    final List<Subscription>? subs = subscriptions.value;
    final List<StreamView>? views = streams.value;
    final Widget body;
    if (subs == null || views == null) {
      body = subscriptions.hasError || streams.hasError
          ? Center(child: Text(l10n.loadFailed))
          : const Center(child: CircularProgressIndicator());
    } else {
      final List<StreamView> muted = [
        for (final StreamView v in views)
          if (v.muted) v,
      ];
      final List<StreamView> others = [
        for (final StreamView v in views)
          if (!v.muted &&
              !v.isSubscription &&
              v.stream.status == RecurringStatus.active &&
              // Outflows only: income is never a subscription.
              v.stream.averageAmount.isNegative)
            v,
      ];
      body = subs.isEmpty && muted.isEmpty && others.isEmpty
          ? EmptyState(
              icon: Icons.subscriptions_outlined,
              headline: l10n.subscriptionsEmptyHeadline,
              body: l10n.subscriptionsEmptyBody,
            )
          : _SubscriptionList(
              subscriptions: subs,
              muted: muted,
              others: others,
              suggested: suggested,
            );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionsTitle)),
      body: body,
    );
  }
}

/// [subscriptions] by yearly cost (by currency first), the irregular ones last, then by
/// name.
List<Subscription> _byYearlyCost(List<Subscription> subscriptions) =>
    [...subscriptions]..sort((a, b) {
      final Money? x = a.annualCost;
      final Money? y = b.annualCost;
      if (x == null || y == null) {
        if (x != y) return x == null ? 1 : -1;
      } else if (x.currencyCode != y.currencyCode) {
        return x.currencyCode.compareTo(y.currencyCode);
      } else if (x != y) {
        return y.compareTo(x);
      }
      final int byName = a.view.displayName.toLowerCase().compareTo(
        b.view.displayName.toLowerCase(),
      );
      return byName != 0
          ? byName
          : a.view.stream.id.compareTo(b.view.stream.id);
    });

class _SubscriptionList extends ConsumerWidget {
  const _SubscriptionList({
    required this.subscriptions,
    required this.muted,
    required this.others,
    required this.suggested,
  });

  final List<Subscription> subscriptions;
  final List<StreamView> muted;
  final List<StreamView> others;

  /// The streams a bill can be made from.
  final Set<String> suggested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    // The yearly totals, per currency, of the subscriptions with a known yearly cost.
    final Map<String, ({Money total, int count})> totals = {};
    for (final Subscription s in subscriptions) {
      final Money? cost = s.annualCost;
      if (cost == null) continue;
      final current = totals[cost.currencyCode];
      totals[cost.currencyCode] = current == null
          ? (total: cost, count: 1)
          : (total: current.total + cost, count: current.count + 1);
    }
    final List<String> currencies = totals.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (currencies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final String code in currencies)
                  Text(
                    l10n.subscriptionsTotal(
                      totals[code]!.total.format(),
                      totals[code]!.count,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
              ],
            ),
          ),
        for (final Subscription s in _byYearlyCost(subscriptions))
          _StreamTile(
            key: ValueKey(s.view.stream.id),
            view: s.view,
            annualCost: s.annualCost,
            actions: [
              _StreamAction.mute,
              _StreamAction.notSubscription,
              _StreamAction.rename,
              if (suggested.contains(s.view.stream.id))
                _StreamAction.createBill,
            ],
          ),
        if (muted.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.subscriptionsMuted(muted.length)),
            children: [
              for (final StreamView v in muted)
                _StreamTile(
                  key: ValueKey(v.stream.id),
                  view: v,
                  actions: const [_StreamAction.unmute, _StreamAction.rename],
                ),
            ],
          ),
        if (others.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.subscriptionsOthers(others.length)),
            children: [
              for (final StreamView v in others)
                _StreamTile(
                  key: ValueKey(v.stream.id),
                  view: v,
                  actions: const [
                    _StreamAction.markSubscription,
                    _StreamAction.rename,
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

/// One stream: its name, cadence and usual amount, its yearly cost when it is a
/// subscription with a known cadence, the source caption, and its menu of [actions].
class _StreamTile extends ConsumerWidget {
  const _StreamTile({
    super.key,
    required this.view,
    this.annualCost,
    required this.actions,
  });

  final StreamView view;
  final Money? annualCost;
  final List<_StreamAction> actions;

  String _label(AppLocalizations l10n, _StreamAction action) =>
      switch (action) {
        _StreamAction.mute => l10n.streamMute,
        _StreamAction.unmute => l10n.streamUnmute,
        _StreamAction.notSubscription => l10n.streamNotSubscription,
        _StreamAction.markSubscription => l10n.streamMarkSubscription,
        _StreamAction.rename => l10n.streamRename,
        _StreamAction.createBill => l10n.streamCreateBill,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final RecurringStream stream = view.stream;
    final Money? yearly = annualCost;
    return ListTile(
      title: Text(view.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.streamAmountEach(
              l10n.streamCadence(stream.cadence.name),
              stream.averageAmount.abs().format(),
            ),
          ),
          if (yearly != null) Text(l10n.streamYearly(yearly.format())),
          if (stream.source == RecurringSource.detected)
            Text(
              l10n.streamDetected,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: PopupMenuButton<_StreamAction>(
        tooltip: l10n.streamActions(view.displayName),
        onSelected: (action) => _act(context, ref, action),
        itemBuilder: (context) => [
          for (final _StreamAction a in actions)
            PopupMenuItem(value: a, child: Text(_label(l10n, a))),
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    _StreamAction action,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final StreamActions streams = ref.read(streamActionsProvider);
    final String id = view.stream.id;
    final String name = view.displayName;

    void offerUndo(String message, Future<void> Function() undo) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: undoDuration,
            persist: false,
            action: SnackBarAction(label: l10n.undo, onPressed: undo),
          ),
        );
    }

    switch (action) {
      case _StreamAction.mute || _StreamAction.unmute:
        final bool before = view.muted;
        final bool after = action == _StreamAction.mute;
        await streams.mute(id, muted: after);
        offerUndo(
          after ? l10n.streamMutedDone(name) : l10n.streamUnmutedDone(name),
          () => streams.mute(id, muted: before),
        );
      case _StreamAction.notSubscription || _StreamAction.markSubscription:
        final bool? before = view.userOverride?.isSubscription;
        final bool after = action == _StreamAction.markSubscription;
        await streams.setSubscription(id, after);
        offerUndo(
          after
              ? l10n.streamMarkSubscriptionDone(name)
              : l10n.streamNotSubscriptionDone(name),
          () => streams.setSubscription(id, before),
        );
      case _StreamAction.rename:
        final String? before = view.userOverride?.displayName;
        final String? entered = await showDialog<String>(
          context: context,
          builder: (context) => _RenameDialog(view: view),
        );
        if (entered == null) return;
        // Blank, or the merchant's own name, clears the override rather than storing
        // a copy of the name.
        final String trimmed = entered.trim();
        final String? after =
            trimmed.isEmpty || trimmed == view.stream.merchantName
            ? null
            : trimmed;
        if (after == before) return;
        await streams.rename(id, after);
        offerUndo(
          l10n.streamRenamedDone(after ?? view.stream.merchantName),
          () => streams.rename(id, before),
        );
      case _StreamAction.createBill:
        unawaited(NewBillRoute(streamId: id).push<void>(context));
    }
  }
}

/// Asks for a stream's name; pops with the text entered (blank restores the merchant's
/// name), or null when cancelled.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.view});

  final StreamView view;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.view.displayName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.streamRename),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.streamRenameLabel,
          helperText: l10n.streamRenameHelper(widget.view.stream.merchantName),
          helperMaxLines: 3,
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
