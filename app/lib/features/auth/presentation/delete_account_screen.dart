/// Delete account (`/settings/delete-account`): what deleting does (every linked bank
/// disconnected at Plaid, every server record deleted, this device wiped, the other
/// devices signed out), the account's email typed to confirm (trimmed, case aside), then
/// `DELETE /me` and, on its 204, the local wipe with its confirmation
/// (`account_actions.dart`). A failed deletion changes nothing local and says why, inline,
/// with the button left to try again.
library;

import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/features/auth/application/account_actions.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/auth/presentation/auth_form.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [typed] confirms [email]: the same address, trimmed, in any case.
bool confirmsEmail(String typed, String email) =>
    typed.trim().toLowerCase() == email.trim().toLowerCase();

/// The text for a deletion that failed with [error].
String deletionErrorMessage(AppLocalizations l10n, Object error) =>
    l10n.deleteAccountFailed(switch (error) {
      PlaidError() => l10n.deleteAccountFailedPlaid,
      NetworkError() => l10n.deleteAccountFailedNetwork,
      _ => l10n.deleteAccountFailedOther,
    });

/// The delete account screen.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _typed = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final AccountActions actions = ref.read(accountActionsProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the app is stopped under this screen: nothing follows.
      await actions.deleteAccount();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final SessionState session = ref.watch(sessionControllerProvider);
    final String email = session is SignedIn ? session.user.email : '';
    final bool confirmed =
        email.isNotEmpty && confirmsEmail(_typed.text, email);
    final Object? error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.deleteAccountIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            for (final String effect in [
              l10n.deleteAccountEffectBanks,
              l10n.deleteAccountEffectServer,
              l10n.deleteAccountEffectDevice,
              l10n.deleteAccountEffectOthers,
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(effect),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteAccountPermanent,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typed,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.deleteAccountConfirmLabel,
                helperText: l10n.deleteAccountConfirmHelper(email),
                helperMaxLines: 2,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              AuthErrorText(deletionErrorMessage(l10n, error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: confirmed && !_busy ? _delete : null,
              child: _busy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onError,
                        semanticsLabel: l10n.deleteAccountDeleting,
                      ),
                    )
                  : Text(l10n.deleteAccountSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
