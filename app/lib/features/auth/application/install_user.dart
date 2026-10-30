/// The install's user (`docs/reference/auth.md`, **One user per install**) as the auth
/// screens see it: while one is recorded, this install still holds that account's data,
/// so the sign-in screen offers to erase it.
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'install_user.g.dart';

/// The id of the user this install's data belongs to, or null; read afresh by each
/// screen that watches it. A marker that cannot be read is an error.
@riverpod
Future<String?> installUser(Ref ref) =>
    ref.watch(tokenStoreProvider).readInstallUserId();
