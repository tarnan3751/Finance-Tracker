/// The registration screen (`/register`): email, a password of 8 to 128 characters, an
/// optional name, the name this device registers under, and the failure inline (email
/// taken, too many attempts, no server, another account on this install). A successful
/// registration needs no navigation: the router follows the session to the shell.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/presentation/auth_form.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The registration screen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  bool _busy = false;
  Exception? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
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
    setState(() => _busy = true);
    final String name = _name.text.trim();
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .register(
            email: _email.text.trim(),
            password: _password.text,
            displayName: name.isEmpty ? null : name,
          );
      TextInput.finishAutofillContext();
    } on Exception catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      setState(() {
        _error = e;
        _fieldErrors = fieldErrors(l10n, e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? deviceName = ref.watch(deviceNameProvider).value;
    final Exception? error = _error;
    return AuthFrame(
      title: l10n.registerTitle,
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                autofillHint: AutofillHints.newPassword,
                helperText: l10n.authPasswordHelper,
                validator: (v) => validatePassword(l10n, v),
                errorText: _fieldErrors['password'],
                onChanged: (_) => _clearField('password'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearField('display_name'),
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => validateDisplayName(l10n, v),
                decoration: InputDecoration(
                  labelText: l10n.authDisplayNameLabel,
                  errorText: _fieldErrors['display_name'],
                ),
              ),
            ],
          ),
        ),
        if (deviceName != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.registerDeviceName(deviceName),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          AuthErrorText(authErrorMessage(l10n, error)),
        ],
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: l10n.registerSubmit,
          busyLabel: l10n.registerSubmitting,
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => const SignInRoute().go(context),
          child: Text(l10n.registerHaveAccount),
        ),
      ],
    );
  }
}
