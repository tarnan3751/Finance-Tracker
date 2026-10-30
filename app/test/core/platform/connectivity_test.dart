// The connectivity seam's fake: the state a test sets, each change delivered.
import 'package:finance_tracker/core/platform/fake_connectivity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the fake reports and delivers what the test sets', () async {
    final FakeConnectivity network = FakeConnectivity();
    final List<bool> seen = [];
    network.changes.listen(seen.add);
    expect(await network.isOnline(), isTrue);
    network
      ..set(false)
      ..set(true);
    await Future<void>.delayed(Duration.zero);
    expect(seen, [false, true]);
    expect(await network.isOnline(), isTrue);
    await network.close();
  });
}
