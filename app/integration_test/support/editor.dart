// Saving an editor in an integration flow: the editor writes the database (off the UI
// isolate in dev) and closes only once the write lands, and only while it is still the
// top page (core/router/own_page.dart), so a flow waits for it to close before it
// navigates or reads back what it saved. Not a test file itself: the flows import it.
import 'package:flutter_test/flutter_test.dart';

/// How long an editor may take to close, in wall-clock time, on an emulator loaded by
/// several lanes.
const Duration _patience = Duration(seconds: 120);

/// Taps Save on the [editor] screen and pumps until it has closed.
Future<void> saveEditor(WidgetTester tester, Type editor) async {
  final Finder save = find.text('Save');
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
  final Stopwatch waited = Stopwatch()..start();
  while (find.byType(editor).evaluate().isNotEmpty) {
    if (waited.elapsed > _patience) {
      fail('the editor never closed in ${_patience.inSeconds} s');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
