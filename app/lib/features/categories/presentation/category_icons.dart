/// The icons a category can wear: about forty Material icons, each with the key stored in
/// `Category.icon` (the Material icon's name) and an accessibility label. The system
/// categories' keys (`category_defaults.dart`) are all here; a key that is not, written by
/// a later version or another device, shows [fallbackCategoryIcon].
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
