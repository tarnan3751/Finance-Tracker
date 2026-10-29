// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'e0b38344e61bd30ba64177815e2f03a1fc868ab5';

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
