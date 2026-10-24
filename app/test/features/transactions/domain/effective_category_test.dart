// The effective category of a transaction: the live user category, else the system
// category of its detailed Plaid code, else of its primary code, else none; a deleted or
// unknown user category counts as unset.
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  const Category mine = Category(
    id: 'mine',
    name: 'Mine',
    isSystem: false,
    icon: 'category',
    color: 0xFF000000,
  );
  final CategoryLookup lookup = categoryLookup([...systemCategories, mine]);

  Transaction transaction({
    String? userCategoryId,
    String? primary,
    String? detailed,
  }) => Transaction(
    id: 't',
    accountId: 'a',
    amount: Money(-100, 'USD'),
    date: LocalDate(2026, 10, 1),
    pending: false,
    name: 'Purchase',
    plaidPrimaryCategory: primary,
    plaidDetailedCategory: detailed,
    userCategoryId: userCategoryId,
    source: DataSource.plaid,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
    syncVersion: 0,
  );

  String? effective(Transaction t) => effectiveCategory(t, lookup)?.id;

  test('the user category wins over the Plaid codes', () {
    expect(
      effective(
        transaction(
          userCategoryId: 'mine',
          primary: 'FOOD_AND_DRINK',
          detailed: 'FOOD_AND_DRINK_GROCERIES',
        ),
      ),
      'mine',
    );
  });

  test('else the category of the detailed code', () {
    expect(
      effective(
        transaction(
          primary: 'FOOD_AND_DRINK',
          detailed: 'FOOD_AND_DRINK_GROCERIES',
        ),
      ),
      systemCategoryId('FOOD_AND_DRINK_GROCERIES'),
    );
  });

  test('else the category of the primary code', () {
    expect(
      effective(transaction(primary: 'FOOD_AND_DRINK')),
      systemCategoryId('FOOD_AND_DRINK'),
    );
    // A detailed code no category has falls back to the primary.
    expect(
      effective(
        transaction(primary: 'FOOD_AND_DRINK', detailed: 'FOOD_AND_DRINK_NEW'),
      ),
      systemCategoryId('FOOD_AND_DRINK'),
    );
  });

  test('a deleted or unknown user category counts as unset', () {
    expect(
      effective(
        transaction(userCategoryId: 'deleted', primary: 'FOOD_AND_DRINK'),
      ),
      systemCategoryId('FOOD_AND_DRINK'),
    );
    expect(effective(transaction(userCategoryId: 'deleted')), isNull);
  });

  test('no user category and no code that resolves is uncategorized', () {
    expect(effective(transaction()), isNull);
    expect(effective(transaction(primary: 'NOT_A_CODE')), isNull);
  });

  test('plaidCategoryOf ignores the user category', () {
    expect(
      plaidCategoryOf(
        transaction(userCategoryId: 'mine', primary: 'INCOME'),
        lookup.byPlaidCode,
      )?.id,
      systemCategoryId('INCOME'),
    );
  });
}
