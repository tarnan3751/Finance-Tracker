// The developer tools' constant (core/config/dev_tools.dart) as the host tests see it: a
// build with no flavor carries the tools, so the widget tests render the dev flavor's
// Developer section.
import 'package:finance_tracker/core/config/dev_tools.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a build with no flavor carries the tools', () {
    expect(appFlavor, isNull);
    expect(kDevTools, isTrue);
  });
}
