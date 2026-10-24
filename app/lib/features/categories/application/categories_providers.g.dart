// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live categories, by name.

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

/// The live categories, by name.

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          Stream<List<Category>>
        >
    with $FutureModifier<List<Category>>, $StreamProvider<List<Category>> {
  /// The live categories, by name.
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'521ced16a330d78b1c4bf47536d6622a3b38d6b1';

/// The live categories by id, for screens that name a transaction's category.

@ProviderFor(categoriesById)
final categoriesByIdProvider = CategoriesByIdProvider._();

/// The live categories by id, for screens that name a transaction's category.

final class CategoriesByIdProvider
    extends
        $FunctionalProvider<
          Map<String, Category>,
          Map<String, Category>,
          Map<String, Category>
        >
    with $Provider<Map<String, Category>> {
  /// The live categories by id, for screens that name a transaction's category.
  CategoriesByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesByIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesByIdHash();

  @$internal
  @override
  $ProviderElement<Map<String, Category>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Category> create(Ref ref) {
    return categoriesById(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Category> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Category>>(value),
    );
  }
}

String _$categoriesByIdHash() => r'aa643689c4323484e24a7839d2a7e9ea83bbe4cc';

/// The live categories as their hierarchy: every top-level category with its children.
/// A child whose parent is not live is shown at the top level.

@ProviderFor(categoryTree)
final categoryTreeProvider = CategoryTreeProvider._();

/// The live categories as their hierarchy: every top-level category with its children.
/// A child whose parent is not live is shown at the top level.

final class CategoryTreeProvider
    extends
        $FunctionalProvider<
          List<CategoryGroup>,
          List<CategoryGroup>,
          List<CategoryGroup>
        >
    with $Provider<List<CategoryGroup>> {
  /// The live categories as their hierarchy: every top-level category with its children.
  /// A child whose parent is not live is shown at the top level.
  CategoryTreeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryTreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryTreeHash();

  @$internal
  @override
  $ProviderElement<List<CategoryGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CategoryGroup> create(Ref ref) {
    return categoryTree(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CategoryGroup> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CategoryGroup>>(value),
    );
  }
}

String _$categoryTreeHash() => r'6304515c6a71f99f3f845ebe41510f9bd642d063';

/// The writes of the category screens.

@ProviderFor(categoryActions)
final categoryActionsProvider = CategoryActionsProvider._();

/// The writes of the category screens.

final class CategoryActionsProvider
    extends
        $FunctionalProvider<CategoryActions, CategoryActions, CategoryActions>
    with $Provider<CategoryActions> {
  /// The writes of the category screens.
  CategoryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryActionsHash();

  @$internal
  @override
  $ProviderElement<CategoryActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CategoryActions create(Ref ref) {
    return categoryActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryActions>(value),
    );
  }
}

String _$categoryActionsHash() => r'508e3c22ab5046b31bb6395f75575e94be273352';
