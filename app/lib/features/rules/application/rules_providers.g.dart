// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live rules, in the order they are applied.

@ProviderFor(rules)
final rulesProvider = RulesProvider._();

/// The live rules, in the order they are applied.

final class RulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Rule>>,
          List<Rule>,
          Stream<List<Rule>>
        >
    with $FutureModifier<List<Rule>>, $StreamProvider<List<Rule>> {
  /// The live rules, in the order they are applied.
  RulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rulesHash();

  @$internal
  @override
  $StreamProviderElement<List<Rule>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Rule>> create(Ref ref) {
    return rules(ref);
  }
}

String _$rulesHash() => r'dd22d8777fccacf84cf44df1efce69b0a626b9bf';

/// The writes of the rules screens.

@ProviderFor(ruleActions)
final ruleActionsProvider = RuleActionsProvider._();

/// The writes of the rules screens.

final class RuleActionsProvider
    extends $FunctionalProvider<RuleActions, RuleActions, RuleActions>
    with $Provider<RuleActions> {
  /// The writes of the rules screens.
  RuleActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleActionsHash();

  @$internal
  @override
  $ProviderElement<RuleActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RuleActions create(Ref ref) {
    return ruleActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RuleActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RuleActions>(value),
    );
  }
}

String _$ruleActionsHash() => r'09942f8213cd7f487fc022675edabef692893f67';
