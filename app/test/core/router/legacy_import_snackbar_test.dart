// The app shell's one-time report of the legacy import: a snack bar with the count and
// total on the first frame, then the summary is cleared so it is not shown again.
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/accounts/presentation/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/pump_app.dart';

class _Imported extends LegacyImportResult {
  _Imported(this.summary);

  final ImportSummary? summary;

  @override
  ImportSummary? build() => summary;
}

Future<ProviderContainer> _pumpWith(
  WidgetTester tester,
  ImportSummary? summary,
) async {
  await pumpApp(
    tester,
    overrides: [
      legacyImportResultProvider.overrideWith(() => _Imported(summary)),
    ],
  );
  return ProviderScope.containerOf(tester.element(find.byType(AccountsScreen)));
}

void main() {
  testWidgets('an import is reported once, with its count and total', (
    tester,
  ) async {
    final ProviderContainer container = await _pumpWith(
      tester,
      ImportSummary(transactions: 12, total: Money(4500, 'USD'), skipped: 0),
    );

    expect(
      find.text(r'Imported 12 entries into “Imported”, totalling $45.00.'),
      findsOneWidget,
    );
    expect(container.read(legacyImportResultProvider), isNull);
  });

  testWidgets('skipped entries are reported too', (tester) async {
    await _pumpWith(
      tester,
      ImportSummary(transactions: 1, total: Money(-100, 'USD'), skipped: 2),
    );

    expect(
      find.text(
        r'Imported 1 entry into “Imported”, totalling -$1.00. '
        '2 entries could not be read and were left in place.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no import, no snack bar', (tester) async {
    await _pumpWith(tester, null);

    expect(find.byType(SnackBar), findsNothing);
  });
}
