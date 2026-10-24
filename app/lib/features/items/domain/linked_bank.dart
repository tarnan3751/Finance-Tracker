/// One Plaid Item as the device stores it: the Item, its institution, the institution's
/// logo bytes when fetched, and when the Plaid pull last wrote it
/// (`docs/reference/items.md`). Pure Dart, no Flutter import.
library;

import 'dart:typed_data';

import 'package:shared_models/shared_models.dart';

/// A linked bank: an [item] at its [institution].
final class LinkedBank {
  /// A linked bank. [logo] is the institution's logo, fetched from the server; null until
  /// it is, or when the institution has none.
  const LinkedBank({
    required this.item,
    required this.institution,
    this.logo,
    required this.pulledAt,
  });

  /// The Item, its status as the server last reported it.
  final Item item;

  /// Its institution.
  final Institution institution;

  /// The institution's logo bytes, or null.
  final Uint8List? logo;

  /// When the Plaid pull last wrote this Item, UTC.
  final DateTime pulledAt;

  /// The Item's id.
  String get id => item.id;

  /// A copy with [item] replaced.
  LinkedBank withItem(Item item) => LinkedBank(
    item: item,
    institution: institution,
    logo: logo,
    pulledAt: pulledAt,
  );

  @override
  bool operator ==(Object other) =>
      other is LinkedBank &&
      other.item == item &&
      other.institution == institution &&
      _sameBytes(other.logo, logo) &&
      other.pulledAt == pulledAt;

  @override
  int get hashCode => Object.hash(item, institution, logo?.length, pulledAt);

  @override
  String toString() => 'LinkedBank(${item.id}, ${item.status.name})';
}

bool _sameBytes(Uint8List? a, Uint8List? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
