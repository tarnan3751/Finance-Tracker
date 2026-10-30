/// The app lock's suppression count (`docs/reference/lock.md`, **Holding the lock
/// open**): the app wraps every trip to another activity it starts itself (Plaid Link, the
/// "Save as" dialog, the share sheet, the camera and the photo picker, the unlock prompt)
/// in [LockHold.holdOpen], and a trip to the background that begins while one is open
/// locks the app on its return only once it has lasted the longer of five minutes
/// (`heldStayBound`) and the "Lock after" timeout. Kept apart from the
/// controller so the features that hold it need no Flutter binding.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_hold.g.dart';

/// The count of external activities open now.
final class LockHold {
  int _open = 0;

  /// Whether an external activity the app started is open.
  bool get isHeld => _open > 0;

  /// Runs [action] with the lock held open, and completes with what it completes with.
  Future<T> holdOpen<T>(Future<T> Function() action) async {
    _open++;
    try {
      return await action();
    } finally {
      _open--;
    }
  }
}

/// The app's one suppression count.
@Riverpod(keepAlive: true)
LockHold lockHold(Ref ref) => LockHold();
