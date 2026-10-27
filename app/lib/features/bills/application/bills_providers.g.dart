// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bills_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live bills, by first due date, then id.

@ProviderFor(bills)
final billsProvider = BillsProvider._();

/// The live bills, by first due date, then id.

final class BillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillReminder>>,
          List<BillReminder>,
          Stream<List<BillReminder>>
        >
    with
        $FutureModifier<List<BillReminder>>,
        $StreamProvider<List<BillReminder>> {
  /// The live bills, by first due date, then id.
  BillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billsHash();

  @$internal
  @override
  $StreamProviderElement<List<BillReminder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BillReminder>> create(Ref ref) {
    return bills(ref);
  }
}

String _$billsHash() => r'70432149114b5b560dd8184fc618bb10b448525e';

/// The streams' names as the app shows them, by stream id: the name of a bill recorded
/// before bills had one.

@ProviderFor(streamNames)
final streamNamesProvider = StreamNamesProvider._();

/// The streams' names as the app shows them, by stream id: the name of a bill recorded
/// before bills had one.

final class StreamNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// The streams' names as the app shows them, by stream id: the name of a bill recorded
  /// before bills had one.
  StreamNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streamNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streamNamesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return streamNames(ref);
  }
}

String _$streamNamesHash() => r'14cbc55e1e7868fddc7a250f90ea092b1a685903';

/// The next payment due date of each liability a live bill follows, by bill id.

@ProviderFor(liabilityDueDates)
final liabilityDueDatesProvider = LiabilityDueDatesProvider._();

/// The next payment due date of each liability a live bill follows, by bill id.

final class LiabilityDueDatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, LocalDate>>,
          Map<String, LocalDate>,
          FutureOr<Map<String, LocalDate>>
        >
    with
        $FutureModifier<Map<String, LocalDate>>,
        $FutureProvider<Map<String, LocalDate>> {
  /// The next payment due date of each liability a live bill follows, by bill id.
  LiabilityDueDatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liabilityDueDatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liabilityDueDatesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, LocalDate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, LocalDate>> create(Ref ref) {
    return liabilityDueDates(ref);
  }
}

String _$liabilityDueDatesHash() => r'3c19848d77fa0e8ac3c48913d2eedc09e7e2d36a';

/// Which transaction paid which bill occurrence, one assignment across every bill
/// (`assignPayments`): the occurrences due from [statusLookbackDays] days back (or from
/// the oldest one-off bill's date, when that is older: its one occurrence stays its last)
/// to the end of the reminder window and its offsets, among the transactions dated
/// around them.
/// The bill statuses and the reminders both read it, so a payment counts the same way for
/// both. Recomputed when the bills, the followed liabilities' due dates, the transactions
/// in that range or today change.

@ProviderFor(billPayments)
final billPaymentsProvider = BillPaymentsProvider._();

/// Which transaction paid which bill occurrence, one assignment across every bill
/// (`assignPayments`): the occurrences due from [statusLookbackDays] days back (or from
/// the oldest one-off bill's date, when that is older: its one occurrence stays its last)
/// to the end of the reminder window and its offsets, among the transactions dated
/// around them.
/// The bill statuses and the reminders both read it, so a payment counts the same way for
/// both. Recomputed when the bills, the followed liabilities' due dates, the transactions
/// in that range or today change.

final class BillPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillPayments>,
          BillPayments,
          Stream<BillPayments>
        >
    with $FutureModifier<BillPayments>, $StreamProvider<BillPayments> {
  /// Which transaction paid which bill occurrence, one assignment across every bill
  /// (`assignPayments`): the occurrences due from [statusLookbackDays] days back (or from
  /// the oldest one-off bill's date, when that is older: its one occurrence stays its last)
  /// to the end of the reminder window and its offsets, among the transactions dated
  /// around them.
  /// The bill statuses and the reminders both read it, so a payment counts the same way for
  /// both. Recomputed when the bills, the followed liabilities' due dates, the transactions
  /// in that range or today change.
  BillPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billPaymentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billPaymentsHash();

  @$internal
  @override
  $StreamProviderElement<BillPayments> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BillPayments> create(Ref ref) {
    return billPayments(ref);
  }
}

String _$billPaymentsHash() => r'e65e5e869984e2398b26efefe1731c5d1daddbd8';

/// Every live bill's status today, in [bills]' order, from [billPayments].

@ProviderFor(billStatuses)
final billStatusesProvider = BillStatusesProvider._();

/// Every live bill's status today, in [bills]' order, from [billPayments].

final class BillStatusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillStatus>>,
          List<BillStatus>,
          FutureOr<List<BillStatus>>
        >
    with $FutureModifier<List<BillStatus>>, $FutureProvider<List<BillStatus>> {
  /// Every live bill's status today, in [bills]' order, from [billPayments].
  BillStatusesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billStatusesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billStatusesHash();

  @$internal
  @override
  $FutureProviderElement<List<BillStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillStatus>> create(Ref ref) {
    return billStatuses(ref);
  }
}

String _$billStatusesHash() => r'e062141ed9527058145eeb8e3aedf0f5359c520b';

/// The in-app keys (`bill/<id>/<due>`) of the bill occurrences paid now, by a mark or a
/// payment, so the in-app list can hide a due notice a later pull has paid (the
/// `bill_alerts` row stays, so it is not raised again).

@ProviderFor(paidBillKeys)
final paidBillKeysProvider = PaidBillKeysProvider._();

/// The in-app keys (`bill/<id>/<due>`) of the bill occurrences paid now, by a mark or a
/// payment, so the in-app list can hide a due notice a later pull has paid (the
/// `bill_alerts` row stays, so it is not raised again).

final class PaidBillKeysProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The in-app keys (`bill/<id>/<due>`) of the bill occurrences paid now, by a mark or a
  /// payment, so the in-app list can hide a due notice a later pull has paid (the
  /// `bill_alerts` row stays, so it is not raised again).
  PaidBillKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paidBillKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paidBillKeysHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return paidBillKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$paidBillKeysHash() => r'ed89baff3a84499cde8bafc1c26e45d274fe35ea';

/// What bill suggestions are made from: the active, unmuted recurring streams under the
/// names the app shows, and the liabilities, named by their accounts.

@ProviderFor(billSourceData)
final billSourceDataProvider = BillSourceDataProvider._();

/// What bill suggestions are made from: the active, unmuted recurring streams under the
/// names the app shows, and the liabilities, named by their accounts.

final class BillSourceDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillSourceData>,
          BillSourceData,
          FutureOr<BillSourceData>
        >
    with $FutureModifier<BillSourceData>, $FutureProvider<BillSourceData> {
  /// What bill suggestions are made from: the active, unmuted recurring streams under the
  /// names the app shows, and the liabilities, named by their accounts.
  BillSourceDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billSourceDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billSourceDataHash();

  @$internal
  @override
  $FutureProviderElement<BillSourceData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BillSourceData> create(Ref ref) {
    return billSourceData(ref);
  }
}

String _$billSourceDataHash() => r'db4cba82daa4e715b2e996d89c4167e057016b82';

/// The bills the user may add, from [billSourceData], leaving out what a live bill
/// already links.

@ProviderFor(suggestedBills)
final suggestedBillsProvider = SuggestedBillsProvider._();

/// The bills the user may add, from [billSourceData], leaving out what a live bill
/// already links.

final class SuggestedBillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillSuggestion>>,
          List<BillSuggestion>,
          FutureOr<List<BillSuggestion>>
        >
    with
        $FutureModifier<List<BillSuggestion>>,
        $FutureProvider<List<BillSuggestion>> {
  /// The bills the user may add, from [billSourceData], leaving out what a live bill
  /// already links.
  SuggestedBillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestedBillsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestedBillsHash();

  @$internal
  @override
  $FutureProviderElement<List<BillSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillSuggestion>> create(Ref ref) {
    return suggestedBills(ref);
  }
}

String _$suggestedBillsHash() => r'1efc91b6d7a71015121b8b0b6882e779a8259fcb';

/// What the reminders are planned from: the live bills, the followed liabilities' due
/// dates, the streams' names, and [billPayments]; recomputed when any of them changes.

@ProviderFor(reminderInputs)
final reminderInputsProvider = ReminderInputsProvider._();

/// What the reminders are planned from: the live bills, the followed liabilities' due
/// dates, the streams' names, and [billPayments]; recomputed when any of them changes.

final class ReminderInputsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReminderInputs>,
          ReminderInputs,
          FutureOr<ReminderInputs>
        >
    with $FutureModifier<ReminderInputs>, $FutureProvider<ReminderInputs> {
  /// What the reminders are planned from: the live bills, the followed liabilities' due
  /// dates, the streams' names, and [billPayments]; recomputed when any of them changes.
  ReminderInputsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderInputsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderInputsHash();

  @$internal
  @override
  $FutureProviderElement<ReminderInputs> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReminderInputs> create(Ref ref) {
    return reminderInputs(ref);
  }
}

String _$reminderInputsHash() => r'3d5b3c49989ce706bbb9d320794b8b213d793183';

/// The reminders' texts, in the device's language: "Rent is due tomorrow", and the
/// expected amount.

@ProviderFor(reminderText)
final reminderTextProvider = ReminderTextProvider._();

/// The reminders' texts, in the device's language: "Rent is due tomorrow", and the
/// expected amount.

final class ReminderTextProvider
    extends $FunctionalProvider<ReminderText, ReminderText, ReminderText>
    with $Provider<ReminderText> {
  /// The reminders' texts, in the device's language: "Rent is due tomorrow", and the
  /// expected amount.
  ReminderTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderTextHash();

  @$internal
  @override
  $ProviderElement<ReminderText> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReminderText create(Ref ref) {
    return reminderText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderText>(value),
    );
  }
}

String _$reminderTextHash() => r'56f041aeec2587c6e4b1b3c4b4581ab452778141';

/// The bill actions: saving, deleting with undo, accepting a suggestion and marking an
/// occurrence paid.

@ProviderFor(billActions)
final billActionsProvider = BillActionsProvider._();

/// The bill actions: saving, deleting with undo, accepting a suggestion and marking an
/// occurrence paid.

final class BillActionsProvider
    extends $FunctionalProvider<BillActions, BillActions, BillActions>
    with $Provider<BillActions> {
  /// The bill actions: saving, deleting with undo, accepting a suggestion and marking an
  /// occurrence paid.
  BillActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billActionsHash();

  @$internal
  @override
  $ProviderElement<BillActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillActions create(Ref ref) {
    return billActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillActions>(value),
    );
  }
}

String _$billActionsHash() => r'9f5894a7736fe70cbe00f41a9f4dff382bc4ba8a';
