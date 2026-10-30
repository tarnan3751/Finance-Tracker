/// One liability's payoff projection (`docs/reference/net-worth.md`, **The screen**): the
/// account (captioned when it is hidden, which net worth still counts), what it owes, the
/// rate and the payment with where each came from, the projection (paid off in N months
/// on a date with the interest; never, when the payment does not cover the interest; over
/// 50 years), the entries for a rate or a payment the bank does not report, and the
/// extra-per-month slider with what it changes.
library;

import 'package:finance_tracker/features/net_worth/application/net_worth_providers.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff.dart';
import 'package:finance_tracker/features/net_worth/domain/payoff_entries.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// How many steps the extra-payment slider has.
const int extraSteps = 20;

/// The extra a month at step [k] of the slider for [payment]: k twentieths of the
/// payment, each step rounded up to a whole major unit, at least one.
Money extraAt(Money payment, int k) {
  int unit = 1;
  for (int i = 0; i < Currency.scaleOf(payment.currencyCode); i++) {
    unit *= 10;
  }
  final int raw = (payment.minorUnits + extraSteps - 1) ~/ extraSteps;
  final int units = (raw + unit - 1) ~/ unit;
  final int step = (units < 1 ? 1 : units) * unit;
  return Money(step * k, payment.currencyCode);
}

/// The projection's sentence.
String payoffText(PayoffProjection projection, AppLocalizations l10n) =>
    switch (projection) {
      PaidOff(:final months, :final date, :final totalInterest) =>
        l10n.netWorthPaidOff(
          months,
          DateFormat.yMMM().format(date.toDateTime()),
          totalInterest.format(),
        ),
      NeverPaidOff(:final firstInterest) => l10n.netWorthNever(
        firstInterest.format(),
      ),
      BeyondCap() => l10n.netWorthBeyondCap,
      NothingOwed() => l10n.netWorthNothingOwed,
    };

/// The card of [payoff].
class LiabilityPayoffCard extends ConsumerStatefulWidget {
  const LiabilityPayoffCard(this.payoff, {super.key});

  final LiabilityPayoff payoff;

  @override
  ConsumerState<LiabilityPayoffCard> createState() =>
      _LiabilityPayoffCardState();
}

class _LiabilityPayoffCardState extends ConsumerState<LiabilityPayoffCard> {
  // The slider's step while it is dragged; the stored extra otherwise.
  int? _dragging;

  Future<void> _save(Future<void> Function() change) async {
    try {
      await change();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).netWorthEntryFailed),
        ),
      );
    }
  }

  Future<void> _enterRate() async {
    final LiabilityPayoff p = widget.payoff;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final _Entered? entered = await showDialog<_Entered>(
      context: context,
      builder: (_) => _EntryDialog(
        title: l10n.netWorthRateLabel,
        initial: switch (p.entry.rateBasisPoints) {
          final int bp => rateText(bp),
          null => '',
        },
        error: l10n.netWorthRateInvalid,
        parse: (text) => parseRateBasisPoints(text) != null,
        canClear: p.entry.rateBasisPoints != null,
      ),
    );
    if (entered == null || !mounted) return;
    await _save(
      () => ref
          .read(payoffEntriesControllerProvider.notifier)
          .setRate(
            p.account.id,
            entered.text == null ? null : parseRateBasisPoints(entered.text!),
          ),
    );
  }

  Future<void> _enterPayment() async {
    final LiabilityPayoff p = widget.payoff;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String currency = p.account.currencyCode;
    Money? parse(String text) {
      try {
        final Money m = Money.parse(text, currency);
        return m.isPositive ? m : null;
      } on FormatException {
        return null;
      }
    }

    final _Entered? entered = await showDialog<_Entered>(
      context: context,
      builder: (_) => _EntryDialog(
        title: l10n.netWorthPaymentLabel,
        initial: p.entry.payment?.format(symbol: false) ?? '',
        error: l10n.netWorthPaymentInvalid,
        parse: (text) => parse(text) != null,
        canClear: p.entry.payment != null,
      ),
    );
    if (entered == null || !mounted) return;
    await _save(
      () => ref
          .read(payoffEntriesControllerProvider.notifier)
          .setPayment(
            p.account.id,
            entered.text == null ? null : parse(entered.text!),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final LiabilityPayoff p = widget.payoff;
    final PayoffTerms terms = p.terms;
    final TextStyle? muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final String rate = switch ((terms.rateBasisPoints, terms.rateSource)) {
      (final int bp, PayoffInputSource.entered) => l10n.netWorthRateEntered(
        rateText(bp),
      ),
      (final int bp, _) => l10n.netWorthRate(rateText(bp)),
      _ => l10n.netWorthNoRate,
    };
    final String payment = switch ((terms.payment, terms.paymentKind)) {
      (final Money m, PayoffPaymentKind.entered) => l10n.netWorthPaymentEntered(
        m.format(),
      ),
      (final Money m, PayoffPaymentKind.monthly) => l10n.netWorthPaymentMonthly(
        m.format(),
      ),
      (final Money m, _) => l10n.netWorthPaymentMinimum(m.format()),
      _ => l10n.netWorthNoPayment,
    };
    final bool rateEditable = terms.rateSource != PayoffInputSource.reported;
    final bool paymentEditable =
        terms.paymentKind == null ||
        terms.paymentKind == PayoffPaymentKind.entered;
    final Money? base = terms.payment;
    final PayoffProjection? projection = p.projection;
    // The stored extra is the one source of the slider's position, its label and the
    // result line; when the payment changed, it is snapped to the new steps and written
    // back, so the three never disagree for longer than that write.
    final Money? stored = switch ((base, p.entry.extra)) {
      (final Money b, final Money e) when e.currencyCode == b.currencyCode => e,
      _ => null,
    };
    final int storedStep = base == null || stored == null
        ? 0
        : _stepOf(base, stored);
    if (base != null && stored != null) {
      _resnap(p.account.id, stored, extraAt(base, storedStep));
    }
    final int step = _dragging ?? storedStep;
    final Money? shownExtra = base == null
        ? null
        : _dragging == null
        ? (stored ?? extraAt(base, 0))
        : extraAt(base, _dragging!);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A wrap, so with large text the amount goes under the name.
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(p.account.name, style: theme.textTheme.titleMedium),
                      Text(
                        l10n.netWorthOwed(terms.owed.format()),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  if (p.account.isHidden)
                    Text(l10n.netWorthHiddenAccount, style: muted),
                  Text(rate, style: muted),
                  Text(payment, style: muted),
                  if (projection != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      payoffText(projection, l10n),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: projection is NeverPaidOff
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rateEditable || paymentEditable)
              Wrap(
                spacing: 8,
                children: [
                  if (rateEditable)
                    TextButton(
                      onPressed: _enterRate,
                      child: Text(
                        terms.rateSource == PayoffInputSource.entered
                            ? l10n.netWorthEditRate
                            : l10n.netWorthEnterRate,
                      ),
                    ),
                  if (paymentEditable)
                    TextButton(
                      onPressed: _enterPayment,
                      child: Text(
                        terms.paymentKind == PayoffPaymentKind.entered
                            ? l10n.netWorthEditPayment
                            : l10n.netWorthEnterPayment,
                      ),
                    ),
                ],
              ),
            if (base != null && terms.rateBasisPoints != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.netWorthExtra(shownExtra!.format()),
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                value: step.toDouble(),
                max: extraSteps.toDouble(),
                divisions: extraSteps,
                label: shownExtra.format(),
                semanticFormatterCallback: (v) =>
                    l10n.netWorthExtra(extraAt(base, v.round()).format()),
                onChanged: (v) => setState(() => _dragging = v.round()),
                onChangeEnd: (v) async {
                  final Money extra = extraAt(base, v.round());
                  await _save(
                    () => ref
                        .read(payoffEntriesControllerProvider.notifier)
                        .setExtra(p.account.id, extra.isZero ? null : extra),
                  );
                  if (mounted) setState(() => _dragging = null);
                },
              ),
              if (_dragging == null &&
                  p.withExtra != null &&
                  projection != null)
                Text(
                  l10n.netWorthWithExtra(
                    p.entry.extra!.format(),
                    _difference(projection, p.withExtra!, l10n),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // The extra last asked to be snapped, so one mismatch is written back once.
  Money? _snapping;

  // Writes [snapped] back for [accountId] when it differs from the [stored] extra (the
  // payment changed and the extra is off the slider's new steps); after this frame.
  void _resnap(String accountId, Money stored, Money snapped) {
    if (snapped == stored || snapped == _snapping) return;
    _snapping = snapped;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _save(
        () => ref
            .read(payoffEntriesControllerProvider.notifier)
            .setExtra(accountId, snapped.isZero ? null : snapped),
      );
    });
  }

  // The step of [extra] on the slider for [payment], the nearest at or below it.
  static int _stepOf(Money payment, Money extra) {
    for (int k = extraSteps; k > 0; k--) {
      if (extraAt(payment, k) <= extra) return k;
    }
    return 0;
  }

  static String _difference(
    PayoffProjection base,
    PayoffProjection more,
    AppLocalizations l10n,
  ) => switch ((base, more)) {
    (PaidOff(:final months, :final totalInterest), PaidOff() && final m) =>
      l10n.netWorthExtraDifference(
        months - m.months,
        (totalInterest - m.totalInterest).format(),
      ),
    _ => payoffText(more, l10n),
  };
}

// What an entry dialog returns: the text entered, or null to clear the entry.
typedef _Entered = ({String? text});

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    required this.title,
    required this.initial,
    required this.error,
    required this.parse,
    required this.canClear,
  });

  final String title;
  final String initial;
  final String error;
  final bool Function(String) parse;
  final bool canClear;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );
  bool _invalid = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.parse(_text.text)) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop<_Entered>((text: _text.text));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: widget.title,
          errorText: _invalid ? widget.error : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.canClear)
          TextButton(
            onPressed: () => Navigator.of(context).pop<_Entered>((text: null)),
            child: Text(l10n.netWorthClearEntry),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
