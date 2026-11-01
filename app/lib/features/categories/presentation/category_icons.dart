/// The icons a category can wear: about forty Material icons, each with the key stored in
/// `Category.icon` (the Material icon's name) and an accessibility label. The system
/// categories' keys (`category_defaults.dart`) are all here; a key that is not, written by
/// a later version or another device, shows [fallbackCategoryIcon].
///
/// A category's color as drawn ([categoryColorOf]): a system category still in its
/// default taxonomy color takes one of the brand's eight hues (`brand_hues.dart`,
/// derived from the inks, assigned so that neighbouring top-level categories differ,
/// with lifted variants on the night print); any other color, one the user chose, stays
/// as chosen, lightened in the dark theme and harmonized with the scheme's primary
/// (`FinanceColors.custom`). The icon, the budget card and the report's slice all draw it,
/// so a category reads the same everywhere. [CategoryIconDisc] is the icon on a disc of
/// the color's tint over `surfaceContainer`, the icon in the color's text-safe variant.
library;

import 'package:finance_tracker/core/theme/brand_hues.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// A choosable category icon.
typedef CategoryIconOption = ({
  String key,
  IconData icon,
  String Function(AppLocalizations) label,
});

/// The curated icons, in the order the editor shows them.
const List<CategoryIconOption> categoryIcons = [
  (key: 'payments', icon: Icons.payments, label: _lPayments),
  (
    key: 'account_balance',
    icon: Icons.account_balance,
    label: _lAccountBalance,
  ),
  (key: 'credit_score', icon: Icons.credit_score, label: _lCreditScore),
  (key: 'call_received', icon: Icons.call_received, label: _lCallReceived),
  (key: 'call_made', icon: Icons.call_made, label: _lCallMade),
  (key: 'receipt_long', icon: Icons.receipt_long, label: _lReceiptLong),
  (key: 'movie', icon: Icons.movie, label: _lMovie),
  (key: 'restaurant', icon: Icons.restaurant, label: _lRestaurant),
  (key: 'shopping_bag', icon: Icons.shopping_bag, label: _lShoppingBag),
  (
    key: 'home_repair_service',
    icon: Icons.home_repair_service,
    label: _lHomeRepairService,
  ),
  (
    key: 'medical_services',
    icon: Icons.medical_services,
    label: _lMedicalServices,
  ),
  (key: 'spa', icon: Icons.spa, label: _lSpa),
  (key: 'build', icon: Icons.build, label: _lBuild),
  (
    key: 'volunteer_activism',
    icon: Icons.volunteer_activism,
    label: _lVolunteerActivism,
  ),
  (key: 'directions_car', icon: Icons.directions_car, label: _lDirectionsCar),
  (key: 'flight', icon: Icons.flight, label: _lFlight),
  (key: 'house', icon: Icons.house, label: _lHouse),
  (key: 'category', icon: Icons.category, label: _lCategory),
  (
    key: 'local_grocery_store',
    icon: Icons.local_grocery_store,
    label: _lLocalGroceryStore,
  ),
  (key: 'local_cafe', icon: Icons.local_cafe, label: _lLocalCafe),
  (key: 'local_bar', icon: Icons.local_bar, label: _lLocalBar),
  (key: 'fastfood', icon: Icons.fastfood, label: _lFastfood),
  (
    key: 'local_gas_station',
    icon: Icons.local_gas_station,
    label: _lLocalGasStation,
  ),
  (key: 'directions_bus', icon: Icons.directions_bus, label: _lDirectionsBus),
  (key: 'train', icon: Icons.train, label: _lTrain),
  (key: 'school', icon: Icons.school, label: _lSchool),
  (key: 'child_care', icon: Icons.child_care, label: _lChildCare),
  (key: 'pets', icon: Icons.pets, label: _lPets),
  (key: 'fitness_center', icon: Icons.fitness_center, label: _lFitnessCenter),
  (key: 'sports_esports', icon: Icons.sports_esports, label: _lSportsEsports),
  (key: 'music_note', icon: Icons.music_note, label: _lMusicNote),
  (key: 'menu_book', icon: Icons.menu_book, label: _lMenuBook),
  (key: 'phone_iphone', icon: Icons.phone_iphone, label: _lPhoneIphone),
  (key: 'wifi', icon: Icons.wifi, label: _lWifi),
  (key: 'bolt', icon: Icons.bolt, label: _lBolt),
  (key: 'water_drop', icon: Icons.water_drop, label: _lWaterDrop),
  (key: 'savings', icon: Icons.savings, label: _lSavings),
  (key: 'card_giftcard', icon: Icons.card_giftcard, label: _lCardGiftcard),
  (key: 'checkroom', icon: Icons.checkroom, label: _lCheckroom),
  (key: 'celebration', icon: Icons.celebration, label: _lCelebration),
];

/// The icon shown for a category whose key is not in [categoryIcons], and for no category.
const IconData fallbackCategoryIcon = Icons.label_outline;

final Map<String, IconData> _byKey = {
  for (final CategoryIconOption option in categoryIcons)
    option.key: option.icon,
};

/// The icon of key [key].
IconData categoryIconFor(String key) => _byKey[key] ?? fallbackCategoryIcon;

/// A category's stored ARGB [color] as drawn in [context]'s theme: as stored in the light
/// theme, and lightened in the dark one, where the deep stored colors would vanish.
Color categoryColor(BuildContext context, int color) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(Color(color), Colors.white, 0.45)!
    : Color(color);

/// The default taxonomy's colors (`category_defaults.dart`, one per Plaid primary, which
/// its detailed categories share) and the palette hue each takes, assigned so that
/// neighbours differ both in Plaid's order and by name.
const Map<int, int> _defaultHue = {
  0xFF2E7D32: 3, // Income: green
  0xFF00695C: 5, // Loan disbursements: teal
  0xFF4527A0: 4, // Loan payments: violet
  0xFF0277BD: 0, // Transfer in: blue
  0xFF01579B: 4, // Transfer out: violet
  0xFFC62828: 7, // Bank fees: plum
  0xFF6A1B9A: 4, // Entertainment: violet
  0xFFEF6C00: 6, // Food and drink: orange
  0xFFAD1457: 1, // General merchandise: pink
  0xFF5D4037: 2, // Home improvement: yellow
  0xFFD32F2F: 7, // Medical: plum
  0xFFC2185B: 1, // Personal care: pink
  0xFF455A64: 5, // General services: teal
  0xFF283593: 4, // Government and non-profit: violet
  0xFF1565C0: 0, // Transportation: blue
  0xFF00838F: 5, // Travel: teal
  0xFF6D4C41: 2, // Rent and utilities: yellow
  0xFF616161: 0, // Other: blue
};

/// The brand hue (`brand_hues.dart`) of [category] when it is a system category still in
/// its default color, else null.
int? _hueOf(Category category) =>
    category.isSystem ? _defaultHue[category.color] : null;

/// [category]'s color as every screen draws it: the brand hue for a system category still
/// in its default color, else the stored color as [categoryColor] draws it, harmonized
/// with the scheme's primary.
Color categoryColorOf(BuildContext context, Category category) {
  if (_hueOf(category) case final int hue) {
    return brandHue(hue, Theme.of(context).brightness);
  }
  return FinanceColors.of(context)
      .custom(categoryColor(context, category.color));
}

/// [category]'s icon in its color on a disc of the color's tint over the scheme's
/// `surfaceContainer`; the fallback icon in the outline for no category. The icon takes
/// the hue's text-safe variant (`brandHueText`), and a color the user chose is darkened on
/// paper or lifted on the night print until it reaches 3:1 on its disc, as a meaningful
/// graphic must. Decorative: the category's name is written beside it.
class CategoryIconDisc extends StatelessWidget {
  const CategoryIconDisc(this.category, {super.key, this.radius = 20});

  /// The category, or null for none (a deleted or unknown one).
  final Category? category;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Category? category = this.category;
    final Color color = category == null
        ? scheme.outline
        : categoryColorOf(context, category);
    final Color disc = hueTint(color, scheme);
    final int? hue = category == null ? null : _hueOf(category);
    final Color ink = hue != null
        ? brandHueTextOn(hue, theme.brightness)
        : category == null
        ? color
        : readableOn(color, disc, theme.brightness);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: disc),
        child: SizedBox.square(
          dimension: radius * 2,
          child: Icon(
            category == null
                ? fallbackCategoryIcon
                : categoryIconFor(category.icon),
            color: ink,
            size: radius,
          ),
        ),
      ),
    );
  }
}

/// [color], darkened on paper ([brightness] light) or lifted on the night print in steps
/// of its lightness until it reaches 3:1 against [background].
Color readableOn(Color color, Color background, Brightness brightness) {
  HSLColor hsl = HSLColor.fromColor(color);
  Color shown = color;
  final double step = brightness == Brightness.light ? -0.02 : 0.02;
  while (_contrast(shown, background) < 3 &&
      hsl.lightness + step >= 0 &&
      hsl.lightness + step <= 1) {
    hsl = hsl.withLightness(hsl.lightness + step);
    shown = hsl.toColor();
  }
  return shown;
}

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

String _lPayments(AppLocalizations l) => l.categoryIconPayments;
String _lAccountBalance(AppLocalizations l) => l.categoryIconAccountBalance;
String _lCreditScore(AppLocalizations l) => l.categoryIconCreditScore;
String _lCallReceived(AppLocalizations l) => l.categoryIconCallReceived;
String _lCallMade(AppLocalizations l) => l.categoryIconCallMade;
String _lReceiptLong(AppLocalizations l) => l.categoryIconReceiptLong;
String _lMovie(AppLocalizations l) => l.categoryIconMovie;
String _lRestaurant(AppLocalizations l) => l.categoryIconRestaurant;
String _lShoppingBag(AppLocalizations l) => l.categoryIconShoppingBag;
String _lHomeRepairService(AppLocalizations l) =>
    l.categoryIconHomeRepairService;
String _lMedicalServices(AppLocalizations l) => l.categoryIconMedicalServices;
String _lSpa(AppLocalizations l) => l.categoryIconSpa;
String _lBuild(AppLocalizations l) => l.categoryIconBuild;
String _lVolunteerActivism(AppLocalizations l) =>
    l.categoryIconVolunteerActivism;
String _lDirectionsCar(AppLocalizations l) => l.categoryIconDirectionsCar;
String _lFlight(AppLocalizations l) => l.categoryIconFlight;
String _lHouse(AppLocalizations l) => l.categoryIconHouse;
String _lCategory(AppLocalizations l) => l.categoryIconCategory;
String _lLocalGroceryStore(AppLocalizations l) =>
    l.categoryIconLocalGroceryStore;
String _lLocalCafe(AppLocalizations l) => l.categoryIconLocalCafe;
String _lLocalBar(AppLocalizations l) => l.categoryIconLocalBar;
String _lFastfood(AppLocalizations l) => l.categoryIconFastfood;
String _lLocalGasStation(AppLocalizations l) => l.categoryIconLocalGasStation;
String _lDirectionsBus(AppLocalizations l) => l.categoryIconDirectionsBus;
String _lTrain(AppLocalizations l) => l.categoryIconTrain;
String _lSchool(AppLocalizations l) => l.categoryIconSchool;
String _lChildCare(AppLocalizations l) => l.categoryIconChildCare;
String _lPets(AppLocalizations l) => l.categoryIconPets;
String _lFitnessCenter(AppLocalizations l) => l.categoryIconFitnessCenter;
String _lSportsEsports(AppLocalizations l) => l.categoryIconSportsEsports;
String _lMusicNote(AppLocalizations l) => l.categoryIconMusicNote;
String _lMenuBook(AppLocalizations l) => l.categoryIconMenuBook;
String _lPhoneIphone(AppLocalizations l) => l.categoryIconPhoneIphone;
String _lWifi(AppLocalizations l) => l.categoryIconWifi;
String _lBolt(AppLocalizations l) => l.categoryIconBolt;
String _lWaterDrop(AppLocalizations l) => l.categoryIconWaterDrop;
String _lSavings(AppLocalizations l) => l.categoryIconSavings;
String _lCardGiftcard(AppLocalizations l) => l.categoryIconCardGiftcard;
String _lCheckroom(AppLocalizations l) => l.categoryIconCheckroom;
String _lCelebration(AppLocalizations l) => l.categoryIconCelebration;
