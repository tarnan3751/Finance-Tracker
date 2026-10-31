// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The writer over the flavor's repositories.

@ProviderFor(snapshotWriter)
final snapshotWriterProvider = SnapshotWriterProvider._();

/// The writer over the flavor's repositories.

final class SnapshotWriterProvider
    extends $FunctionalProvider<SnapshotWriter, SnapshotWriter, SnapshotWriter>
    with $Provider<SnapshotWriter> {
  /// The writer over the flavor's repositories.
  SnapshotWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snapshotWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snapshotWriterHash();

  @$internal
  @override
  $ProviderElement<SnapshotWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SnapshotWriter create(Ref ref) {
    return snapshotWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnapshotWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnapshotWriter>(value),
    );
  }
}

String _$snapshotWriterHash() => r'0e76d6ae408b4878ce2157bbe5aa88c051b038aa';

/// Keeps today's snapshots written while listened to (see the library comment). Its
/// state is the last day it wrote, null before its first write.

@ProviderFor(SnapshotWriterRunner)
final snapshotWriterRunnerProvider = SnapshotWriterRunnerProvider._();

/// Keeps today's snapshots written while listened to (see the library comment). Its
/// state is the last day it wrote, null before its first write.
final class SnapshotWriterRunnerProvider
    extends $NotifierProvider<SnapshotWriterRunner, LocalDate?> {
  /// Keeps today's snapshots written while listened to (see the library comment). Its
  /// state is the last day it wrote, null before its first write.
  SnapshotWriterRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snapshotWriterRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snapshotWriterRunnerHash();

  @$internal
  @override
  SnapshotWriterRunner create() => SnapshotWriterRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate?>(value),
    );
  }
}

String _$snapshotWriterRunnerHash() =>
    r'b77cc73d45ef5774a6880f9cb247214199f84330';

/// Keeps today's snapshots written while listened to (see the library comment). Its
/// state is the last day it wrote, null before its first write.

abstract class _$SnapshotWriterRunner extends $Notifier<LocalDate?> {
  LocalDate? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalDate?, LocalDate?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalDate?, LocalDate?>,
              LocalDate?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
