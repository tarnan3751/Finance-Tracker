/// The sign-in screen (`/sign-in`): the server's address while none is compiled in
/// (`server_field.dart`, checked before anything is sent), email and password, a link to
/// registration, and the failure inline (wrong credentials, too many attempts, no server,
/// another account on this install). After the server ended this device's session it says so, once. While
/// the install still holds an account's data (its user is recorded), a line under the
/// form offers to erase this device's data (the local wipe, after a confirmation): the
/// way out for an install whose account is gone, deleted elsewhere or by a deletion
/// whose answer was lost. A successful sign-in needs no navigation: the router follows
/// the session to the shell. On an install that chose the live mode on the Welcome screen
/// and holds no account yet, "Try the demo instead" clears the choice and restarts on
/// Welcome (`docs/reference/onboarding.md`).
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/install_user.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/auth/presentation/auth_form.dart';
import 'package:finance_tracker/features/auth/presentation/erase_device_dialog.dart';
import 'package:finance_tracker/features/auth/presentation/server_field.dart';
import 'package:finance_tracker/features/onboarding/presentation/mode_choice.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sign-in screen.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _server = TextEditingController();
  String? _serverError;
  bool _busy = false;
  Exception? _error;
  Map<String, String> _fieldErrors = const {};
  late final bool _endedRemotely;

  @override
  void initState() {
    super.initState();
    _server.text = ref.read(serverAddressProvider).entered?.toString() ?? '';
    // Taken once, as the screen opens.
    _endedRemotely = ref
        .read(sessionControllerProvider.notifier)
        .takeRemoteSignOutNotice();
  }

  @override
  void dispose() {
    _server.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearField(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _error = null;
      _fieldErrors = const {};
    });
    if (!_form.currentState!.validate()) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final String? server = await confirmServer(ref, l10n, _server.text);
      if (server != null) {
        if (mounted) setState(() => _serverError = server);
        return;
      }
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(email: _email.text.trim(), password: _password.text);
      TextInput.finishAutofillContext();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _fieldErrors = fieldErrors(l10n, e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Forgets the live mode chosen on Welcome and starts again there.
  Future<void> _tryDemo() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool stored = await storeChoiceAndRestart(
      context,
      ref,
      (modes) => modes.clear(),
    );
    if (!stored && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Exception? error = _error;
    return AuthFrame(
      title: l10n.signInTitle,
      children: [
        if (_endedRemotely) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.signInRemoteNotice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ref.watch(serverAddressProvider).editable) ...[
                ServerUrlField(
                  controller: _server,
                  errorText: _serverError,
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearField('email'),
                validator: (v) => validateEmail(l10n, v),
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  errorText: _fieldErrors['email'],
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _password,
                autofillHint: AutofillHints.password,
                validator: (v) => validatePassword(l10n, v),
                errorText: _fieldErrors['password'],
                onChanged: (_) => _clearField('password'),
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          AuthErrorText(authErrorMessage(l10n, error)),
        ],
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: l10n.signInSubmit,
          busyLabel: l10n.signInSubmitting,
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => const RegisterRoute().go(context),
          child: Text(l10n.signInCreateAccount),
        ),
        if (ref.watch(installUserProvider).value != null ||
            error is OtherAccountOnDeviceException)
          TextButton(
            onPressed: _busy ? null : () => confirmAndEraseDevice(context, ref),
            child: Text(l10n.signInEraseDevice),
          ),
        if (ref.watch(installUserProvider) case AsyncData(value: null)
            when ref.watch(appConfigProvider).choosesMode)
          TextButton(
            onPressed: _busy ? null : _tryDemo,
            child: Text(l10n.signInTryDemo),
          ),
      ],
    );
  }
}
