// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investments_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every holding of the user's linked investment accounts with its security, by
/// account, then security name.

@ProviderFor(holdings)
final holdingsProvider = HoldingsProvider._();

/// Every holding of the user's linked investment accounts with its security, by
/// account, then security name.

final class HoldingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HoldingView>>,
          List<HoldingView>,
          Stream<List<HoldingView>>
        >
    with
        $FutureModifier<List<HoldingView>>,
        $StreamProvider<List<HoldingView>> {
  /// Every holding of the user's linked investment accounts with its security, by
  /// account, then security name.
  HoldingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'holdingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$holdingsHash();

  @$internal
  @override
  $StreamProviderElement<List<HoldingView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<HoldingView>> create(Ref ref) {
    return holdings(ref);
  }
}

String _$holdingsHash() => r'5ea1e700dd4731d76e7cc90f33cb1e318f1f1dd6';

/// The live investment transactions of account [accountId], newest first.

@ProviderFor(investmentTransactions)
final investmentTransactionsProvider = InvestmentTransactionsFamily._();

/// The live investment transactions of account [accountId], newest first.

final class InvestmentTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvestmentTransaction>>,
          List<InvestmentTransaction>,
          Stream<List<InvestmentTransaction>>
        >
    with
        $FutureModifier<List<InvestmentTransaction>>,
        $StreamProvider<List<InvestmentTransaction>> {
  /// The live investment transactions of account [accountId], newest first.
  InvestmentTransactionsProvider._({
    required InvestmentTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'investmentTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$investmentTransactionsHash();

  @override
  String toString() {
    return r'investmentTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<InvestmentTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InvestmentTransaction>> create(Ref ref) {
    final argument = this.argument as String;
    return investmentTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvestmentTransactionsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$investmentTransactionsHash() =>
    r'da1f281bc97cd1d3488969cf056003036d3563b0';

/// The live investment transactions of account [accountId], newest first.

final class InvestmentTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<List<InvestmentTransaction>>, String> {
  InvestmentTransactionsFamily._()
    : super(
        retry: null,
        name: r'investmentTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live investment transactions of account [accountId], newest first.

  InvestmentTransactionsProvider call(String accountId) =>
      InvestmentTransactionsProvider._(argument: accountId, from: this);

  @override
  String toString() => r'investmentTransactionsProvider';
}
