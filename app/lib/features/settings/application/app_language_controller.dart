/// The language the app is shown in on this device (`domain/app_language.dart`), read
/// from and saved to `app_meta`. Choosing English or the pseudo-locale also formats
/// amounts and dates in `en_US` (intl has no data for the pseudo-locale); choosing the
/// device's language again formats them in the device's locale, as `bootstrap` does at
/// start.
library;

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/settings/domain/app_language.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_language_controller.g.dart';

/// The language choice, with [set] to change it.
@Riverpod(keepAlive: true)
class AppLanguageController extends _$AppLanguageController {
  @override
  Future<AppLanguage> build() async {
    final AppLanguage language = AppLanguage.parse(
      await ref.watch(appMetaStoreProvider).read(AppMetaKeys.appLanguage),
    );
    if (language != AppLanguage.system) _formatIn(language);
    return language;
  }

  /// Shows the app in [language] from now on, on this device.
  Future<void> set(AppLanguage language) async {
    await ref
        .read(appMetaStoreProvider)
        .write(AppMetaKeys.appLanguage, language.name);
    _formatIn(language);
    state = AsyncData(language);
  }

  static void _formatIn(AppLanguage language) => Intl.defaultLocale =
      language == AppLanguage.system ? deviceLocale() : 'en_US';
}
