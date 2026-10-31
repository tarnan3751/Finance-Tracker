// currentValue: the first value of a stream, the subscription cancelled after it; an
// error before any value fails it; and a stream that ends with nothing emitted fails it
// with a StateError rather than leaving it pending.
import 'dart:async';

import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the first value', () async {
    final StreamController<int> c = StreamController<int>();
    final Future<int> v = currentValue(c.stream);
    c
      ..add(1)
      ..add(2);
    expect(await v, 1);
    await c.close();
  });

  test('an error before any value', () async {
    final StreamController<int> c = StreamController<int>();
    final Future<int> v = currentValue(c.stream);
    c.addError(const FormatException('bad'));
    await expectLater(v, throwsFormatException);
    await c.close();
  });

  test('a stream that closes unheard', () async {
    final StreamController<int> c = StreamController<int>();
    final Future<int> v = currentValue(c.stream);
    await c.close();
    await expectLater(v, throwsStateError);
  });
}
