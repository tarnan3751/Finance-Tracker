// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The backup picker.

@ProviderFor(backupPicker)
final backupPickerProvider = BackupPickerProvider._();

/// The backup picker.

final class BackupPickerProvider
    extends $FunctionalProvider<BackupPicker, BackupPicker, BackupPicker>
    with $Provider<BackupPicker> {
  /// The backup picker.
  BackupPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupPickerHash();

  @$internal
  @override
  $ProviderElement<BackupPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupPicker create(Ref ref) {
    return backupPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupPicker>(value),
    );
  }
}

String _$backupPickerHash() => r'03224484fb8c1bcf3738511f0173c330ea388864';
