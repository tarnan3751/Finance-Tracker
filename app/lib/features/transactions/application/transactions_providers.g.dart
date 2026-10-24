// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The transaction list's search, filters and paging. Any change to the filters goes back
/// to the first page.

@ProviderFor(TransactionListController)
final transactionListControllerProvider = TransactionListControllerProvider._();

/// The transaction list's search, filters and paging. Any change to the filters goes back
/// to the first page.
final class TransactionListControllerProvider
    extends $NotifierProvider<TransactionListController, TransactionListState> {
  /// The transaction list's search, filters and paging. Any change to the filters goes back
  /// to the first page.
  TransactionListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionListControllerHash();

  @$internal
  @override
  TransactionListController create() => TransactionListController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionListState>(value),
    );
  }
}

String _$transactionListControllerHash() =>
    r'63b5a2633d29550b2d83f6d4dba5fdae769d17ce';

/// The transaction list's search, filters and paging. Any change to the filters goes back
/// to the first page.

abstract class _$TransactionListController
    extends $Notifier<TransactionListState> {
  TransactionListState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionListState, TransactionListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionListState, TransactionListState>,
              TransactionListState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The list's transactions under its filters, newest first, as many pages as are loaded.
/// A category filter takes the categories under each chosen one along; date presets are
/// resolved against [todayProvider], so they move at midnight.

@ProviderFor(transactionPage)
final transactionPageProvider = TransactionPageProvider._();

/// The list's transactions under its filters, newest first, as many pages as are loaded.
/// A category filter takes the categories under each chosen one along; date presets are
/// resolved against [todayProvider], so they move at midnight.

final class TransactionPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransactionPage>,
          TransactionPage,
          Stream<TransactionPage>
        >
    with $FutureModifier<TransactionPage>, $StreamProvider<TransactionPage> {
  /// The list's transactions under its filters, newest first, as many pages as are loaded.
  /// A category filter takes the categories under each chosen one along; date presets are
  /// resolved against [todayProvider], so they move at midnight.
  TransactionPageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionPageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionPageHash();

  @$internal
  @override
  $StreamProviderElement<TransactionPage> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TransactionPage> create(Ref ref) {
    return transactionPage(ref);
  }
}

String _$transactionPageHash() => r'1535c38f2f70cfec1a78141550c89da193431531';

/// The live transaction [id], or null when it does not exist or is deleted.

@ProviderFor(transaction)
final transactionProvider = TransactionFamily._();

/// The live transaction [id], or null when it does not exist or is deleted.

final class TransactionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Transaction?>,
          Transaction?,
          Stream<Transaction?>
        >
    with $FutureModifier<Transaction?>, $StreamProvider<Transaction?> {
  /// The live transaction [id], or null when it does not exist or is deleted.
  TransactionProvider._({
    required TransactionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transactionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionHash();

  @override
  String toString() {
    return r'transactionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Transaction?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Transaction?> create(Ref ref) {
    final argument = this.argument as String;
    return transaction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionHash() => r'74c2dc86e9958af21acbcd03c85cda370a0df4e4';

/// The live transaction [id], or null when it does not exist or is deleted.

final class TransactionFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Transaction?>, String> {
  TransactionFamily._()
    : super(
        retry: null,
        name: r'transactionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live transaction [id], or null when it does not exist or is deleted.

  TransactionProvider call(String id) =>
      TransactionProvider._(argument: id, from: this);

  @override
  String toString() => r'transactionProvider';
}

/// What the editor and the filter sheet suggest, from the live transactions: the tags in
/// use and the most recently used categories and accounts
/// (`TransactionRepository.watchUsage`).

@ProviderFor(transactionUsage)
final transactionUsageProvider = TransactionUsageProvider._();

/// What the editor and the filter sheet suggest, from the live transactions: the tags in
/// use and the most recently used categories and accounts
/// (`TransactionRepository.watchUsage`).

final class TransactionUsageProvider
    extends
        $FunctionalProvider<
          AsyncValue<TransactionUsage>,
          TransactionUsage,
          Stream<TransactionUsage>
        >
    with $FutureModifier<TransactionUsage>, $StreamProvider<TransactionUsage> {
  /// What the editor and the filter sheet suggest, from the live transactions: the tags in
  /// use and the most recently used categories and accounts
  /// (`TransactionRepository.watchUsage`).
  TransactionUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionUsageHash();

  @$internal
  @override
  $StreamProviderElement<TransactionUsage> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TransactionUsage> create(Ref ref) {
    return transactionUsage(ref);
  }
}

String _$transactionUsageHash() => r'a490a29d0c3b40d516d3f383a85ad49960422ec5';

/// The writes of the transaction editor.

@ProviderFor(transactionActions)
final transactionActionsProvider = TransactionActionsProvider._();

/// The writes of the transaction editor.

final class TransactionActionsProvider
    extends
        $FunctionalProvider<
          TransactionActions,
          TransactionActions,
          TransactionActions
        >
    with $Provider<TransactionActions> {
  /// The writes of the transaction editor.
  TransactionActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionActionsHash();

  @$internal
  @override
  $ProviderElement<TransactionActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionActions create(Ref ref) {
    return transactionActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionActions>(value),
    );
  }
}

String _$transactionActionsHash() =>
    r'6ec05b17029004f5cd54d4425c5ca321b365207c';
