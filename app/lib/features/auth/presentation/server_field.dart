/// The Server field of the sign-in and registration screens
/// (`docs/reference/onboarding.md`, **The server URL**), shown while no server URL is
/// compiled in (`ServerAddress.editable`): the address of the user's own server, checked
/// as it is typed in ([checkServerUrl]: `https` only in prod), then, on submit and before
/// any other request, answered by `GET /v1/health` ([confirmServer]) and kept on the
/// device for the next start. A compiled URL, or the in-app fake server, hides it.
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/server_address.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/server_check.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The text for [problem].
String serverUrlMessage(AppLocalizations l10n, ServerUrlProblem problem) =>
    switch (problem) {
      ServerUrlProblem.empty => l10n.serverUrlEmpty,
      ServerUrlProblem.invalid => l10n.serverUrlInvalid,
      ServerUrlProblem.notHttps => l10n.serverUrlNotHttps,
    };

/// Makes the server [text] names the one the app talks to: nothing to do while the
/// address is compiled in or already [text]'s; otherwise its health answered, then the
/// address kept and used. Returns null when the app may go on, else what to show.
Future<String?> confirmServer(
  WidgetRef ref,
  AppLocalizations l10n,
  String text,
) async {
  final ServerAddress address = ref.read(serverAddressProvider);
  if (!address.editable) return null;
  final ({Uri? url, ServerUrlProblem? problem}) checked = checkServerUrl(
    text,
    ref.read(appConfigProvider).flavor,
  );
  final Uri? url = checked.url;
  if (url == null) return serverUrlMessage(l10n, checked.problem!);
  if (url == address.entered) return null;
  // Read before the awaits.
  final AppModeStore modes = ref.read(appModeStoreProvider);
  switch (await ref.read(serverCheckProvider).check(url)) {
    case ServerCheckOutcome.ok:
      await modes.writeServerUrl(url);
      address.entered = url;
      return null;
    case ServerCheckOutcome.unreachable:
      return l10n.serverUnreachable;
    case ServerCheckOutcome.notAServer:
      return l10n.serverNotSpendthrift;
  }
}

/// The Server field, over [controller], showing [errorText] (the health check's) until
/// it changes ([onChanged]).
class ServerUrlField extends ConsumerWidget {
  const ServerUrlField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Flavor flavor = ref.watch(appConfigProvider).flavor;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.url,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      validator: (value) {
        final ServerUrlProblem? problem = checkServerUrl(
          value ?? '',
          flavor,
        ).problem;
        return problem == null ? null : serverUrlMessage(l10n, problem);
      },
      decoration: InputDecoration(
        labelText: l10n.serverFieldLabel,
        hintText: l10n.serverFieldHint,
        helperText: l10n.serverFieldHelper,
        errorText: errorText,
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
    );
  }
}
