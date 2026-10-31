/// The one-shot read of a repository's stream, for code that needs the current value once
/// (the rules on arrival and on the existing transactions, the bulk actions). Pure Dart.
library;

import 'dart:async';

/// The first value of [stream], the repositories' current one. Unlike `Stream.first` it
/// does not wait for the subscription's cancel, whose future a widget test's fake clock
/// never completes for the in-memory repositories' streams. A stream that ends with
/// nothing emitted (a Drift query stream closed with its database) completes it with a
/// [StateError], as `Stream.first` does.
Future<T> currentValue<T>(Stream<T> stream) {
  final Completer<T> value = Completer<T>();
  late final StreamSubscription<T> subscription;
  subscription = stream.listen(
    (v) {
      if (value.isCompleted) return;
      value.complete(v);
      unawaited(subscription.cancel());
    },
    onError: (Object e, StackTrace s) {
      if (!value.isCompleted) value.completeError(e, s);
    },
    onDone: () {
      if (!value.isCompleted) {
        value.completeError(StateError('the stream ended with no value'));
      }
    },
  );
  return value.future;
}
