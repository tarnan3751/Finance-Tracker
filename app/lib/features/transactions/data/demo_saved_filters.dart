/// The demo flavor's saved filters: two samples over the system categories and the
/// date presets, which every demo persona has. Data only, in the JSON of
/// `TransactionFilters.toJson`.
library;

import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';

/// The demo's two saved filters.
final List<SavedFilter> demoSavedFilters = [
  SavedFilter(
    id: 'demo-saved-food',
    name: 'Food and drink this month',
    position: 0,
    filters: const {
      'category_ids': ['plaid:FOOD_AND_DRINK'],
      'date': {'preset': 'this_month'},
    },
  ),
  SavedFilter(
    id: 'demo-saved-large',
    name: r'Over $100, last 90 days',
    position: 1,
    filters: const {
      'date': {'preset': 'last_90_days'},
      'min_amount': {'minor_units': 10000, 'currency': 'USD'},
    },
  ),
];
