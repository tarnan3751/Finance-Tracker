/// What each help section says (`docs/reference/onboarding.md`, **Help**): its title and
/// its body as headings, paragraphs and bullets (`help_widgets.dart`), one ARB message
/// per block, so the text is translated like the rest of the app.
library;

import 'package:finance_tracker/features/help/domain/help_section.dart';
import 'package:finance_tracker/features/help/presentation/help_widgets.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The title of [section].
String helpSectionTitle(AppLocalizations l10n, HelpSection section) =>
    switch (section) {
      HelpSection.gettingStarted => l10n.helpStartTitle,
      HelpSection.accounts => l10n.helpAccountsTitle,
      HelpSection.transactions => l10n.helpTransactionsTitle,
      HelpSection.budgets => l10n.helpBudgetsTitle,
      HelpSection.bills => l10n.helpBillsTitle,
      HelpSection.forecast => l10n.helpForecastTitle,
      HelpSection.insights => l10n.helpInsightsTitle,
      HelpSection.sync => l10n.helpSyncTitle,
      HelpSection.backupSecurity => l10n.helpBackupTitle,
      HelpSection.widgets => l10n.helpWidgetsTitle,
      HelpSection.notifications => l10n.helpNotificationsTitle,
    };

/// The body of [section].
List<Widget> helpSectionBody(AppLocalizations l10n, HelpSection section) =>
    switch (section) {
      HelpSection.gettingStarted => [
        HelpParagraph(l10n.helpStart1),
        HelpHeading(l10n.helpStart2),
        HelpBullets([l10n.helpStart3, l10n.helpStart4]),
        HelpHeading(l10n.helpStart5),
        HelpParagraph(l10n.helpStart6),
        HelpParagraph(l10n.helpStart7),
        HelpHeading(l10n.helpStart8),
        HelpParagraph(l10n.helpStart9),
      ],
      HelpSection.accounts => [
        HelpParagraph(l10n.helpAccounts1),
        HelpHeading(l10n.helpAccounts2),
        HelpParagraph(l10n.helpAccounts3),
        HelpHeading(l10n.helpAccounts4),
        HelpParagraph(l10n.helpAccounts5),
        HelpBullets([
          l10n.helpAccounts6,
          l10n.helpAccounts7,
          l10n.helpAccounts8,
        ]),
      ],
      HelpSection.transactions => [
        HelpParagraph(l10n.helpTransactions1),
        HelpHeading(l10n.helpTransactions2),
        HelpBullets([l10n.helpTransactions3, l10n.helpTransactions4]),
        HelpHeading(l10n.helpTransactions5),
        HelpBullets([l10n.helpTransactions6, l10n.helpTransactions7]),
        HelpHeading(l10n.helpTransactions8),
        HelpParagraph(l10n.helpTransactions9),
        HelpHeading(l10n.helpTransactions10),
        HelpParagraph(l10n.helpTransactions11),
      ],
      HelpSection.budgets => [
        HelpParagraph(l10n.helpBudgets1),
        HelpBullets([l10n.helpBudgets2, l10n.helpBudgets3, l10n.helpBudgets4]),
        HelpParagraph(l10n.helpBudgets5),
      ],
      HelpSection.bills => [
        HelpParagraph(l10n.helpBills1),
        HelpBullets([l10n.helpBills2, l10n.helpBills3, l10n.helpBills4]),
        HelpHeading(l10n.helpBills5),
        HelpParagraph(l10n.helpBills6),
      ],
      HelpSection.forecast => [
        HelpParagraph(l10n.helpForecast1),
        HelpBullets([l10n.helpForecast2, l10n.helpForecast3]),
        HelpParagraph(l10n.helpForecast4),
      ],
      HelpSection.insights => [
        HelpParagraph(l10n.helpInsights1),
        HelpBullets([
          l10n.helpInsights2,
          l10n.helpInsights3,
          l10n.helpInsights4,
          l10n.helpInsights5,
        ]),
        HelpParagraph(l10n.helpInsights6),
      ],
      HelpSection.sync => [
        HelpParagraph(l10n.helpSync1),
        HelpBullets([l10n.helpSync2, l10n.helpSync3, l10n.helpSync4]),
        HelpParagraph(l10n.helpSync5),
      ],
      HelpSection.backupSecurity => [
        HelpHeading(l10n.helpBackup1),
        HelpParagraph(l10n.helpBackup2),
        HelpHeading(l10n.helpBackup3),
        HelpParagraph(l10n.helpBackup4),
        HelpHeading(l10n.helpBackup5),
        HelpBullets([l10n.helpBackup6, l10n.helpBackup7, l10n.helpBackup8]),
      ],
      HelpSection.widgets => [
        HelpParagraph(l10n.helpWidgets1),
        HelpBullets([l10n.helpWidgets2, l10n.helpWidgets3]),
      ],
      HelpSection.notifications => [
        HelpParagraph(l10n.helpNotifications1),
        HelpBullets([l10n.helpNotifications2, l10n.helpNotifications3]),
        HelpHeading(l10n.helpNotifications4),
        HelpParagraph(l10n.helpNotifications5),
      ],
    };
