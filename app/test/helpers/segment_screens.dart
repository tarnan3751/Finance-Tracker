// The Plan and Insights segments on screens of their own, for the tests: a Scaffold titled
// as the segment around its view, with no route (the tabs mount the views themselves, under
// PlanScaffold and InsightsScaffold); the seed helpers' routers put one at their root.
import 'package:finance_tracker/features/forecast/presentation/forecast_view.dart';
import 'package:finance_tracker/features/investments/presentation/investments_view.dart';
import 'package:finance_tracker/features/net_worth/presentation/net_worth_view.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The forecast with its own app bar and [forecastAppBarActions].
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).forecastTitle),
      actions: forecastAppBarActions(context, ref),
    ),
    body: const ForecastView(),
  );
}

/// The investments with their own app bar.
class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).investmentsTitle)),
    body: const InvestmentsView(),
  );
}

/// The net worth with its own app bar.
class NetWorthScreen extends StatelessWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).netWorthTitle)),
    body: const NetWorthView(),
  );
}
