/// The Investments segment on a screen of its own: a Scaffold titled "Investments" with
/// [InvestmentsView], with no route of its own, for the tests: the Insights tab mounts
/// the view itself at `/investments`.
library;

import 'package:finance_tracker/features/investments/presentation/investments_view.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The investments with their own app bar.
class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).investmentsTitle)),
    body: const InvestmentsView(),
  );
}
