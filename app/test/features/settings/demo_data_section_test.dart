// The settings screen's Demo data section: shown in the demo flavor only, with the
// current persona selected, and choosing one switches the demo's persona.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the demo flavor chooses its household here', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      config: AppConfig.demo(),
      // Tall enough for the whole screen, the Security section included.
      size: const Size(412, 2200),
    );
    expect(find.text('Demo data'), findsOneWidget);
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.text('Demo data')),
    );
    expect(container.read(demoPersonaProvider), PersonaId.renter);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(container.read(demoPersonaProvider), PersonaId.family);
    final RadioGroup<PersonaId> group = tester.widget(
      find.byType(RadioGroup<PersonaId>),
    );
    expect(group.groupValue, PersonaId.family);
  });

  testWidgets('dev and prod have no Demo data section', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      size: const Size(412, 1600),
    );
    expect(find.text('Demo data'), findsNothing);
  });
}
