// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live budgets, by category, then id.

@ProviderFor(budgets)
final budgetsProvider = BudgetsProvider._();

/// The live budgets, by category, then id.

final class BudgetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  /// The live budgets, by category, then id.
  BudgetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsHash();

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    return budgets(ref);
  }
}

String _$budgetsHash() => r'44b1ebd84442bc78b77ce67bb2e75db8f5878294';

/// Every live budget's status for today, in [budgets]' order: recomputed when the
/// budgets, the categories, the transactions in the budgets' periods or today change.

@ProviderFor(budgetStatuses)
final budgetStatusesProvider = BudgetStatusesProvider._();

/// Every live budget's status for today, in [budgets]' order: recomputed when the
/// budgets, the categories, the transactions in the budgets' periods or today change.

final class BudgetStatusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BudgetStatus>>,
          List<BudgetStatus>,
          Stream<List<BudgetStatus>>
        >
    with
        $FutureModifier<List<BudgetStatus>>,
        $StreamProvider<List<BudgetStatus>> {
  /// Every live budget's status for today, in [budgets]' order: recomputed when the
  /// budgets, the categories, the transactions in the budgets' periods or today change.
  BudgetStatusesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetStatusesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetStatusesHash();

  @$internal
  @override
  $StreamProviderElement<List<BudgetStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BudgetStatus>> create(Ref ref) {
    return budgetStatuses(ref);
  }
}

String _$budgetStatusesHash() => r'ff86f06782a9e5ec99e3a2660496f60c4070cad2';

/// How long after the last change to the statuses the alerts are evaluated.

@ProviderFor(budgetAlertDebounce)
final budgetAlertDebounceProvider = BudgetAlertDebounceProvider._();

/// How long after the last change to the statuses the alerts are evaluated.

final class BudgetAlertDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long after the last change to the statuses the alerts are evaluated.
  BudgetAlertDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetAlertDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetAlertDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return budgetAlertDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$budgetAlertDebounceHash() =>
    r'5c599964238bc1ff29e9f7d1e1ab6ed3fa8eaeaf';

/// Raises the budget alerts, through [appNotifier].

@ProviderFor(budgetAlertEvaluator)
final budgetAlertEvaluatorProvider = BudgetAlertEvaluatorProvider._();

/// Raises the budget alerts, through [appNotifier].

final class BudgetAlertEvaluatorProvider
    extends
        $FunctionalProvider<
          BudgetAlertEvaluator,
          BudgetAlertEvaluator,
          BudgetAlertEvaluator
        >
    with $Provider<BudgetAlertEvaluator> {
  /// Raises the budget alerts, through [appNotifier].
  BudgetAlertEvaluatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetAlertEvaluatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetAlertEvaluatorHash();

  @$internal
  @override
  $ProviderElement<BudgetAlertEvaluator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BudgetAlertEvaluator create(Ref ref) {
    return budgetAlertEvaluator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetAlertEvaluator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetAlertEvaluator>(value),
    );
  }
}

String _$budgetAlertEvaluatorHash() =>
    r'6666379984c1c8ebc5c4b672473e21e3967077a5';

/// Evaluates the budget alerts [budgetAlertDebounce] after the statuses last changed,
/// outside any build, while something listens: `bootstrap` does, for the life of the
/// app.

@ProviderFor(BudgetAlertWatcher)
final budgetAlertWatcherProvider = BudgetAlertWatcherProvider._();

/// Evaluates the budget alerts [budgetAlertDebounce] after the statuses last changed,
/// outside any build, while something listens: `bootstrap` does, for the life of the
/// app.
final class BudgetAlertWatcherProvider
    extends $NotifierProvider<BudgetAlertWatcher, void> {
  /// Evaluates the budget alerts [budgetAlertDebounce] after the statuses last changed,
  /// outside any build, while something listens: `bootstrap` does, for the life of the
  /// app.
  BudgetAlertWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetAlertWatcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetAlertWatcherHash();

  @$internal
  @override
  BudgetAlertWatcher create() => BudgetAlertWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$budgetAlertWatcherHash() =>
    r'faa33321e9c3b5c9dd756191528fc18a99c49961';

/// Evaluates the budget alerts [budgetAlertDebounce] after the statuses last changed,
/// outside any build, while something listens: `bootstrap` does, for the life of the
/// app.

abstract class _$BudgetAlertWatcher extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
