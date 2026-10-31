// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The record of this device's imports, newest first ([ImportActions.history]); empty
/// when the stored value does not decode.

@ProviderFor(importHistory)
final importHistoryProvider = ImportHistoryProvider._();

/// The record of this device's imports, newest first ([ImportActions.history]); empty
/// when the stored value does not decode.

final class ImportHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ImportBatch>>,
          List<ImportBatch>,
          FutureOr<List<ImportBatch>>
        >
    with
        $FutureModifier<List<ImportBatch>>,
        $FutureProvider<List<ImportBatch>> {
  /// The record of this device's imports, newest first ([ImportActions.history]); empty
  /// when the stored value does not decode.
  ImportHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<ImportBatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ImportBatch>> create(Ref ref) {
    return importHistory(ref);
  }
}

String _$importHistoryHash() => r'69942ec9ee783767e0318c7437c27c970cc27e76';

/// The import's work over the flavor's repositories.

@ProviderFor(importActions)
final importActionsProvider = ImportActionsProvider._();

/// The import's work over the flavor's repositories.

final class ImportActionsProvider
    extends $FunctionalProvider<ImportActions, ImportActions, ImportActions>
    with $Provider<ImportActions> {
  /// The import's work over the flavor's repositories.
  ImportActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importActionsHash();

  @$internal
  @override
  $ProviderElement<ImportActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportActions create(Ref ref) {
    return importActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportActions>(value),
    );
  }
}

String _$importActionsHash() => r'82b8b723a441b9d7b6fde3c4882b0b9a3942558a';
