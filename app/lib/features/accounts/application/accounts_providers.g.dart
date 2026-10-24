// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live accounts: visible ones first, then hidden ones, each in display order.

@ProviderFor(accounts)
final accountsProvider = AccountsProvider._();

/// The live accounts: visible ones first, then hidden ones, each in display order.

final class AccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          Stream<List<Account>>
        >
    with $FutureModifier<List<Account>>, $StreamProvider<List<Account>> {
  /// The live accounts: visible ones first, then hidden ones, each in display order.
  AccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsHash();

  @$internal
  @override
  $StreamProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Account>> create(Ref ref) {
    return accounts(ref);
  }
}

String _$accountsHash() => r'970788a5387f58b1981df52e25a560bb14ca3e92';

/// The live accounts by id, for screens that name a transaction's account.

@ProviderFor(accountsById)
final accountsByIdProvider = AccountsByIdProvider._();

/// The live accounts by id, for screens that name a transaction's account.

final class AccountsByIdProvider
    extends
        $FunctionalProvider<
          Map<String, Account>,
          Map<String, Account>,
          Map<String, Account>
        >
    with $Provider<Map<String, Account>> {
  /// The live accounts by id, for screens that name a transaction's account.
  AccountsByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsByIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsByIdHash();

  @$internal
  @override
  $ProviderElement<Map<String, Account>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, Account> create(Ref ref) {
    return accountsById(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Account> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Account>>(value),
    );
  }
}

String _$accountsByIdHash() => r'f438643b7b35e1774cb5dfe597ea9ffa26442e5b';

/// Every live account's balance derived from its transactions, by account id; null for an
/// account with none.

@ProviderFor(derivedBalances)
final derivedBalancesProvider = DerivedBalancesProvider._();

/// Every live account's balance derived from its transactions, by account id; null for an
/// account with none.

final class DerivedBalancesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Money?>>,
          Map<String, Money?>,
          Stream<Map<String, Money?>>
        >
    with
        $FutureModifier<Map<String, Money?>>,
        $StreamProvider<Map<String, Money?>> {
  /// Every live account's balance derived from its transactions, by account id; null for an
  /// account with none.
  DerivedBalancesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'derivedBalancesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$derivedBalancesHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, Money?>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Money?>> create(Ref ref) {
    return derivedBalances(ref);
  }
}

String _$derivedBalancesHash() => r'4ceda084ddfeed5f6280ab5fe634fb364c56924e';

/// The live account [id], or null when it does not exist or is deleted.

@ProviderFor(account)
final accountProvider = AccountFamily._();

/// The live account [id], or null when it does not exist or is deleted.

final class AccountProvider
    extends
        $FunctionalProvider<AsyncValue<Account?>, Account?, Stream<Account?>>
    with $FutureModifier<Account?>, $StreamProvider<Account?> {
  /// The live account [id], or null when it does not exist or is deleted.
  AccountProvider._({
    required AccountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'accountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountHash();

  @override
  String toString() {
    return r'accountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Account?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Account?> create(Ref ref) {
    final argument = this.argument as String;
    return account(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountHash() => r'd5de6be20c2245237bb0cb7ed5f752694c9d62b0';

/// The live account [id], or null when it does not exist or is deleted.

final class AccountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Account?>, String> {
  AccountFamily._()
    : super(
        retry: null,
        name: r'accountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live account [id], or null when it does not exist or is deleted.

  AccountProvider call(String id) =>
      AccountProvider._(argument: id, from: this);

  @override
  String toString() => r'accountProvider';
}

/// Account [accountId]'s live transactions, newest first, each with the running balance
/// after it, derived from the transactions before it.

@ProviderFor(accountLedger)
final accountLedgerProvider = AccountLedgerFamily._();

/// Account [accountId]'s live transactions, newest first, each with the running balance
/// after it, derived from the transactions before it.

final class AccountLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LedgerEntry>>,
          List<LedgerEntry>,
          Stream<List<LedgerEntry>>
        >
    with
        $FutureModifier<List<LedgerEntry>>,
        $StreamProvider<List<LedgerEntry>> {
  /// Account [accountId]'s live transactions, newest first, each with the running balance
  /// after it, derived from the transactions before it.
  AccountLedgerProvider._({
    required AccountLedgerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'accountLedgerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountLedgerHash();

  @override
  String toString() {
    return r'accountLedgerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LedgerEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LedgerEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return accountLedger(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountLedgerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountLedgerHash() => r'36515e9585d10b148b793c8a82dbe038409d0875';

/// Account [accountId]'s live transactions, newest first, each with the running balance
/// after it, derived from the transactions before it.

final class AccountLedgerFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LedgerEntry>>, String> {
  AccountLedgerFamily._()
    : super(
        retry: null,
        name: r'accountLedgerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Account [accountId]'s live transactions, newest first, each with the running balance
  /// after it, derived from the transactions before it.

  AccountLedgerProvider call(String accountId) =>
      AccountLedgerProvider._(argument: accountId, from: this);

  @override
  String toString() => r'accountLedgerProvider';
}

/// How many live transactions account [accountId] has, when the editor or the delete
/// confirmation asks.

@ProviderFor(accountTransactionCount)
final accountTransactionCountProvider = AccountTransactionCountFamily._();

/// How many live transactions account [accountId] has, when the editor or the delete
/// confirmation asks.

final class AccountTransactionCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How many live transactions account [accountId] has, when the editor or the delete
  /// confirmation asks.
  AccountTransactionCountProvider._({
    required AccountTransactionCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'accountTransactionCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accountTransactionCountHash();

  @override
  String toString() {
    return r'accountTransactionCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return accountTransactionCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountTransactionCountProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountTransactionCountHash() =>
    r'3a3ffbdcfd885ce42754e3eb0d624ec9957bee34';

/// How many live transactions account [accountId] has, when the editor or the delete
/// confirmation asks.

final class AccountTransactionCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  AccountTransactionCountFamily._()
    : super(
        retry: null,
        name: r'accountTransactionCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How many live transactions account [accountId] has, when the editor or the delete
  /// confirmation asks.

  AccountTransactionCountProvider call(String accountId) =>
      AccountTransactionCountProvider._(argument: accountId, from: this);

  @override
  String toString() => r'accountTransactionCountProvider';
}

/// The writes of the account screens.

@ProviderFor(accountActions)
final accountActionsProvider = AccountActionsProvider._();

/// The writes of the account screens.

final class AccountActionsProvider
    extends $FunctionalProvider<AccountActions, AccountActions, AccountActions>
    with $Provider<AccountActions> {
  /// The writes of the account screens.
  AccountActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountActionsHash();

  @$internal
  @override
  $ProviderElement<AccountActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountActions create(Ref ref) {
    return accountActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountActions>(value),
    );
  }
}

String _$accountActionsHash() => r'376709c59f62e95476907b259c9916666bae3f39';
