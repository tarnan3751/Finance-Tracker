// Goldens of the Bills segment, light and dark at phone size, on the bill seed
// (bill_seed.dart) and the test seed: the list with its Overdue, Due soon and Later
// groups and the folded Paused group, the calendar on today's month, and the list with a
// suggestion from the stream seed (stream_seed.dart). Tagged `golden`; see
// test/flutter_test_config.dart for where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/bill_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/stream_seed.dart';

Widget _app(
  Brightness brightness, {
  List<BillReminder>? bills,
  bool streams = false,
}) => SizedBox.fromSize(
  size: phoneSize,
  child: buildTestApp(
    initialLocation: '/bills',
    brightness: brightness,
    overrides: [
      storeOverride(seededStore()),
      billRepositoryProvider.overrideWithValue(
        InMemoryBillRepository(
          testClock,
          recorder: const NoChangeRecorder(),
          initial: bills ?? testBills(),
        ),
      ),
      if (streams) streamsOverride(seededStreams()),
    ],
  ),
);

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the bills list, ${brightness.name}',
      fileName: 'bills_list_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app(brightness),
    );

    goldenTest(
      'the bills calendar, ${brightness.name}',
      fileName: 'bills_calendar_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app(brightness),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Calendar'));
        await tester.pumpAndSettle();
      },
    );

    goldenTest(
      'a bill suggestion, ${brightness.name}',
      fileName: 'bills_suggested_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () =>
          _app(brightness, bills: [testBills().first], streams: true),
    );
  }
}
