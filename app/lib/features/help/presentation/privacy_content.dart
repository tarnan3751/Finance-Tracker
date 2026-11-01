/// What the privacy page says (`docs/reference/onboarding.md`, **Privacy**), block by
/// block, one ARB message each. `PRIVACY.md` at the repository's root carries the same
/// text as Markdown; `test/features/help/privacy_parity_test.dart` keeps them equal.
library;

import 'package:finance_tracker/features/help/presentation/help_widgets.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The privacy page's body.
List<Widget> privacyBody(AppLocalizations l10n) => [
  HelpParagraph(l10n.privacy1),
  HelpHeading(l10n.privacy2),
  HelpParagraph(l10n.privacy3),
  HelpBullets([
    l10n.privacy4,
    l10n.privacy5,
    l10n.privacy6,
    l10n.privacy7,
    l10n.privacy8,
    l10n.privacy9,
  ]),
  HelpParagraph(l10n.privacy10),
  HelpHeading(l10n.privacy11),
  HelpBullets([
    l10n.privacy12,
    l10n.privacy13,
    l10n.privacy14,
    l10n.privacy15,
    l10n.privacy16,
    l10n.privacy17,
  ]),
  HelpHeading(l10n.privacy18),
  HelpParagraph(l10n.privacy19),
];
