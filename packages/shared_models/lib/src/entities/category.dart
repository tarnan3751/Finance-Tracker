/// A spending category (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// A category in the hierarchy: the system set seeded from Plaid's taxonomy, plus the
/// user's own.
@freezed
abstract class Category with _$Category {
  /// A category. [parentId] is null at the top level; [icon] is a key into the app's
  /// icon set; [color] is ARGB; [plaidCategory] is the Plaid primary or detailed code a
  /// system category was seeded from.
  const factory Category({
    required String id,
    required String name,
    String? parentId,
    required bool isSystem,
    required String icon,
    required int color,
    String? plaidCategory,
  }) = _Category;

  /// Reads the snake_case JSON form.
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
