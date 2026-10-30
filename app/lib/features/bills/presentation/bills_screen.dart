/// `/bills`: the Plan tab's Bills segment (`docs/reference/bills.md`, **Screens**;
/// `PLAN.md` §12 "5e rulings", "5c review rulings" item 8).
///
/// The list view: "Suggested" first when there are suggestions this device has not
/// dismissed, three of them until "Show all" (Add opens the editor prefilled; Dismiss is
/// remembered in `app_meta`), then the active bills grouped Overdue (the last occurrence missed), Due soon (due within 7
/// days, or still in its grace days) and Later, each row the name, the due date (relative
/// within a week), the expected amount and a chip (Missed, Paid, Autopay), with "Mark
/// paid" on a due or missed occurrence; then a folded "Paused" group of the inactive
/// bills, with no chip and no action. The calendar view: a month grid with a dot per
/// active bill due each day, today ringed, and the chosen day's bills under it. Tapping a
/// bill opens its editor. The app bar opens the subscriptions and a new bill.
library;

import 'dart:async';

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/core/layout/two_pane.dart';
import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/bills/domain/bill_suggestions.dart';
import 'package:finance_tracker/features/bills/presentation/bill_editor_screen.dart'
    show cadenceLabel;
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The bills segment.
class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  bool _calendar = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<BillStatus>> statuses = ref.watch(
      billStatusesProvider,
    );
    final List<BillSuggestion> suggestions =
        ref.watch(suggestedBillsProvider).value ?? const [];
    final Set<String> dismissed =
        ref.watch(dismissedBillSuggestionsProvider).value ?? const {};
    final List<BillSuggestion> shown = [
      for (final BillSuggestion s in suggestions)
        if (!dismissed.contains(billSuggestionKey(s))) s,
    ];
    final List<BillStatus>? list = statuses.value;
    final Widget toggle = Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.view_list_outlined),
              tooltip: l10n.billsListView,
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: l10n.billsCalendarView,
            ),
          ],
          selected: {_calendar},
          showSelectedIcon: false,
          onSelectionChanged: (selected) =>
              setState(() => _calendar = selected.single),
        ),
      ),
    );
    return PlanScaffold(
      segment: PlanSegment.bills,
      actions: [
        IconButton(
          tooltip: l10n.subscriptionsTitle,
          icon: const Icon(Icons.subscriptions_outlined),
          onPressed: () =>
              openDetail(context, const SubscriptionsRoute().location),
        ),
        IconButton(
          tooltip: l10n.billNew,
          icon: const Icon(Icons.add),
          onPressed: () => openDetail(context, const NewBillRoute().location),
        ),
      ],
      body: switch (list) {
        null when statuses.hasError => Center(child: Text(l10n.loadFailed)),
        null => const Center(child: CircularProgressIndicator()),
        [] when shown.isEmpty => EmptyState(
          icon: Icons.event_note_outlined,
          headline: l10n.billsEmptyHeadline,
          body: l10n.billsEmptyBody,
          action: FilledButton.icon(
            onPressed: () => openDetail(context, const NewBillRoute().location),
            icon: const Icon(Icons.add),
            label: Text(l10n.billNew),
          ),
        ),
        final List<BillStatus> list when _calendar => _BillCalendar(
          header: toggle,
          statuses: list,
        ),
        final List<BillStatus> list => _BillList(
          header: toggle,
          statuses: list,
          suggestions: shown,
        ),
      },
    );
  }
}

/// The list view: suggestions, the three groups and the paused bills.
class _BillList extends ConsumerWidget {
  const _BillList({
    required this.header,
    required this.statuses,
    required this.suggestions,
  });

  final Widget header;
  final List<BillStatus> statuses;
  final List<BillSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final LocalDate today = ref.watch(todayProvider);
    final BillPayments payments =
        ref.watch(billPaymentsProvider).value ?? const {};
    final List<_Row> overdue = [];
    final List<_Row> soon = [];
    final List<_Row> later = [];
    final List<BillReminder> paused = [];
    for (final BillStatus s in statuses) {
      if (!s.bill.active) {
        paused.add(s.bill);
        continue;
      }
      final BillOccurrence focus = billFocus(
        s,
        today,
        payments[s.bill.id] ?? const {},
      );
      final _Row row = (bill: s.bill, focus: focus);
      final LocalDate? due = focus.due;
      if (focus.state == BillState.missed) {
        overdue.add(row);
      } else if (due != null && today.daysUntil(due) <= dueWindowDays) {
        soon.add(row);
      } else {
        later.add(row);
      }
    }
    for (final List<_Row> group in [overdue, soon, later]) {
      group.sort(_byDue);
    }
    paused.sort(_byName);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        header,
        if (suggestions.isNotEmpty) ...[
          heading(l10n.billsSuggested),
          _Suggestions(suggestions),
        ],
        for (final (String title, List<_Row> rows) in [
          (l10n.billsGroupOverdue, overdue),
          (l10n.billsGroupDueSoon, soon),
          (l10n.billsGroupLater, later),
        ])
          if (rows.isNotEmpty) ...[
            heading(title),
            for (final _Row r in rows)
              _BillTile(
                key: ValueKey(r.bill.id),
                bill: r.bill,
                due: r.focus.due,
                state: r.focus.state,
                today: today,
              ),
          ],
        if (paused.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.billsGroupPaused(paused.length)),
            children: [
              for (final BillReminder b in paused)
                _BillTile(
                  key: ValueKey(b.id),
                  bill: b,
                  due: null,
                  state: null,
                  today: today,
                ),
            ],
          ),
      ],
    );
  }
}

/// A bill and the occurrence its row shows.
typedef _Row = ({BillReminder bill, BillOccurrence focus});

int _byName(BillReminder a, BillReminder b) {
  final int byName = (a.name ?? '').toLowerCase().compareTo(
    (b.name ?? '').toLowerCase(),
  );
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// By due date, no date last, then by name.
int _byDue(_Row a, _Row b) {
  final LocalDate? x = a.focus.due;
  final LocalDate? y = b.focus.due;
  if (x != y) {
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
  return _byName(a.bill, b.bill);
}

/// When [due] is, as a bill's row says it: relative within a week of [today] (up to the
/// 7 days the Due soon group reaches).
String _dueLabel(AppLocalizations l10n, LocalDate due, LocalDate today) {
  final int days = today.daysUntil(due);
  if (days >= 0 && days <= dueWindowDays) return l10n.billDueIn(days);
  if (days < 0 && days > -7) return l10n.billDueAgo(-days);
  return l10n.billDueOn(shortDateLabel(due));
}

/// One bill: its name, the occurrence [due] (null for a paused bill, or one with no
/// next due date) in [state], the expected amount, the chip, and Mark paid when that
/// occurrence is due or missed.
class _BillTile extends ConsumerWidget {
  const _BillTile({
    super.key,
    required this.bill,
    required this.due,
    required this.state,
    required this.today,
  });

  final BillReminder bill;
  final LocalDate? due;
  final BillState? state;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Map<String, String> streamNames =
        ref.watch(streamNamesProvider).value ?? const {};
    final String name = billName(bill.name ?? streamNames[bill.streamId], l10n);
    final Money? amount = bill.amount;
    final LocalDate? due = this.due;
    final String? chip = switch (state) {
      _ when !bill.active => null,
      BillState.missed => l10n.billStateMissed,
      BillState.paid => l10n.billStatePaid,
      _ when bill.autopay => l10n.billStateAutopay,
      _ => null,
    };
    final bool markable =
        bill.active &&
        due != null &&
        (state == BillState.due || state == BillState.missed);
    return ListTile(
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (due) {
            _ when !bill.active => l10n.billPaused,
            final LocalDate d => _dueLabel(l10n, d, today),
            null => l10n.billNoNextDue,
          }),
          if (amount != null)
            Text(Money(amount.minorUnits.abs(), amount.currencyCode).format()),
          if (chip != null || markable)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (chip != null)
                  _StateChip(
                    label: chip,
                    color: state == BillState.missed
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                if (markable)
                  TextButton(
                    onPressed: () => _markPaid(context, ref, name, due),
                    child: Text(
                      l10n.billMarkPaid,
                      semanticsLabel: l10n.billMarkPaidLabel(
                        name,
                        shortDateLabel(due),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      onTap: () => openDetail(context, EditBillRoute(bill.id).location),
    );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    String name,
    LocalDate due,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final BillActions actions = ref.read(billActionsProvider);
    await actions.setPaid(bill.id, due, paid: true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.billMarkedPaid(name)),
          duration: undoDuration,
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () =>
                unawaited(actions.setPaid(bill.id, due, paid: false)),
          ),
        ),
      );
  }
}

/// A bill's state in words, outlined in [color].
class _StateChip extends StatelessWidget {
  const _StateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    ),
  );
}

/// How many suggestions show before "Show all".
const int shownSuggestions = 3;

/// The suggestions: the first [shownSuggestions], then "Show all (N)", which reveals the
/// rest, so the bills stay near the top.
class _Suggestions extends StatefulWidget {
  const _Suggestions(this.suggestions);

  final List<BillSuggestion> suggestions;

  @override
  State<_Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<_Suggestions> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final List<BillSuggestion> suggestions = widget.suggestions;
    final bool folded = !_all && suggestions.length > shownSuggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final BillSuggestion s
            in folded ? suggestions.take(shownSuggestions) : suggestions)
          _SuggestionTile(key: ValueKey(billSuggestionKey(s)), suggestion: s),
        if (folded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _all = true),
                icon: const Icon(Icons.expand_more),
                label: Text(
                  AppLocalizations.of(context)
                      .billsSuggestedShowAll(suggestions.length),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A suggested bill: its name, cadence, next due date and amount, with Add and Dismiss.
class _SuggestionTile extends ConsumerWidget {
  const _SuggestionTile({super.key, required this.suggestion});

  final BillSuggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    // The bill it would make, for its values; nothing is saved here.
    final BillReminder bill = suggestion.accept('');
    final Money? amount = bill.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          title: Text(suggestion.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.billSuggestionDetail(
                  cadenceLabel(l10n, bill.cadence),
                  shortDateLabel(suggestion.dueDate),
                ),
              ),
              if (amount != null)
                Text(
                  Money(amount.minorUnits.abs(), amount.currencyCode).format(),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => ref
                    .read(dismissedBillSuggestionsProvider.notifier)
                    .dismiss(suggestion),
                child: Text(
                  l10n.billSuggestionDismiss,
                  semanticsLabel: l10n.billSuggestionDismissLabel(
                    suggestion.name,
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: () => switch (suggestion) {
                  StreamBillSuggestion(:final stream) => openDetail(
                    context,
                    NewBillRoute(streamId: stream.id).location,
                  ),
                  LiabilityBillSuggestion(:final liability) => openDetail(
                    context,
                    NewBillRoute(liabilityAccountId: liability.accountId)
                        .location,
                  ),
                },
                child: Text(
                  l10n.billSuggestionAdd,
                  semanticsLabel: l10n.billSuggestionAddLabel(suggestion.name),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The calendar view: the month grid, then the chosen day's bills.
class _BillCalendar extends ConsumerStatefulWidget {
  const _BillCalendar({required this.header, required this.statuses});

  final Widget header;
  final List<BillStatus> statuses;

  @override
  ConsumerState<_BillCalendar> createState() => _BillCalendarState();
}

class _BillCalendarState extends ConsumerState<_BillCalendar> {
  /// The first day of the month shown.
  late LocalDate _month = ref.read(todayProvider).firstOfMonth;

  /// The day chosen, in [_month], or null.
  late LocalDate? _day = ref.read(todayProvider);

  /// Shows [month], with today chosen when it is in it.
  void _show(LocalDate month) => setState(() {
    final LocalDate today = ref.read(todayProvider);
    _month = month;
    _day = today.firstOfMonth == month ? today : null;
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final LocalDate today = ref.watch(todayProvider);
    final BillPayments payments =
        ref.watch(billPaymentsProvider).value ?? const {};
    final Map<String, LocalDate> liabilityDue =
        ref.watch(liabilityDueDatesProvider).value ?? const {};
    final Map<String, String> streamNames =
        ref.watch(streamNamesProvider).value ?? const {};
    final LocalDate next = _month.lastOfMonth.addDays(1);
    // The active bills due each day of the month, by name.
    final Map<LocalDate, List<BillReminder>> byDay = {};
    for (final BillStatus s in widget.statuses) {
      if (!s.bill.active) continue;
      final BillSchedule schedule = BillSchedule.of(
        s.bill,
        liabilityDue: liabilityDue[s.bill.id],
      );
      for (final LocalDate due in schedule.between(_month, next)) {
        byDay.putIfAbsent(due, () => []).add(s.bill);
      }
    }
    for (final List<BillReminder> bills in byDay.values) {
      bills.sort(_byName);
    }
    String nameOf(BillReminder b) =>
        billName(b.name ?? streamNames[b.streamId], l10n);
    BillState stateOf(BillReminder b, LocalDate due) =>
        occurrenceState(b, due, today, paidBy: payments[b.id]?[due]);

    // Leading blanks put the 1st under its weekday, counted from the locale's first
    // day of the week (index 0 is Sunday; LocalDate's weekday is 1 for Monday to 7).
    final int lead =
        (_month.weekday % 7 - material.firstDayOfWeekIndex + 7) % 7;
    final List<Widget> cells = [
      for (int i = 0; i < lead; i++) const SizedBox.shrink(),
      for (LocalDate d = _month; d.isBefore(next); d = d.addDays(1))
        _DayCell(
          day: d,
          today: today,
          selected: d == _day,
          dots: [
            for (final BillReminder b in byDay[d] ?? const <BillReminder>[])
              stateOf(b, d) == BillState.missed
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
          ],
          label: l10n.billsCalendarDay(
            DateFormat.MMMd().format(d.toDateTime()),
            byDay[d]?.length ?? 0,
            listLine(l10n, (byDay[d] ?? const <BillReminder>[]).map(nameOf)),
          ),
          onTap: () => setState(() => _day = d),
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    final LocalDate? day = _day;
    final List<BillReminder> dayBills = day == null
        ? const []
        : byDay[day] ?? const [];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        widget.header,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.billsPreviousMonth,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _show(_month.addDays(-1).firstOfMonth),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(_month.toDateTime()),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.billsNextMonth,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _show(next),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // The day numbers stop growing at 1.5 times, so a week fits the width.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Table(
              children: [
                TableRow(
                  children: [
                    for (int i = 0; i < 7; i++)
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            material.narrowWeekdays[(i +
                                    material.firstDayOfWeekIndex) %
                                7],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                for (int row = 0; row < cells.length; row += 7)
                  TableRow(children: cells.sublist(row, row + 7)),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
        if (day != null && dayBills.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.billsCalendarNone(shortDateLabel(day)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (day != null)
          for (final BillReminder b in dayBills)
            _BillTile(
              key: ValueKey(b.id),
              bill: b,
              due: day,
              state: stateOf(b, day),
              today: today,
            ),
      ],
    );
  }
}

/// A day of the calendar: its number, ringed when it is [today] and filled when
/// [selected], over one dot per bill due (up to three), read as [label].
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.selected,
    required this.dots,
    required this.label,
    required this.onTap,
  });

  final LocalDate day;
  final LocalDate today;
  final bool selected;
  final List<Color> dots;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? colors.primary : null,
                  border: day == today && !selected
                      ? Border.all(color: colors.primary)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    '${day.day}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final Color c in dots.take(3))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
