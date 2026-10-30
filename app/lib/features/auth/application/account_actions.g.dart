// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_actions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The account's actions.

@ProviderFor(accountActions)
final accountActionsProvider = AccountActionsProvider._();

/// The account's actions.

final class AccountActionsProvider
    extends $FunctionalProvider<AccountActions, AccountActions, AccountActions>
    with $Provider<AccountActions> {
  /// The account's actions.
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

String _$accountActionsHash() => r'6621affe472f6cf5b4a76533d08e825ec468bee8';
