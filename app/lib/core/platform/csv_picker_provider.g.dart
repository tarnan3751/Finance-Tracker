// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The CSV picker.

@ProviderFor(csvPicker)
final csvPickerProvider = CsvPickerProvider._();

/// The CSV picker.

final class CsvPickerProvider
    extends $FunctionalProvider<BackupPicker, BackupPicker, BackupPicker>
    with $Provider<BackupPicker> {
  /// The CSV picker.
  CsvPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'csvPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$csvPickerHash();

  @$internal
  @override
  $ProviderElement<BackupPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupPicker create(Ref ref) {
    return csvPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupPicker>(value),
    );
  }
}

String _$csvPickerHash() => r'45b39382ceadcb61d6b418da1e8223093a390038';
