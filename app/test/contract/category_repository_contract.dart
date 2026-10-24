// The contract every CategoryRepository implementation passes (Drift, in memory, demo),
// each from its own test file under test/features/categories/data/. Call
// runCategoryRepositoryContract with a factory for a fresh, empty fixture (no categories
// seeded) and, when it holds resources, a dispose that releases the one the factory made
// last.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// Registers the contract tests for the fixtures [create] builds.
void runCategoryRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('CategoryRepository contract', () {
    late RepositoryFixture f;
    late CategoryRepository categories;

    setUp(() async {
      f = await create();
      categories = f.categories;
    });
    if (dispose != null) tearDown(dispose);

    Category user(String id, {String? name, String? parentId}) => Category(
      id: id,
      name: name ?? 'Category $id',
      parentId: parentId,
      isSystem: false,
      icon: 'star',
      color: 0xFF123456,
    );

    const String groceries = 'plaid:FOOD_AND_DRINK_GROCERIES';

    test('a fresh repository is empty', () async {
      expect(await categories.watchAll().first, isEmpty);
      expect(await categories.watchById('c1').first, isNull);
    });

    test('ensureSeeded creates the system categories, once', () async {
      await categories.ensureSeeded();
      final List<Category> seeded = await categories.watchAll().first;
      expect(seeded, unorderedEquals(systemCategories));
      expect(seeded.every((c) => c.isSystem), isTrue);

      await categories.ensureSeeded();
      expect(await categories.watchAll().first, seeded);

      final Category food = (await categories
          .watchById('plaid:FOOD_AND_DRINK')
          .first)!;
      expect(food.name, 'Food and drink');
      expect(food.parentId, isNull);
      final Category grocery = (await categories.watchById(groceries).first)!;
      expect(grocery.name, 'Groceries');
      expect(grocery.parentId, 'plaid:FOOD_AND_DRINK');
      expect(grocery.plaidCategory, 'FOOD_AND_DRINK_GROCERIES');
    });

    test(
      "a system category's icon and color change and survive reseeding",
      () async {
        await categories.ensureSeeded();
        final Category grocery = (await categories.watchById(groceries).first)!;
        final Category restyled = grocery.copyWith(
          icon: 'shopping_cart',
          color: 0xFF000000,
        );
        await categories.upsert(restyled);
        await categories.ensureSeeded();
        expect(await categories.watchById(groceries).first, restyled);
      },
    );

    test(
      'nothing else of a system category changes, and it is never deleted',
      () async {
        await categories.ensureSeeded();
        final Category grocery = (await categories.watchById(groceries).first)!;
        for (final Category edit in [
          grocery.copyWith(name: 'Food shop'),
          grocery.copyWith(parentId: null),
          grocery.copyWith(plaidCategory: 'OTHER'),
          grocery.copyWith(isSystem: false),
        ]) {
          await expectLater(
            categories.upsert(edit),
            throwsA(isA<CategoryNotEditableException>()),
          );
        }
        await expectLater(
          categories.delete(groceries),
          throwsA(isA<CategoryNotDeletableException>()),
        );
        expect(await categories.watchById(groceries).first, grocery);
      },
    );

    test('a user category is created, updated and watched', () async {
      final Category c = user('c1', parentId: 'plaid:FOOD_AND_DRINK');
      final Future<void> seen = expectLater(
        categories.watchById('c1'),
        emitsInOrder([isNull, c, c.copyWith(name: 'Snacks')]),
      );
      await pumpEventQueue();
      await categories.upsert(c);
      await pumpEventQueue();
      await categories.upsert(c.copyWith(name: 'Snacks'));
      await seen;
    });

    test('a new or user category cannot be made a system one', () async {
      await expectLater(
        categories.upsert(user('c1').copyWith(isSystem: true)),
        throwsA(isA<CategoryNotEditableException>()),
      );
      await categories.upsert(user('c1'));
      await expectLater(
        categories.upsert(user('c1').copyWith(isSystem: true)),
        throwsA(isA<CategoryNotEditableException>()),
      );
    });

    test('a delete hides the category and its direct children only', () async {
      await categories.upsert(user('parent'));
      await categories.upsert(user('child', parentId: 'parent'));
      await categories.upsert(user('grandchild', parentId: 'child'));
      await categories.upsert(user('other'));

      final Future<void> gone = expectLater(
        categories.watchById('parent'),
        emitsThrough(isNull),
      );
      await pumpEventQueue();
      await categories.delete('parent');
      await gone;

      expect(
        (await categories.watchAll().first).map((c) => c.id),
        unorderedEquals(['grandchild', 'other']),
      );
      await categories.delete('parent');
      await categories.delete('missing');
      await expectLater(
        categories.upsert(user('child')),
        throwsA(isA<EntityDeletedException>()),
      );
    });

    test('a transaction keeps a deleted category id', () async {
      await categories.upsert(user('c1'));
      await f.accounts.upsert(testAccount('a1'));
      await f.transactions.upsert(
        testTransaction('t1', 'a1', -100, userCategoryId: 'c1'),
      );
      await categories.delete('c1');
      expect(
        (await f.transactions.watchById('t1').first)!.userCategoryId,
        'c1',
      );
    });

    test(
      'categories are ordered by name, ignoring ASCII case, then id',
      () async {
        await categories.upsert(user('3', name: 'banana'));
        await categories.upsert(user('2', name: 'Apple'));
        await categories.upsert(user('1', name: 'apple'));
        await categories.upsert(user('4', name: 'Cherry'));
        expect((await categories.watchAll().first).map((c) => c.id), [
          '1',
          '2',
          '3',
          '4',
        ]);
      },
    );

    test(
      'names and ids compare in UTF-8 byte order, as SQLite NOCASE does',
      () async {
        // U+1F600 sorts before U+FF21 in UTF-16 code units, after it in UTF-8 bytes.
        await categories.upsert(user('emoji', name: '\u{1F600}'));
        await categories.upsert(user('wide', name: '\uFF21'));
        await categories.upsert(user('\u{1F600}', name: 'same'));
        await categories.upsert(user('\uFF21', name: 'same'));
        expect((await categories.watchAll().first).map((c) => c.id), [
          '\uFF21',
          '\u{1F600}',
          'wide',
          'emoji',
        ]);
      },
    );
  });
}
