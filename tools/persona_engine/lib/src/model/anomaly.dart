/// The unusual transactions the generator plants: ground truth for anomaly detection.
library;

import 'package:meta/meta.dart';

/// The kind of anomaly.
enum AnomalyKind {
  /// A merchant the household already uses, at several times its usual amount.
  unusualAmount,

  /// A merchant the household has never used.
  newMerchant,
}

/// A planted anomaly.
@immutable
final class Anomaly {
  /// An anomaly on the transaction [transactionId].
  const Anomaly(this.kind, this.transactionId);

  /// The kind.
  final AnomalyKind kind;

  /// The transaction.
  final String transactionId;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'kind': switch (kind) {
      AnomalyKind.unusualAmount => 'unusual_amount',
      AnomalyKind.newMerchant => 'new_merchant',
    },
    'transaction_id': transactionId,
  };
}
