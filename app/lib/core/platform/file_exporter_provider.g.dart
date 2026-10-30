// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_exporter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The file exporter.

@ProviderFor(fileExporter)
final fileExporterProvider = FileExporterProvider._();

/// The file exporter.

final class FileExporterProvider
    extends $FunctionalProvider<FileExporter, FileExporter, FileExporter>
    with $Provider<FileExporter> {
  /// The file exporter.
  FileExporterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileExporterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileExporterHash();

  @$internal
  @override
  $ProviderElement<FileExporter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileExporter create(Ref ref) {
    return fileExporter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileExporter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileExporter>(value),
    );
  }
}

String _$fileExporterHash() => r'c1da4badf1cc198abec8e2dcb322314065aa9e79';
