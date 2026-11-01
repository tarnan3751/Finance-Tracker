/// The licences of what the app bundles itself, beside the packages' that Flutter
/// collects on its own, for the licence page Settings → About opens
/// (`docs/reference/onboarding.md`, **About**): the Roboto fonts the PDF report embeds
/// (Apache-2.0) and the Syne and Work Sans fonts the app is set in (OFL-1.1), all under
/// `assets/fonts/`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Roboto fonts' licence file, an asset of every flavor.
const String robotoLicenseAsset = 'assets/fonts/LICENSE.txt';

/// The Syne font's licence file, an asset of every flavor.
const String syneLicenseAsset = 'assets/fonts/Syne-OFL.txt';

/// The Work Sans font's licence file, an asset of every flavor.
const String workSansLicenseAsset = 'assets/fonts/WorkSans-OFL.txt';

bool _registered = false;

/// Adds the bundled fonts' licences to Flutter's [LicenseRegistry], once per process.
void registerBundledLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (String font, String asset) in const [
      ('Roboto', robotoLicenseAsset),
      ('Syne', syneLicenseAsset),
      ('Work Sans', workSansLicenseAsset),
    ]) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(asset));
    }
  });
}
