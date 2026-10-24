// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current [Settings] as an `AsyncValue`, following the repository's stream, and
/// the two changes the settings screen makes.

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

/// The current [Settings] as an `AsyncValue`, following the repository's stream, and
/// the two changes the settings screen makes.
final class SettingsControllerProvider
    extends $StreamNotifierProvider<SettingsController, Settings> {
  /// The current [Settings] as an `AsyncValue`, following the repository's stream, and
  /// the two changes the settings screen makes.
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();
}

String _$settingsControllerHash() =>
    r'6ba5d59a60e8d77d5393ee6bb5edd52a89fd90ca';

/// The current [Settings] as an `AsyncValue`, following the repository's stream, and
/// the two changes the settings screen makes.

abstract class _$SettingsController extends $StreamNotifier<Settings> {
  Stream<Settings> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Settings>, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Settings>, Settings>,
              AsyncValue<Settings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
