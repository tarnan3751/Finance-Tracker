/// A first-in, first-out asynchronous lock.
library;

/// Runs bodies one at a time, in the order [run] was called. A body that throws releases
/// the lock and its error reaches only its own caller.
final class Mutex {
  Future<void> _tail = Future<void>.value();

  /// Runs [body] once every earlier body has finished.
  Future<T> run<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
