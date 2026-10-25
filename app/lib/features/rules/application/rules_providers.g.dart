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

/// Every live transaction, newest first: what a rule is previewed on.

@ProviderFor(ruleHistory)
final ruleHistoryProvider = RuleHistoryProvider._();

/// Every live transaction, newest first: what a rule is previewed on.

final class RuleHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// Every live transaction, newest first: what a rule is previewed on.
  RuleHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    return ruleHistory(ref);
  }
}

String _$ruleHistoryHash() => r'5c6788dff55ddb5fca5e1fddf95eaa29799848f3';

/// What [rule], as the editor holds it, would change in the live transactions on live
/// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
/// categories change.

@ProviderFor(rulePreview)
final rulePreviewProvider = RulePreviewFamily._();

/// What [rule], as the editor holds it, would change in the live transactions on live
/// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
/// categories change.

final class RulePreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<RulePreview>,
          RulePreview,
          FutureOr<RulePreview>
        >
    with $FutureModifier<RulePreview>, $FutureProvider<RulePreview> {
  /// What [rule], as the editor holds it, would change in the live transactions on live
  /// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
  /// categories change.
  RulePreviewProvider._({
    required RulePreviewFamily super.from,
    required Rule super.argument,
  }) : super(
         retry: null,
         name: r'rulePreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rulePreviewHash();

  @override
  String toString() {
    return r'rulePreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RulePreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RulePreview> create(Ref ref) {
    final argument = this.argument as Rule;
    return rulePreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RulePreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rulePreviewHash() => r'5eafdeef180a3f24baff7316a78f172c155b8f57';

/// What [rule], as the editor holds it, would change in the live transactions on live
/// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
/// categories change.

final class RulePreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RulePreview>, Rule> {
  RulePreviewFamily._()
    : super(
        retry: null,
        name: r'rulePreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What [rule], as the editor holds it, would change in the live transactions on live
  /// accounts (`evaluateRuleOnHistory`), recomputed when they, the accounts or the
  /// categories change.

  RulePreviewProvider call(Rule rule) =>
      RulePreviewProvider._(argument: rule, from: this);

  @override
  String toString() => r'rulePreviewProvider';
}

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
