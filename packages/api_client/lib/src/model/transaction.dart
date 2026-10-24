//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/data_source.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/transaction_split.dart';
import 'package:api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction.g.dart';

/// Mirrors `shared_models` `Transaction`. `amount` is negative for an outflow (Plaid's sign flipped at the server). `name` is Plaid's raw name; `merchant_name` is Plaid's cleaned merchant, null when Plaid has none. `deleted_at` is the tombstone.
///
/// Properties:
/// * [id]
/// * [accountId]
/// * [amount]
/// * [date]
/// * [authorizedDate]
/// * [pending]
/// * [pendingTransactionId]
/// * [name]
/// * [merchantName]
/// * [merchantLogoUrl]
/// * [plaidPrimaryCategory]
/// * [plaidDetailedCategory]
/// * [userCategoryId]
/// * [notes]
/// * [tags]
/// * [splits]
/// * [receiptPath]
/// * [source_]
/// * [createdAt]
/// * [updatedAt]
/// * [deletedAt]
/// * [syncVersion]
@BuiltValue()
abstract class Transaction implements Built<Transaction, TransactionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'amount')
  Money get amount;

  @BuiltValueField(wireName: r'date')
  Date get date;

  @BuiltValueField(wireName: r'authorized_date')
  Date? get authorizedDate;

  @BuiltValueField(wireName: r'pending')
  bool get pending;

  @BuiltValueField(wireName: r'pending_transaction_id')
  String? get pendingTransactionId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'merchant_name')
  String? get merchantName;

  @BuiltValueField(wireName: r'merchant_logo_url')
  String? get merchantLogoUrl;

  @BuiltValueField(wireName: r'plaid_primary_category')
  String? get plaidPrimaryCategory;

  @BuiltValueField(wireName: r'plaid_detailed_category')
  String? get plaidDetailedCategory;

  @BuiltValueField(wireName: r'user_category_id')
  String? get userCategoryId;

  @BuiltValueField(wireName: r'notes')
  String? get notes;

  @BuiltValueField(wireName: r'tags')
  BuiltList<String> get tags;

  @BuiltValueField(wireName: r'splits')
  BuiltList<TransactionSplit> get splits;

  @BuiltValueField(wireName: r'receipt_path')
  String? get receiptPath;

  @BuiltValueField(wireName: r'source')
  DataSource get source_;
  // enum source_Enum {  plaid,  manual,  import,  derived,  demo,  };

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'deleted_at')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'sync_version')
  int get syncVersion;

  Transaction._();

  factory Transaction([void updates(TransactionBuilder b)]) = _$Transaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Transaction> get serializer => _$TransactionSerializer();
}

class _$TransactionSerializer implements PrimitiveSerializer<Transaction> {
  @override
  final Iterable<Type> types = const [Transaction, _$Transaction];

  @override
  final String wireName = r'Transaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Transaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(Money),
    );
    yield r'date';
    yield serializers.serialize(
      object.date,
      specifiedType: const FullType(Date),
    );
    yield r'authorized_date';
    yield object.authorizedDate == null
        ? null
        : serializers.serialize(
            object.authorizedDate,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'pending';
    yield serializers.serialize(
      object.pending,
      specifiedType: const FullType(bool),
    );
    yield r'pending_transaction_id';
    yield object.pendingTransactionId == null
        ? null
        : serializers.serialize(
            object.pendingTransactionId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'merchant_name';
    yield object.merchantName == null
        ? null
        : serializers.serialize(
            object.merchantName,
            specifiedType: const FullType.nullable(String),
          );
    yield r'merchant_logo_url';
    yield object.merchantLogoUrl == null
        ? null
        : serializers.serialize(
            object.merchantLogoUrl,
            specifiedType: const FullType.nullable(String),
          );
    yield r'plaid_primary_category';
    yield object.plaidPrimaryCategory == null
        ? null
        : serializers.serialize(
            object.plaidPrimaryCategory,
            specifiedType: const FullType.nullable(String),
          );
    yield r'plaid_detailed_category';
    yield object.plaidDetailedCategory == null
        ? null
        : serializers.serialize(
            object.plaidDetailedCategory,
            specifiedType: const FullType.nullable(String),
          );
    yield r'user_category_id';
    yield object.userCategoryId == null
        ? null
        : serializers.serialize(
            object.userCategoryId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'notes';
    yield object.notes == null
        ? null
        : serializers.serialize(
            object.notes,
            specifiedType: const FullType.nullable(String),
          );
    yield r'tags';
    yield serializers.serialize(
      object.tags,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'splits';
    yield serializers.serialize(
      object.splits,
      specifiedType: const FullType(BuiltList, [FullType(TransactionSplit)]),
    );
    yield r'receipt_path';
    yield object.receiptPath == null
        ? null
        : serializers.serialize(
            object.receiptPath,
            specifiedType: const FullType.nullable(String),
          );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(DataSource),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'deleted_at';
    yield object.deletedAt == null
        ? null
        : serializers.serialize(
            object.deletedAt,
            specifiedType: const FullType.nullable(DateTime),
          );
    yield r'sync_version';
    yield serializers.serialize(
      object.syncVersion,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Transaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransactionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'account_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accountId = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.amount.replace(valueDes);
          break;
        case r'date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.date = valueDes;
          break;
        case r'authorized_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.authorizedDate = valueDes;
          break;
        case r'pending':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.pending = valueDes;
          break;
        case r'pending_transaction_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.pendingTransactionId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'merchant_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.merchantName = valueDes;
          break;
        case r'merchant_logo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.merchantLogoUrl = valueDes;
          break;
        case r'plaid_primary_category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.plaidPrimaryCategory = valueDes;
          break;
        case r'plaid_detailed_category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.plaidDetailedCategory = valueDes;
          break;
        case r'user_category_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.userCategoryId = valueDes;
          break;
        case r'notes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.notes = valueDes;
          break;
        case r'tags':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.tags.replace(valueDes);
          break;
        case r'splits':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(TransactionSplit),
            ]),
          ) as BuiltList<TransactionSplit>;
          result.splits.replace(valueDes);
          break;
        case r'receipt_path':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.receiptPath = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DataSource),
          ) as DataSource;
          result.source_ = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'deleted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.deletedAt = valueDes;
          break;
        case r'sync_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.syncVersion = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Transaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
