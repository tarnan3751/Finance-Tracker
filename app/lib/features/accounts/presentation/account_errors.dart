/// What the account screens say when the repository refuses an account write: the same
/// snack-bar message for the same typed exception on every screen.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// Runs [write]; when it throws one of the account repositories' typed exceptions, shows
/// its message on [messenger] and returns false. Other errors propagate.
Future<bool> runAccountWrite(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Future<void> Function() write,
) async {
  try {
    await write();
    return true;
  } on CurrencyMismatchException {
    _show(messenger, l10n.accountCurrencyLocked);
  } on EntityDeletedException {
    _show(messenger, l10n.accountDeleted);
  } on AccountNotFoundException {
    _show(messenger, l10n.accountNotFound);
  }
  return false;
}

void _show(ScaffoldMessengerState messenger, String message) =>
    messenger.showSnackBar(SnackBar(content: Text(message)));
