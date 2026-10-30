/// Net worth on a screen of its own: a Scaffold titled "Net worth" around
/// [NetWorthView], for the tests; the Insights tab mounts the view itself at
/// `/net-worth`.
library;

import 'package:finance_tracker/features/net_worth/presentation/net_worth_view.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The net worth with its own app bar.
class NetWorthScreen extends StatelessWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).netWorthTitle)),
    body: const NetWorthView(),
  );
}
