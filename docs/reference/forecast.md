# Forecast

The cash-flow forecast: the projected balance of the chosen accounts for each day of the
next 30 or 90 days, with a confidence band, from the recurring streams, the bills and an
allowance for everyday spending (`PLAN.md` §12 "The forecast", "5d plan rulings", "5e
rulings"). The feature is `app/lib/features/forecast/`; its view is for the Plan tab's
Forecast segment, `/forecast`, which shows a placeholder until the view is mounted there.

Code:
- `domain/` (pure Dart, integer `Money` only): `cash_flow_forecast.dart` (the projection,
  `ForecastSeries`, `ForecastPoint`, `ForecastEvent`), `forecast_plan.dart` (the inputs and
  the allowance), `stream_schedule.dart` (a stream's dates), `forecast_selection.dart`
  (which accounts and which currency);
- `application/`: `forecast_providers.dart` (the selection, the plan, the series),
  `forecast_bills.dart` (the bills the forecast counts);
- `presentation/`: `forecast_view.dart` (`ForecastView`, `forecastAppBarActions`),
  `forecast_chart.dart`, `forecast_table.dart`, `forecast_accounts_sheet.dart`,
  `forecast_screen.dart` (`ForecastScreen`).

Tests: `app/test/features/forecast/` (the worked examples, the stream dates, the
allowance, the selection, a property test over 200 seeded plans, the bills, the providers
on the in-memory repositories, the screen, and goldens light and dark at text scale 1 and
2 on `test/helpers/forecast_seed.dart`, the account sheet's on a page of its own since a
golden's root navigator is the harness's), the forecast entries of
`app/test/accessibility_test.dart`, and on the harness
`app/integration_test/forecast_test.dart` (the renter's 90-day series in the demo flavor).

## The inputs

One series is projected per currency, over the covered accounts in that currency
(**The selection**):

- the **start balance**: the sum of each covered account's balance as the app shows it,
  the institution's reported balance when there is one, else the one derived from its
  transactions (`shownBalance`, `accounts.md`);
- the **streams**: of `mergedStreamsProvider`'s list (`recurring.md`), the active, unmuted
  streams on a covered account in the currency, with their live member transactions from
  `recurringLedgerProvider`. A muted stream leaves the forecast entirely: its occurrences
  are not projected, and its members stay out of the allowance as every stream's do;
- the **bills** (**Bills**);
- the **allowance** (**The allowance**).

## Stream dates

`stream_schedule.dart` gives a stream's dates from its `nextExpected` by its cadence; it is
the forecast's own, not the bills' `BillSchedule`, since a stream's predicted date already
carries its history:

- weekly and biweekly: every 7 or 14 days;
- monthly, quarterly and annually: `nextExpected`'s day of the month every 1, 3 or 12
  months, clamped to short months from the anchor each time (the 31st gives February 28,
  then March 31). When `nextExpected` is a month's last day the series is on every month's
  last day, as the detector anchors a stream on its `L` token; a stream the app did not
  detect also needs `lastExpected` on a month's last day, so a bank's stream on the 28th
  or the 30th stays there;
- semimonthly, whatever the source: the days of the month of `lastExpected` and
  `nextExpected` when they are at least 10 apart, else `nextExpected`'s day `d` and
  `d + 15` (`d - 15` past the 15th); a day of 28 or more is the month's last day (the
  detector's `L` token), so a payroll on the 15th and the month end lands on every
  month's true last day whichever of its two dates is the next, and otherwise each day
  is clamped to the month;
- unknown: `nextExpected` once.

With no `nextExpected` the series steps from `lastExpected` by the cadence (that date
itself is past); with neither there are no dates, and an `ended` stream has none.

## The arithmetic

For each day `d` from today to today + H (H is 30 or 90), H + 1 points:

    balance(d) = start + Σ stream occurrences in (today, d] + Σ bill occurrences in (today, d]
                 − allowance × days from today to d
    lower(d)   = balance(d) − Σ (median − min)   over the stream occurrences up to d
    upper(d)   = balance(d) + Σ (max − median)   over the stream occurrences up to d

A stream occurrence is the median of `StreamBand.of(members)` (the newest price step's,
`recurring.md`), signed; a stream with no live members uses its `averageAmount` with no
band. Bills and the allowance add no width, so `lower ≤ balance ≤ upper` and each side
only widens. Today's point is the start balance. The lowest point is the smallest balance,
the earliest on a tie; the first negative date the first day below zero. The inputs are
taken in id order, so their order never changes the result, and the 30-day series is the
first 31 points of the 90-day one.

**Overdue** (D2): an occurrence dated from three days ago to today that has not arrived
lands on tomorrow; older ones are dropped and the series goes on from its next date. A
stream's occurrence has arrived when a member (pending or posted) is dated on or after
three days before it, so a bank's predicted date lagging a posted payment is not counted
twice; a bill's has arrived when it is paid (**Bills**). Nothing after today is skipped.

Each point carries its events (`ForecastEvent`: the stream or bill, its name, its amount,
and the date it was due, earlier than the point's when it was overdue), streams then
bills, each by id.

## Bills

`forecast_bills.dart` takes each active bill's occurrences from three days ago to the
horizon from its schedule (`BillSchedule.of`, a followed liability's due date its anchor;
`bills.md`) and leaves out the ones paid, by a mark (`paidOccurrences`) or by the payment
assignment the bill statuses read (`billPaymentsProvider`). A bill is left out when it is
paused, when its `streamId` names a stream the series projects (the stream wins), or when
its account is not covered; a bill with no account counts in every series in its amount's
currency (D4). Its amount counts as an outflow whatever its sign; a bill with no amount is
listed among the day's events and moves nothing. It is named by its name, else by the
stream it follows, else "Bill".

## The allowance

The average daily outflow no schedule explains: the outflows on the covered accounts in
the currency dated in the 90 whole days before today (today left out), live and not hidden,
pending ones included, less every merged stream's members (muted and ended ones too), the
transactions the bill payment assignment gave to a bill, and the transfers to the user's
own accounts by effective category (`TRANSFER_OUT_ACCOUNT_TRANSFER`,
`TRANSFER_OUT_SAVINGS`; card payments stay in, D3), divided by 90 and rounded half-even.
A transfer to a savings account the app does not hold is left out too: a known limit.
Income outside the streams (gig pay, for one) is not projected, so such a user sees a
cautious line.

## The selection

`ForecastSelection` keeps the user's changes from the default (D1, D7): the accounts
turned on that the default leaves off, the ones turned off that it covers, and the
currency picked. The default covers every depository account that is not hidden; only a
depository account can be covered. So an account linked later joins by default. The
currency shown is the one picked when a covered account holds it, else the device's
default currency (`defaultCurrencyCode()`) when one does, else the first covered account's
in display order.

`forecastSelectionControllerProvider` (kept alive) reads it from `app_meta` under
`forecast_selection` (`data.md`), on this device only and never synced, as
`{"include": [...], "exclude": [...], "currency": "..."}`; an unreadable value is the
default. `toggle(account)` and `showCurrency(code)` are applied one at a time in order:
the state is updated, then written; when the write fails the state goes back and the
change's Future fails, and a line under the sheet's switches says the accounts could not
be saved until the next change is kept.

## Providers

| Provider | What |
|---|---|
| `forecastSelectionControllerProvider` | The selection (**The selection**) |
| `forecastPlanProvider` | The `ForecastPlan` of the series shown, over the longest horizon; null when no account is covered. It watches today, the selection, the accounts and their derived balances, the merged streams, the ledger, the categories, the bills, the followed liabilities' due dates, the bill payments and the streams' names |
| `forecastProvider(horizonDays)` | The `ForecastSeries` for 30 or 90 days (`forecastHorizons`), or null; the screen reads only this |

## The screen

`ForecastView` (const, no arguments, no Scaffold) is the body for the Plan tab's
`/forecast` segment, under its app bar with `forecastAppBarActions(context, ref)`:

- the 30 / 90 days `SegmentedButton`, with a Table / Chart switch beside it;
- the headline: "Lowest point $412.00 on Nov 18", or "Below zero on Nov 3" in the error
  colour;
- the chart (fl_chart 1.2.0): the balance line, the band filled between its edges
  (`BetweenBarsData`), dots on today and the lowest point, a dashed zero line when the
  band reaches zero, dates along the bottom, and a tooltip on touch with the day's
  balance and band; a screen reader hears one summary (the horizon, the start and end
  balances, the lowest point). fl_chart places points by `double` coordinates, which serve
  placement only: every amount shown is the point's `Money` formatted through intl;
- or the table, the chart's equivalent: one row per day with the date, the balance, the
  band's low and high and the day's events ("Rent -$1,650.00"; "…, due Oct 22" when it
  was overdue), each row one semantics node read as a sentence;
- the empty state when no account is covered, with Choose accounts.

The "Choose accounts" action opens `forecast_accounts_sheet.dart` on the root navigator
(`useRootNavigator`): a switch per depository account (hidden ones listed, off unless turned on) and,
when the covered accounts hold more than one currency, a chip per currency.

`ForecastScreen` is a thin Scaffold titled "Forecast" with the action and the view, with
no route of its own, for the tests and the integration test (`pumpApp`'s `router`
parameter puts it at a test router's root).
