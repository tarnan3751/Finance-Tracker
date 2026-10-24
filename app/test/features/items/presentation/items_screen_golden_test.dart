// Goldens of the linked banks screen, light and dark at phone size: the three test banks
// (connected, needing attention, in error) and the empty state. Tagged `golden`; see
// test/flutter_test_config.dart for where the files go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Widget _app(Brightness brightness, {required bool banks}) {
  final InMemoryStore store = seededStore();
  if (banks) store.applyPlaidItems(testBanks, testClock.nowUtc());
  return SizedBox.fromSize(
    size: phoneSize,
    child: buildTestApp(
      initialLocation: '/accounts/linked-banks',
      brightness: brightness,
      overrides: [storeOverride(store)],
    ),
  );
}

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the linked banks, ${brightness.name}',
      fileName: 'items_list_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app(brightness, banks: true),
    );
    goldenTest(
      'no linked banks, ${brightness.name}',
      fileName: 'items_empty_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app(brightness, banks: false),
    );
  }
}
