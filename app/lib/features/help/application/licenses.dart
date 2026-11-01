/// The licences of what the app bundles itself, beside the packages' that Flutter
/// collects on its own, for the licence page Settings → About opens
/// (`docs/reference/onboarding.md`, **About**): the Roboto fonts the PDF report embeds
/// (`assets/fonts/`, Apache-2.0).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Roboto fonts' licence file, an asset of every flavor.
const String robotoLicenseAsset = 'assets/fonts/LICENSE.txt';

bool _registered = false;

/// Adds the bundled fonts' licence to Flutter's [LicenseRegistry], once per process.
void registerBundledLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Roboto',
    ], await rootBundle.loadString(robotoLicenseAsset));
  });
}
