/// The seeded user of one-command startup (`SEED_USER_EMAIL`, `SEED_USER_PASSWORD`).
library;

import 'package:finance_tracker_server/src/auth/password_hasher.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/ids.dart';

/// Creates the user [email] with [password] unless the email is already registered, in
/// which case nothing changes (an existing password is never reset). Returns whether it
/// created the user.
Future<bool> seedUser(
  AppDatabase db,
  PasswordHasher hasher, {
  required String email,
  required String password,
  required DateTime Function() now,
}) async {
  final folded = email.toLowerCase();
  final exists = await db.read(
    (tx) => tx.first('SELECT 1 FROM users WHERE email = ?', [folded]) != null,
  );
  if (exists) return false;
  final hash = await hasher.hash(password);
  return db.transaction((tx) async {
    if (tx.first('SELECT 1 FROM users WHERE email = ?', [folded]) != null) {
      return false;
    }
    tx.execute(
      'INSERT INTO users (id, email, password_hash, display_name, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [
        newId(),
        folded,
        hash,
        folded.substring(0, folded.indexOf('@')),
        now().millisecondsSinceEpoch,
      ],
    );
    return true;
  });
}
