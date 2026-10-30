// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_language_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The language choice, with [set] to change it.

@ProviderFor(AppLanguageController)
final appLanguageControllerProvider = AppLanguageControllerProvider._();

/// The language choice, with [set] to change it.
final class AppLanguageControllerProvider
    extends $AsyncNotifierProvider<AppLanguageController, AppLanguage> {
  /// The language choice, with [set] to change it.
  AppLanguageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLanguageControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLanguageControllerHash();

  @$internal
  @override
  AppLanguageController create() => AppLanguageController();
}

String _$appLanguageControllerHash() =>
    r'942fb5c39bf9aae3b6d40e873a6aa6af54ab2961';

/// The language choice, with [set] to change it.

abstract class _$AppLanguageController extends $AsyncNotifier<AppLanguage> {
  FutureOr<AppLanguage> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppLanguage>, AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppLanguage>, AppLanguage>,
              AsyncValue<AppLanguage>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
