// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Transaction',
  json,
  ($checkedConvert) {
    final val = _Transaction(
      id: $checkedConvert('id', (v) => v as String),
      accountId: $checkedConvert('account_id', (v) => v as String),
      amount: $checkedConvert(
        'amount',
        (v) => Money.fromJson(v as Map<String, dynamic>),
      ),
      date: $checkedConvert('date', (v) => LocalDate.fromJson(v as String)),
      authorizedDate: $checkedConvert(
        'authorized_date',
        (v) => v == null ? null : LocalDate.fromJson(v as String),
      ),
      pending: $checkedConvert('pending', (v) => v as bool),
      pendingTransactionId: $checkedConvert(
        'pending_transaction_id',
        (v) => v as String?,
      ),
      name: $checkedConvert('name', (v) => v as String),
      merchantName: $checkedConvert('merchant_name', (v) => v as String?),
      merchantLogoUrl: $checkedConvert(
        'merchant_logo_url',
        (v) => v == null ? null : Uri.parse(v as String),
      ),
      plaidPrimaryCategory: $checkedConvert(
        'plaid_primary_category',
        (v) => v as String?,
      ),
      plaidDetailedCategory: $checkedConvert(
        'plaid_detailed_category',
        (v) => v as String?,
      ),
      userCategoryId: $checkedConvert('user_category_id', (v) => v as String?),
      notes: $checkedConvert('notes', (v) => v as String?),
      tags: $checkedConvert(
        'tags',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ??
            const <String>[],
      ),
      splits: $checkedConvert(
        'splits',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) => TransactionSplit.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const <TransactionSplit>[],
      ),
      receiptPath: $checkedConvert('receipt_path', (v) => v as String?),
      hidden: $checkedConvert('hidden', (v) => v as bool? ?? false),
      source: $checkedConvert(
        'source',
        (v) => $enumDecode(_$DataSourceEnumMap, v),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => const UtcInstantConverter().fromJson(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => const UtcInstantConverter().fromJson(v as String),
      ),
      deletedAt: $checkedConvert(
        'deleted_at',
        (v) => _$JsonConverterFromJson<String, DateTime>(
          v,
          const UtcInstantConverter().fromJson,
        ),
      ),
      syncVersion: $checkedConvert('sync_version', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'accountId': 'account_id',
    'authorizedDate': 'authorized_date',
    'pendingTransactionId': 'pending_transaction_id',
    'merchantName': 'merchant_name',
    'merchantLogoUrl': 'merchant_logo_url',
    'plaidPrimaryCategory': 'plaid_primary_category',
    'plaidDetailedCategory': 'plaid_detailed_category',
    'userCategoryId': 'user_category_id',
    'receiptPath': 'receipt_path',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'deletedAt': 'deleted_at',
    'syncVersion': 'sync_version',
  },
);

Map<String, dynamic> _$TransactionToJson(_Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'amount': instance.amount.toJson(),
      'date': instance.date.toJson(),
      'authorized_date': instance.authorizedDate?.toJson(),
      'pending': instance.pending,
      'pending_transaction_id': instance.pendingTransactionId,
      'name': instance.name,
      'merchant_name': instance.merchantName,
      'merchant_logo_url': instance.merchantLogoUrl?.toString(),
      'plaid_primary_category': instance.plaidPrimaryCategory,
      'plaid_detailed_category': instance.plaidDetailedCategory,
      'user_category_id': instance.userCategoryId,
      'notes': instance.notes,
      'tags': instance.tags,
      'splits': instance.splits.map((e) => e.toJson()).toList(),
      'receipt_path': instance.receiptPath,
      'hidden': instance.hidden,
      'source': _$DataSourceEnumMap[instance.source]!,
      'created_at': const UtcInstantConverter().toJson(instance.createdAt),
      'updated_at': const UtcInstantConverter().toJson(instance.updatedAt),
      'deleted_at': _$JsonConverterToJson<String, DateTime>(
        instance.deletedAt,
        const UtcInstantConverter().toJson,
      ),
      'sync_version': instance.syncVersion,
    };

const _$DataSourceEnumMap = {
  DataSource.plaid: 'plaid',
  DataSource.manual: 'manual',
  DataSource.import: 'import',
  DataSource.derived: 'derived',
  DataSource.demo: 'demo',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_TransactionSplit _$TransactionSplitFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_TransactionSplit', json, ($checkedConvert) {
      final val = _TransactionSplit(
        categoryId: $checkedConvert('category_id', (v) => v as String),
        amount: $checkedConvert(
          'amount',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'categoryId': 'category_id'});

Map<String, dynamic> _$TransactionSplitToJson(_TransactionSplit instance) =>
    <String, dynamic>{
      'category_id': instance.categoryId,
      'amount': instance.amount.toJson(),
      'note': instance.note,
    };
