/// An installation of the app (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'device.freezed.dart';
part 'device.g.dart';

/// One installation of the app; a user has one device per install.
@freezed
abstract class Device with _$Device {
  /// A device. [lastSyncAt] is null before its first sync.
  const factory Device({
    required String id,
    required String userId,
    required String name,
    @UtcInstantConverter() DateTime? lastSyncAt,
  }) = _Device;

  /// Reads the snake_case JSON form.
  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}
