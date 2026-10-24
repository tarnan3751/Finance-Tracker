/// The system categories: one per Plaid primary category and one per detailed category,
/// seeded by every `CategoryRepository.ensureSeeded` (`PLAN.md` §6.2, §12 taxonomy row).
///
/// Ids are `plaid:<PRIMARY>` and `plaid:<DETAILED>`. Names come from the codes in sentence
/// case, the primary prefix dropped from a detailed code (`FOOD_AND_DRINK_GROCERIES` is
/// "Groceries" under "Food and drink"), with [_nameOverrides] for acronyms and
/// punctuation. Each primary has an icon (a key into the app's icon set: a Material icon
/// name, mapped to an `IconData` by the UI) and an ARGB color, which its detailed
/// categories share. Names are English; a localized display can key off `plaidCategory`.
library;

import 'package:shared_models/shared_models.dart';

/// The icon key and ARGB color of each primary category.
const Map<String, ({String icon, int color})> primaryCategoryStyles = {
  'INCOME': (icon: 'payments', color: 0xFF2E7D32),
  'LOAN_DISBURSEMENTS': (icon: 'account_balance', color: 0xFF00695C),
  'LOAN_PAYMENTS': (icon: 'credit_score', color: 0xFF4527A0),
  'TRANSFER_IN': (icon: 'call_received', color: 0xFF0277BD),
  'TRANSFER_OUT': (icon: 'call_made', color: 0xFF01579B),
  'BANK_FEES': (icon: 'receipt_long', color: 0xFFC62828),
  'ENTERTAINMENT': (icon: 'movie', color: 0xFF6A1B9A),
  'FOOD_AND_DRINK': (icon: 'restaurant', color: 0xFFEF6C00),
  'GENERAL_MERCHANDISE': (icon: 'shopping_bag', color: 0xFFAD1457),
  'HOME_IMPROVEMENT': (icon: 'home_repair_service', color: 0xFF5D4037),
  'MEDICAL': (icon: 'medical_services', color: 0xFFD32F2F),
  'PERSONAL_CARE': (icon: 'spa', color: 0xFFC2185B),
  'GENERAL_SERVICES': (icon: 'build', color: 0xFF455A64),
  'GOVERNMENT_AND_NON_PROFIT': (icon: 'volunteer_activism', color: 0xFF283593),
  'TRANSPORTATION': (icon: 'directions_car', color: 0xFF1565C0),
  'TRAVEL': (icon: 'flight', color: 0xFF00838F),
  'RENT_AND_UTILITIES': (icon: 'house', color: 0xFF6D4C41),
  'OTHER': (icon: 'category', color: 0xFF616161),
};

const Map<String, String> _nameOverrides = {
  'GOVERNMENT_AND_NON_PROFIT': 'Government and non-profit',
  'GOVERNMENT_AND_NON_PROFIT_OTHER_GOVERNMENT_AND_NON_PROFIT':
      'Other government and non-profit',
  'BANK_FEES_ATM_FEES': 'ATM fees',
  'ENTERTAINMENT_TV_AND_MOVIES': 'TV and movies',
  'ENTERTAINMENT_SPORTING_EVENTS_AMUSEMENT_PARKS_AND_MUSEUMS':
      'Sporting events, amusement parks and museums',
  'FOOD_AND_DRINK_BEER_WINE_AND_LIQUOR': 'Beer, wine and liquor',
  'INCOME_LONG_TERM_DISABILITY': 'Long-term disability',
  'LOAN_DISBURSEMENTS_EWA': 'Earned wage access',
  'LOAN_PAYMENTS_EWA': 'Earned wage access',
  'LOAN_PAYMENTS_BNPL': 'Buy now, pay later',
};

/// The id of the system category seeded from Plaid code [code].
String systemCategoryId(String code) => 'plaid:$code';

/// Every system category: each primary, followed by its detailed categories, in the order
/// Plaid publishes them.
final List<Category> systemCategories = _buildSystemCategories();

List<Category> _buildSystemCategories() {
  final List<Category> categories = [];
  for (final String primary in plaidPrimaryCategories) {
    final ({String icon, int color}) style = primaryCategoryStyles[primary]!;
    categories.add(
      Category(
        id: systemCategoryId(primary),
        name: _nameOverrides[primary] ?? _sentenceCase(primary),
        isSystem: true,
        icon: style.icon,
        color: style.color,
        plaidCategory: primary,
      ),
    );
    for (final PlaidCategory detailed in plaidCategories) {
      if (detailed.primary != primary) continue;
      categories.add(
        Category(
          id: systemCategoryId(detailed.detailed),
          name:
              _nameOverrides[detailed.detailed] ??
              _sentenceCase(detailed.detailed.substring(primary.length + 1)),
          parentId: systemCategoryId(primary),
          isSystem: true,
          icon: style.icon,
          color: style.color,
          plaidCategory: detailed.detailed,
        ),
      );
    }
  }
  return List.unmodifiable(categories);
}

String _sentenceCase(String code) {
  final String words = code.replaceAll('_', ' ').toLowerCase();
  return words[0].toUpperCase() + words.substring(1);
}
