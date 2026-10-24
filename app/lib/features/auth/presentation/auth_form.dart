/// What the sign-in and registration screens share: the field rules (the contract's:
/// an email address, a password of 8 to 128 characters, an optional name of at most 100),
/// the password field with its show and hide button, the inline error, and the text for
/// each way a submission can fail.
library;

import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

final RegExp _email = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

/// The email rule, or null when [value] passes.
String? validateEmail(AppLocalizations l10n, String? value) =>
    _email.hasMatch((value ?? '').trim()) ? null : l10n.authEmailInvalid;

/// The password rule, counted in characters as the server counts them.
String? validatePassword(AppLocalizations l10n, String? value) {
  final int length = (value ?? '').runes.length;
  if (length == 0) return l10n.authPasswordRequired;
  return length < 8 || length > 128 ? l10n.authPasswordLength : null;
}

/// The optional display name's rule.
String? validateDisplayName(AppLocalizations l10n, String? value) =>
    (value ?? '').trim().runes.length > 100 ? l10n.authDisplayNameLength : null;

/// The text for a failed sign-in or registration.
String authErrorMessage(AppLocalizations l10n, Exception error) =>
    switch (error) {
      InvalidCredentials() => l10n.authErrorInvalidCredentials,
      RateLimited(:final Duration? retryAfter) =>
        retryAfter == null || retryAfter.inSeconds < 1
            ? l10n.authErrorRateLimitedLater
            : l10n.authErrorRateLimited(retryAfter.inSeconds),
      EmailTaken() => l10n.authErrorEmailTaken,
      NetworkError() => l10n.authErrorNetwork,
      ValidationFailed() => l10n.authErrorValidation,
      OtherAccountOnDeviceException() => l10n.authErrorOtherAccount,
      _ => l10n.authErrorGeneric,
    };

/// The field-by-field text for a refused submission: the server's field names mapped to
/// this screen's own rules.
Map<String, String> fieldErrors(AppLocalizations l10n, Exception error) {
  if (error is! ValidationFailed) return const {};
  final Map<String, String> rules = {
    'email': l10n.authEmailInvalid,
    'password': l10n.authPasswordLength,
    'display_name': l10n.authDisplayNameLength,
  };
  return {
    for (final FieldError f in error.errors)
      if (rules[f.field] case final String text) f.field: text,
  };
}

/// A password field with a button that shows or hides it.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    required this.autofillHint,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String autofillHint;
  final String? helperText;

  /// An error from the server, shown until the field changes.
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [widget.autofillHint],
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: l10n.authPasswordLabel,
        helperText: widget.helperText,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: _obscured ? l10n.authShowPassword : l10n.authHidePassword,
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

/// A submission's error, announced to screen readers when it appears.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// The submit button: its label, or a progress indicator labelled [busyLabel].
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.busyLabel,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final String busyLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    child: busy
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: busyLabel,
            ),
          )
        : Text(label),
  );
}

/// The screens' frame: a scrolling column at most 480 wide.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
