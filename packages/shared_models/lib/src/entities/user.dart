/// A user of the app; one per install (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// The person signed in to this install.
@freezed
abstract class User with _$User {
  /// A user.
  const factory User({
    required String id,
    required String email,
    required String displayName,
    @UtcInstantConverter() required DateTime createdAt,
  }) = _User;

  /// Reads the snake_case JSON form.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
