/// The [WidgetWriter] of every flavor on a device, over `home_widget`: the snapshot's
/// JSON under [widgetSnapshotKey] in the plugin's preferences file, then an update
/// broadcast to each of the three providers in `dev.tarnan.financetracker.widgets`
/// (`app/android/app/src/main/kotlin/dev/tarnan/financetracker/widgets/`), which render
/// it and nothing else. The providers are named in full: the namespace stays
/// `dev.tarnan.financetracker` while the demo flavor's application id has a suffix.
library;

import 'dart:convert';

import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/features/widgets/domain/widget_writer.dart';
import 'package:home_widget/home_widget.dart';

/// The providers the writer redraws, by their full class names.
const List<String> widgetProviders = [
  'dev.tarnan.financetracker.widgets.BalancesWidgetProvider',
  'dev.tarnan.financetracker.widgets.BudgetsWidgetProvider',
  'dev.tarnan.financetracker.widgets.BillsWidgetProvider',
];

/// The widgets through `home_widget`.
final class HomeWidgetWriter implements WidgetWriter {
  const HomeWidgetWriter();

  @override
  Future<void> write(WidgetData data) async {
    await HomeWidget.saveWidgetData<String>(
      widgetSnapshotKey,
      jsonEncode(data.toJson()),
    );
    await _redraw();
  }

  @override
  Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>(widgetSnapshotKey, null);
    await _redraw();
  }

  Future<void> _redraw() async {
    for (final String provider in widgetProviders) {
      await HomeWidget.updateWidget(qualifiedAndroidName: provider);
    }
  }
}
