/// The forecast on a screen of its own: a Scaffold titled "Forecast" with
/// [forecastAppBarActions] and [ForecastView]. It has no route: the Plan tab mounts the
/// view itself (`PLAN.md` §12 "5e rulings"); this screen serves the tests and the
/// integration test.
library;

import 'package:finance_tracker/features/forecast/presentation/forecast_view.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The forecast with its own app bar.
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
