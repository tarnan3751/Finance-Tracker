/// What the app shows while the local wipe runs with the app stopped (`bootstrap`'s
/// wipe, `core/db/local_wipe.dart`): a plain screen saying the data is being erased; then
/// the confirmation, whose Done starts the app again on the fresh install; or, when the
/// wipe failed, that it did and Try again, which runs it again. The app never starts on
/// a wipe that did not finish. One that keeps failing (the second failure in a row, or
/// any failure of a wipe resumed at startup) also points at Android's storage settings,
/// since a storage that refuses every time cannot be mended from inside the app.
library;

import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// The wipe's state as the screen shows it.
sealed class ErasingState {
  const ErasingState();
}

/// The wipe is running.
final class Erasing extends ErasingState {
  const Erasing();
}

/// The wipe failed; [onRetry] runs it again. [repeated] when it failed before in this
/// process, or was resumed at startup: a wipe that keeps failing.
final class EraseFailed extends ErasingState {
  const EraseFailed(this.onRetry, {this.repeated = false});

  final VoidCallback onRetry;
  final bool repeated;
}

/// The wipe finished; [onDone] starts the app again.
final class Erased extends ErasingState {
  const Erased(this.onDone);

  final VoidCallback onDone;
}

/// The erasing screen's app, following [state], for a wipe run for [reason].
class ErasingApp extends StatelessWidget {
  const ErasingApp({required this.state, required this.reason, super.key});

  /// The wipe's state.
  final ValueNotifier<ErasingState> state;

  /// Why the data is wiped.
  final WipeReason reason;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<ErasingState>(
              valueListenable: state,
              builder: (context, value, _) {
                final AppLocalizations l10n = AppLocalizations.of(context);
                final TextTheme text = Theme.of(context).textTheme;
                final (String title, String? body) = switch (value) {
                  Erasing() => (l10n.erasingTitle, null),
                  EraseFailed(:final repeated) => (
                    l10n.eraseFailedTitle,
                    l10n.eraseFailedBody(repeated.toString()),
                  ),
                  Erased() => switch (reason) {
                    WipeReason.accountDeleted => (
                      l10n.erasedAccountTitle,
                      l10n.erasedAccountBody,
                    ),
                    WipeReason.deviceErased => (
                      l10n.erasedDeviceTitle,
                      l10n.erasedDeviceBody,
                    ),
                  },
                };
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        title,
                        style: text.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (body != null) ...[
                      Text(
                        body,
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                    switch (value) {
                      Erasing() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      EraseFailed(:final onRetry) => FilledButton(
                        onPressed: onRetry,
                        child: Text(l10n.eraseTryAgain),
                      ),
                      Erased(:final onDone) => FilledButton(
                        onPressed: onDone,
                        child: Text(l10n.erasedDone),
                      ),
                    },
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
