// The restore offer settled for a test: answered (an install past it, whose sync runs)
// or pending (a fresh install held at /restore), whatever the database holds.
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An install that answered the restore offer.
final class AnsweredRestoreOffer extends RestoreOffer {
  @override
  Future<bool> build() async => false;
}

/// A fresh install holding the offer until [answer].
final class PendingRestoreOffer extends RestoreOffer {
  @override
  Future<bool> build() async => true;

  @override
  Future<void> answer() async => state = const AsyncData(false);
}
