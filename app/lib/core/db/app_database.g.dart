// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officialNameMeta = const VerificationMeta(
    'officialName',
  );
  @override
  late final GeneratedColumn<String> officialName = GeneratedColumn<String>(
    'official_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maskMeta = const VerificationMeta('mask');
  @override
  late final GeneratedColumn<String> mask = GeneratedColumn<String>(
    'mask',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentBalanceMinorMeta =
      const VerificationMeta('currentBalanceMinor');
  @override
  late final GeneratedColumn<int> currentBalanceMinor = GeneratedColumn<int>(
    'current_balance_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableBalanceMinorMeta =
      const VerificationMeta('availableBalanceMinor');
  @override
  late final GeneratedColumn<int> availableBalanceMinor = GeneratedColumn<int>(
    'available_balance_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditLimitMinorMeta = const VerificationMeta(
    'creditLimitMinor',
  );
  @override
  late final GeneratedColumn<int> creditLimitMinor = GeneratedColumn<int>(
    'credit_limit_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> balancesAsOf =
      GeneratedColumn<int>(
        'balances_as_of',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AccountsTable.$converterbalancesAsOfn);
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AccountsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AccountsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AccountsTable.$converterdeletedAtn);
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    type,
    subtype,
    name,
    officialName,
    mask,
    currency,
    currentBalanceMinor,
    availableBalanceMinor,
    creditLimitMinor,
    balancesAsOf,
    isHidden,
    displayOrder,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('official_name')) {
      context.handle(
        _officialNameMeta,
        officialName.isAcceptableOrUnknown(
          data['official_name']!,
          _officialNameMeta,
        ),
      );
    }
    if (data.containsKey('mask')) {
      context.handle(
        _maskMeta,
        mask.isAcceptableOrUnknown(data['mask']!, _maskMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('current_balance_minor')) {
      context.handle(
        _currentBalanceMinorMeta,
        currentBalanceMinor.isAcceptableOrUnknown(
          data['current_balance_minor']!,
          _currentBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('available_balance_minor')) {
      context.handle(
        _availableBalanceMinorMeta,
        availableBalanceMinor.isAcceptableOrUnknown(
          data['available_balance_minor']!,
          _availableBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit_minor')) {
      context.handle(
        _creditLimitMinorMeta,
        creditLimitMinor.isAcceptableOrUnknown(
          data['credit_limit_minor']!,
          _creditLimitMinorMeta,
        ),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    } else if (isInserting) {
      context.missing(_isHiddenMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      officialName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}official_name'],
      ),
      mask: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mask'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      currentBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_balance_minor'],
      ),
      availableBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}available_balance_minor'],
      ),
      creditLimitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit_minor'],
      ),
      balancesAsOf: $AccountsTable.$converterbalancesAsOfn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}balances_as_of'],
        ),
      ),
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: $AccountsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $AccountsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $AccountsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
  static TypeConverter<DateTime, int> $converterbalancesAsOf =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterbalancesAsOfn =
      NullAwareTypeConverter.wrap($converterbalancesAsOf);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String? itemId;
  final AccountType type;
  final String? subtype;
  final String name;
  final String? officialName;
  final String? mask;
  final String currency;
  final int? currentBalanceMinor;
  final int? availableBalanceMinor;
  final int? creditLimitMinor;
  final DateTime? balancesAsOf;
  final bool isHidden;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int syncVersion;
  const AccountRow({
    required this.id,
    this.itemId,
    required this.type,
    this.subtype,
    required this.name,
    this.officialName,
    this.mask,
    required this.currency,
    this.currentBalanceMinor,
    this.availableBalanceMinor,
    this.creditLimitMinor,
    this.balancesAsOf,
    required this.isHidden,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || officialName != null) {
      map['official_name'] = Variable<String>(officialName);
    }
    if (!nullToAbsent || mask != null) {
      map['mask'] = Variable<String>(mask);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || currentBalanceMinor != null) {
      map['current_balance_minor'] = Variable<int>(currentBalanceMinor);
    }
    if (!nullToAbsent || availableBalanceMinor != null) {
      map['available_balance_minor'] = Variable<int>(availableBalanceMinor);
    }
    if (!nullToAbsent || creditLimitMinor != null) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor);
    }
    if (!nullToAbsent || balancesAsOf != null) {
      map['balances_as_of'] = Variable<int>(
        $AccountsTable.$converterbalancesAsOfn.toSql(balancesAsOf),
      );
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    map['display_order'] = Variable<int>(displayOrder);
    {
      map['created_at'] = Variable<int>(
        $AccountsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $AccountsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $AccountsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      type: Value(type),
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      name: Value(name),
      officialName: officialName == null && nullToAbsent
          ? const Value.absent()
          : Value(officialName),
      mask: mask == null && nullToAbsent ? const Value.absent() : Value(mask),
      currency: Value(currency),
      currentBalanceMinor: currentBalanceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(currentBalanceMinor),
      availableBalanceMinor: availableBalanceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(availableBalanceMinor),
      creditLimitMinor: creditLimitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitMinor),
      balancesAsOf: balancesAsOf == null && nullToAbsent
          ? const Value.absent()
          : Value(balancesAsOf),
      isHidden: Value(isHidden),
      displayOrder: Value(displayOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      subtype: serializer.fromJson<String?>(json['subtype']),
      name: serializer.fromJson<String>(json['name']),
      officialName: serializer.fromJson<String?>(json['officialName']),
      mask: serializer.fromJson<String?>(json['mask']),
      currency: serializer.fromJson<String>(json['currency']),
      currentBalanceMinor: serializer.fromJson<int?>(
        json['currentBalanceMinor'],
      ),
      availableBalanceMinor: serializer.fromJson<int?>(
        json['availableBalanceMinor'],
      ),
      creditLimitMinor: serializer.fromJson<int?>(json['creditLimitMinor']),
      balancesAsOf: serializer.fromJson<DateTime?>(json['balancesAsOf']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String?>(itemId),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'subtype': serializer.toJson<String?>(subtype),
      'name': serializer.toJson<String>(name),
      'officialName': serializer.toJson<String?>(officialName),
      'mask': serializer.toJson<String?>(mask),
      'currency': serializer.toJson<String>(currency),
      'currentBalanceMinor': serializer.toJson<int?>(currentBalanceMinor),
      'availableBalanceMinor': serializer.toJson<int?>(availableBalanceMinor),
      'creditLimitMinor': serializer.toJson<int?>(creditLimitMinor),
      'balancesAsOf': serializer.toJson<DateTime?>(balancesAsOf),
      'isHidden': serializer.toJson<bool>(isHidden),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  AccountRow copyWith({
    String? id,
    Value<String?> itemId = const Value.absent(),
    AccountType? type,
    Value<String?> subtype = const Value.absent(),
    String? name,
    Value<String?> officialName = const Value.absent(),
    Value<String?> mask = const Value.absent(),
    String? currency,
    Value<int?> currentBalanceMinor = const Value.absent(),
    Value<int?> availableBalanceMinor = const Value.absent(),
    Value<int?> creditLimitMinor = const Value.absent(),
    Value<DateTime?> balancesAsOf = const Value.absent(),
    bool? isHidden,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
  }) => AccountRow(
    id: id ?? this.id,
    itemId: itemId.present ? itemId.value : this.itemId,
    type: type ?? this.type,
    subtype: subtype.present ? subtype.value : this.subtype,
    name: name ?? this.name,
    officialName: officialName.present ? officialName.value : this.officialName,
    mask: mask.present ? mask.value : this.mask,
    currency: currency ?? this.currency,
    currentBalanceMinor: currentBalanceMinor.present
        ? currentBalanceMinor.value
        : this.currentBalanceMinor,
    availableBalanceMinor: availableBalanceMinor.present
        ? availableBalanceMinor.value
        : this.availableBalanceMinor,
    creditLimitMinor: creditLimitMinor.present
        ? creditLimitMinor.value
        : this.creditLimitMinor,
    balancesAsOf: balancesAsOf.present ? balancesAsOf.value : this.balancesAsOf,
    isHidden: isHidden ?? this.isHidden,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      name: data.name.present ? data.name.value : this.name,
      officialName: data.officialName.present
          ? data.officialName.value
          : this.officialName,
      mask: data.mask.present ? data.mask.value : this.mask,
      currency: data.currency.present ? data.currency.value : this.currency,
      currentBalanceMinor: data.currentBalanceMinor.present
          ? data.currentBalanceMinor.value
          : this.currentBalanceMinor,
      availableBalanceMinor: data.availableBalanceMinor.present
          ? data.availableBalanceMinor.value
          : this.availableBalanceMinor,
      creditLimitMinor: data.creditLimitMinor.present
          ? data.creditLimitMinor.value
          : this.creditLimitMinor,
      balancesAsOf: data.balancesAsOf.present
          ? data.balancesAsOf.value
          : this.balancesAsOf,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('name: $name, ')
          ..write('officialName: $officialName, ')
          ..write('mask: $mask, ')
          ..write('currency: $currency, ')
          ..write('currentBalanceMinor: $currentBalanceMinor, ')
          ..write('availableBalanceMinor: $availableBalanceMinor, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('balancesAsOf: $balancesAsOf, ')
          ..write('isHidden: $isHidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    type,
    subtype,
    name,
    officialName,
    mask,
    currency,
    currentBalanceMinor,
    availableBalanceMinor,
    creditLimitMinor,
    balancesAsOf,
    isHidden,
    displayOrder,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.name == this.name &&
          other.officialName == this.officialName &&
          other.mask == this.mask &&
          other.currency == this.currency &&
          other.currentBalanceMinor == this.currentBalanceMinor &&
          other.availableBalanceMinor == this.availableBalanceMinor &&
          other.creditLimitMinor == this.creditLimitMinor &&
          other.balancesAsOf == this.balancesAsOf &&
          other.isHidden == this.isHidden &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String?> itemId;
  final Value<AccountType> type;
  final Value<String?> subtype;
  final Value<String> name;
  final Value<String?> officialName;
  final Value<String?> mask;
  final Value<String> currency;
  final Value<int?> currentBalanceMinor;
  final Value<int?> availableBalanceMinor;
  final Value<int?> creditLimitMinor;
  final Value<DateTime?> balancesAsOf;
  final Value<bool> isHidden;
  final Value<int> displayOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.name = const Value.absent(),
    this.officialName = const Value.absent(),
    this.mask = const Value.absent(),
    this.currency = const Value.absent(),
    this.currentBalanceMinor = const Value.absent(),
    this.availableBalanceMinor = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.balancesAsOf = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    this.itemId = const Value.absent(),
    required AccountType type,
    this.subtype = const Value.absent(),
    required String name,
    this.officialName = const Value.absent(),
    this.mask = const Value.absent(),
    required String currency,
    this.currentBalanceMinor = const Value.absent(),
    this.availableBalanceMinor = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.balancesAsOf = const Value.absent(),
    required bool isHidden,
    required int displayOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       currency = Value(currency),
       isHidden = Value(isHidden),
       displayOrder = Value(displayOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? name,
    Expression<String>? officialName,
    Expression<String>? mask,
    Expression<String>? currency,
    Expression<int>? currentBalanceMinor,
    Expression<int>? availableBalanceMinor,
    Expression<int>? creditLimitMinor,
    Expression<int>? balancesAsOf,
    Expression<bool>? isHidden,
    Expression<int>? displayOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (name != null) 'name': name,
      if (officialName != null) 'official_name': officialName,
      if (mask != null) 'mask': mask,
      if (currency != null) 'currency': currency,
      if (currentBalanceMinor != null)
        'current_balance_minor': currentBalanceMinor,
      if (availableBalanceMinor != null)
        'available_balance_minor': availableBalanceMinor,
      if (creditLimitMinor != null) 'credit_limit_minor': creditLimitMinor,
      if (balancesAsOf != null) 'balances_as_of': balancesAsOf,
      if (isHidden != null) 'is_hidden': isHidden,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String?>? itemId,
    Value<AccountType>? type,
    Value<String?>? subtype,
    Value<String>? name,
    Value<String?>? officialName,
    Value<String?>? mask,
    Value<String>? currency,
    Value<int?>? currentBalanceMinor,
    Value<int?>? availableBalanceMinor,
    Value<int?>? creditLimitMinor,
    Value<DateTime?>? balancesAsOf,
    Value<bool>? isHidden,
    Value<int>? displayOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      name: name ?? this.name,
      officialName: officialName ?? this.officialName,
      mask: mask ?? this.mask,
      currency: currency ?? this.currency,
      currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
      availableBalanceMinor:
          availableBalanceMinor ?? this.availableBalanceMinor,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      balancesAsOf: balancesAsOf ?? this.balancesAsOf,
      isHidden: isHidden ?? this.isHidden,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (officialName.present) {
      map['official_name'] = Variable<String>(officialName.value);
    }
    if (mask.present) {
      map['mask'] = Variable<String>(mask.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (currentBalanceMinor.present) {
      map['current_balance_minor'] = Variable<int>(currentBalanceMinor.value);
    }
    if (availableBalanceMinor.present) {
      map['available_balance_minor'] = Variable<int>(
        availableBalanceMinor.value,
      );
    }
    if (creditLimitMinor.present) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor.value);
    }
    if (balancesAsOf.present) {
      map['balances_as_of'] = Variable<int>(
        $AccountsTable.$converterbalancesAsOfn.toSql(balancesAsOf.value),
      );
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AccountsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AccountsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $AccountsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('name: $name, ')
          ..write('officialName: $officialName, ')
          ..write('mask: $mask, ')
          ..write('currency: $currency, ')
          ..write('currentBalanceMinor: $currentBalanceMinor, ')
          ..write('availableBalanceMinor: $availableBalanceMinor, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('balancesAsOf: $balancesAsOf, ')
          ..write('isHidden: $isHidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($TransactionsTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  authorizedDate = GeneratedColumn<String>(
    'authorized_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($TransactionsTable.$converterauthorizedDaten);
  static const VerificationMeta _pendingMeta = const VerificationMeta(
    'pending',
  );
  @override
  late final GeneratedColumn<bool> pending = GeneratedColumn<bool>(
    'pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending" IN (0, 1))',
    ),
  );
  static const VerificationMeta _pendingTransactionIdMeta =
      const VerificationMeta('pendingTransactionId');
  @override
  late final GeneratedColumn<String> pendingTransactionId =
      GeneratedColumn<String>(
        'pending_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Uri?, String> merchantLogoUrl =
      GeneratedColumn<String>(
        'merchant_logo_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Uri?>($TransactionsTable.$convertermerchantLogoUrln);
  static const VerificationMeta _plaidPrimaryCategoryMeta =
      const VerificationMeta('plaidPrimaryCategory');
  @override
  late final GeneratedColumn<String> plaidPrimaryCategory =
      GeneratedColumn<String>(
        'plaid_primary_category',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _plaidDetailedCategoryMeta =
      const VerificationMeta('plaidDetailedCategory');
  @override
  late final GeneratedColumn<String> plaidDetailedCategory =
      GeneratedColumn<String>(
        'plaid_detailed_category',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _userCategoryIdMeta = const VerificationMeta(
    'userCategoryId',
  );
  @override
  late final GeneratedColumn<String> userCategoryId = GeneratedColumn<String>(
    'user_category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptPathMeta = const VerificationMeta(
    'receiptPath',
  );
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
    'receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptSha256Meta = const VerificationMeta(
    'receiptSha256',
  );
  @override
  late final GeneratedColumn<String> receiptSha256 = GeneratedColumn<String>(
    'receipt_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>($TransactionsTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TransactionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TransactionsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TransactionsTable.$converterdeletedAtn);
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedWithAccountMeta =
      const VerificationMeta('deletedWithAccount');
  @override
  late final GeneratedColumn<bool> deletedWithAccount = GeneratedColumn<bool>(
    'deleted_with_account',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_with_account" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    amountMinor,
    currency,
    date,
    authorizedDate,
    pending,
    pendingTransactionId,
    name,
    merchantName,
    merchantLogoUrl,
    plaidPrimaryCategory,
    plaidDetailedCategory,
    userCategoryId,
    notes,
    receiptPath,
    receiptSha256,
    hidden,
    source,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
    deletedWithAccount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('pending')) {
      context.handle(
        _pendingMeta,
        pending.isAcceptableOrUnknown(data['pending']!, _pendingMeta),
      );
    } else if (isInserting) {
      context.missing(_pendingMeta);
    }
    if (data.containsKey('pending_transaction_id')) {
      context.handle(
        _pendingTransactionIdMeta,
        pendingTransactionId.isAcceptableOrUnknown(
          data['pending_transaction_id']!,
          _pendingTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    }
    if (data.containsKey('plaid_primary_category')) {
      context.handle(
        _plaidPrimaryCategoryMeta,
        plaidPrimaryCategory.isAcceptableOrUnknown(
          data['plaid_primary_category']!,
          _plaidPrimaryCategoryMeta,
        ),
      );
    }
    if (data.containsKey('plaid_detailed_category')) {
      context.handle(
        _plaidDetailedCategoryMeta,
        plaidDetailedCategory.isAcceptableOrUnknown(
          data['plaid_detailed_category']!,
          _plaidDetailedCategoryMeta,
        ),
      );
    }
    if (data.containsKey('user_category_id')) {
      context.handle(
        _userCategoryIdMeta,
        userCategoryId.isAcceptableOrUnknown(
          data['user_category_id']!,
          _userCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
        _receiptPathMeta,
        receiptPath.isAcceptableOrUnknown(
          data['receipt_path']!,
          _receiptPathMeta,
        ),
      );
    }
    if (data.containsKey('receipt_sha256')) {
      context.handle(
        _receiptSha256Meta,
        receiptSha256.isAcceptableOrUnknown(
          data['receipt_sha256']!,
          _receiptSha256Meta,
        ),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_with_account')) {
      context.handle(
        _deletedWithAccountMeta,
        deletedWithAccount.isAcceptableOrUnknown(
          data['deleted_with_account']!,
          _deletedWithAccountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      date: $TransactionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      authorizedDate: $TransactionsTable.$converterauthorizedDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}authorized_date'],
        ),
      ),
      pending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending'],
      )!,
      pendingTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_transaction_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      ),
      merchantLogoUrl: $TransactionsTable.$convertermerchantLogoUrln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}merchant_logo_url'],
        ),
      ),
      plaidPrimaryCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plaid_primary_category'],
      ),
      plaidDetailedCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plaid_detailed_category'],
      ),
      userCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_category_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      receiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_path'],
      ),
      receiptSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_sha256'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      source: $TransactionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      createdAt: $TransactionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $TransactionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $TransactionsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      deletedWithAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_with_account'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate, String> $converterauthorizedDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterauthorizedDaten =
      NullAwareTypeConverter.wrap($converterauthorizedDate);
  static TypeConverter<Uri, String> $convertermerchantLogoUrl =
      const UriColumnConverter();
  static TypeConverter<Uri?, String?> $convertermerchantLogoUrln =
      NullAwareTypeConverter.wrap($convertermerchantLogoUrl);
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String accountId;
  final int amountMinor;
  final String currency;
  final LocalDate date;
  final LocalDate? authorizedDate;
  final bool pending;
  final String? pendingTransactionId;
  final String name;
  final String? merchantName;
  final Uri? merchantLogoUrl;
  final String? plaidPrimaryCategory;
  final String? plaidDetailedCategory;
  final String? userCategoryId;
  final String? notes;
  final String? receiptPath;

  /// The SHA-256 of the receipt photo's bytes (schema 13), by which a device without the
  /// file fetches it.
  final String? receiptSha256;

  /// The user's hidden override (schema 5): the row still counts toward its account's
  /// balance and leaves the default list, budgets and reports.
  final bool hidden;
  final DataSource source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int syncVersion;

  /// Whether this row was deleted by its account's delete, so the account's restore brings
  /// back exactly these rows (and not one deleted on its own, whatever its instant).
  final bool deletedWithAccount;
  const TransactionRow({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.authorizedDate,
    required this.pending,
    this.pendingTransactionId,
    required this.name,
    this.merchantName,
    this.merchantLogoUrl,
    this.plaidPrimaryCategory,
    this.plaidDetailedCategory,
    this.userCategoryId,
    this.notes,
    this.receiptPath,
    this.receiptSha256,
    required this.hidden,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncVersion,
    required this.deletedWithAccount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date),
      );
    }
    if (!nullToAbsent || authorizedDate != null) {
      map['authorized_date'] = Variable<String>(
        $TransactionsTable.$converterauthorizedDaten.toSql(authorizedDate),
      );
    }
    map['pending'] = Variable<bool>(pending);
    if (!nullToAbsent || pendingTransactionId != null) {
      map['pending_transaction_id'] = Variable<String>(pendingTransactionId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || merchantName != null) {
      map['merchant_name'] = Variable<String>(merchantName);
    }
    if (!nullToAbsent || merchantLogoUrl != null) {
      map['merchant_logo_url'] = Variable<String>(
        $TransactionsTable.$convertermerchantLogoUrln.toSql(merchantLogoUrl),
      );
    }
    if (!nullToAbsent || plaidPrimaryCategory != null) {
      map['plaid_primary_category'] = Variable<String>(plaidPrimaryCategory);
    }
    if (!nullToAbsent || plaidDetailedCategory != null) {
      map['plaid_detailed_category'] = Variable<String>(plaidDetailedCategory);
    }
    if (!nullToAbsent || userCategoryId != null) {
      map['user_category_id'] = Variable<String>(userCategoryId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    if (!nullToAbsent || receiptSha256 != null) {
      map['receipt_sha256'] = Variable<String>(receiptSha256);
    }
    map['hidden'] = Variable<bool>(hidden);
    {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $TransactionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $TransactionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $TransactionsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['sync_version'] = Variable<int>(syncVersion);
    map['deleted_with_account'] = Variable<bool>(deletedWithAccount);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      date: Value(date),
      authorizedDate: authorizedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(authorizedDate),
      pending: Value(pending),
      pendingTransactionId: pendingTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingTransactionId),
      name: Value(name),
      merchantName: merchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantName),
      merchantLogoUrl: merchantLogoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantLogoUrl),
      plaidPrimaryCategory: plaidPrimaryCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(plaidPrimaryCategory),
      plaidDetailedCategory: plaidDetailedCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(plaidDetailedCategory),
      userCategoryId: userCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(userCategoryId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      receiptSha256: receiptSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptSha256),
      hidden: Value(hidden),
      source: Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
      deletedWithAccount: Value(deletedWithAccount),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      date: serializer.fromJson<LocalDate>(json['date']),
      authorizedDate: serializer.fromJson<LocalDate?>(json['authorizedDate']),
      pending: serializer.fromJson<bool>(json['pending']),
      pendingTransactionId: serializer.fromJson<String?>(
        json['pendingTransactionId'],
      ),
      name: serializer.fromJson<String>(json['name']),
      merchantName: serializer.fromJson<String?>(json['merchantName']),
      merchantLogoUrl: serializer.fromJson<Uri?>(json['merchantLogoUrl']),
      plaidPrimaryCategory: serializer.fromJson<String?>(
        json['plaidPrimaryCategory'],
      ),
      plaidDetailedCategory: serializer.fromJson<String?>(
        json['plaidDetailedCategory'],
      ),
      userCategoryId: serializer.fromJson<String?>(json['userCategoryId']),
      notes: serializer.fromJson<String?>(json['notes']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      receiptSha256: serializer.fromJson<String?>(json['receiptSha256']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      source: $TransactionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      deletedWithAccount: serializer.fromJson<bool>(json['deletedWithAccount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'date': serializer.toJson<LocalDate>(date),
      'authorizedDate': serializer.toJson<LocalDate?>(authorizedDate),
      'pending': serializer.toJson<bool>(pending),
      'pendingTransactionId': serializer.toJson<String?>(pendingTransactionId),
      'name': serializer.toJson<String>(name),
      'merchantName': serializer.toJson<String?>(merchantName),
      'merchantLogoUrl': serializer.toJson<Uri?>(merchantLogoUrl),
      'plaidPrimaryCategory': serializer.toJson<String?>(plaidPrimaryCategory),
      'plaidDetailedCategory': serializer.toJson<String?>(
        plaidDetailedCategory,
      ),
      'userCategoryId': serializer.toJson<String?>(userCategoryId),
      'notes': serializer.toJson<String?>(notes),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'receiptSha256': serializer.toJson<String?>(receiptSha256),
      'hidden': serializer.toJson<bool>(hidden),
      'source': serializer.toJson<String>(
        $TransactionsTable.$convertersource.toJson(source),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'deletedWithAccount': serializer.toJson<bool>(deletedWithAccount),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? accountId,
    int? amountMinor,
    String? currency,
    LocalDate? date,
    Value<LocalDate?> authorizedDate = const Value.absent(),
    bool? pending,
    Value<String?> pendingTransactionId = const Value.absent(),
    String? name,
    Value<String?> merchantName = const Value.absent(),
    Value<Uri?> merchantLogoUrl = const Value.absent(),
    Value<String?> plaidPrimaryCategory = const Value.absent(),
    Value<String?> plaidDetailedCategory = const Value.absent(),
    Value<String?> userCategoryId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> receiptPath = const Value.absent(),
    Value<String?> receiptSha256 = const Value.absent(),
    bool? hidden,
    DataSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
    bool? deletedWithAccount,
  }) => TransactionRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    authorizedDate: authorizedDate.present
        ? authorizedDate.value
        : this.authorizedDate,
    pending: pending ?? this.pending,
    pendingTransactionId: pendingTransactionId.present
        ? pendingTransactionId.value
        : this.pendingTransactionId,
    name: name ?? this.name,
    merchantName: merchantName.present ? merchantName.value : this.merchantName,
    merchantLogoUrl: merchantLogoUrl.present
        ? merchantLogoUrl.value
        : this.merchantLogoUrl,
    plaidPrimaryCategory: plaidPrimaryCategory.present
        ? plaidPrimaryCategory.value
        : this.plaidPrimaryCategory,
    plaidDetailedCategory: plaidDetailedCategory.present
        ? plaidDetailedCategory.value
        : this.plaidDetailedCategory,
    userCategoryId: userCategoryId.present
        ? userCategoryId.value
        : this.userCategoryId,
    notes: notes.present ? notes.value : this.notes,
    receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
    receiptSha256: receiptSha256.present
        ? receiptSha256.value
        : this.receiptSha256,
    hidden: hidden ?? this.hidden,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
    deletedWithAccount: deletedWithAccount ?? this.deletedWithAccount,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      date: data.date.present ? data.date.value : this.date,
      authorizedDate: data.authorizedDate.present
          ? data.authorizedDate.value
          : this.authorizedDate,
      pending: data.pending.present ? data.pending.value : this.pending,
      pendingTransactionId: data.pendingTransactionId.present
          ? data.pendingTransactionId.value
          : this.pendingTransactionId,
      name: data.name.present ? data.name.value : this.name,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      merchantLogoUrl: data.merchantLogoUrl.present
          ? data.merchantLogoUrl.value
          : this.merchantLogoUrl,
      plaidPrimaryCategory: data.plaidPrimaryCategory.present
          ? data.plaidPrimaryCategory.value
          : this.plaidPrimaryCategory,
      plaidDetailedCategory: data.plaidDetailedCategory.present
          ? data.plaidDetailedCategory.value
          : this.plaidDetailedCategory,
      userCategoryId: data.userCategoryId.present
          ? data.userCategoryId.value
          : this.userCategoryId,
      notes: data.notes.present ? data.notes.value : this.notes,
      receiptPath: data.receiptPath.present
          ? data.receiptPath.value
          : this.receiptPath,
      receiptSha256: data.receiptSha256.present
          ? data.receiptSha256.value
          : this.receiptSha256,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      deletedWithAccount: data.deletedWithAccount.present
          ? data.deletedWithAccount.value
          : this.deletedWithAccount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('authorizedDate: $authorizedDate, ')
          ..write('pending: $pending, ')
          ..write('pendingTransactionId: $pendingTransactionId, ')
          ..write('name: $name, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantLogoUrl: $merchantLogoUrl, ')
          ..write('plaidPrimaryCategory: $plaidPrimaryCategory, ')
          ..write('plaidDetailedCategory: $plaidDetailedCategory, ')
          ..write('userCategoryId: $userCategoryId, ')
          ..write('notes: $notes, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('receiptSha256: $receiptSha256, ')
          ..write('hidden: $hidden, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('deletedWithAccount: $deletedWithAccount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    amountMinor,
    currency,
    date,
    authorizedDate,
    pending,
    pendingTransactionId,
    name,
    merchantName,
    merchantLogoUrl,
    plaidPrimaryCategory,
    plaidDetailedCategory,
    userCategoryId,
    notes,
    receiptPath,
    receiptSha256,
    hidden,
    source,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
    deletedWithAccount,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.date == this.date &&
          other.authorizedDate == this.authorizedDate &&
          other.pending == this.pending &&
          other.pendingTransactionId == this.pendingTransactionId &&
          other.name == this.name &&
          other.merchantName == this.merchantName &&
          other.merchantLogoUrl == this.merchantLogoUrl &&
          other.plaidPrimaryCategory == this.plaidPrimaryCategory &&
          other.plaidDetailedCategory == this.plaidDetailedCategory &&
          other.userCategoryId == this.userCategoryId &&
          other.notes == this.notes &&
          other.receiptPath == this.receiptPath &&
          other.receiptSha256 == this.receiptSha256 &&
          other.hidden == this.hidden &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion &&
          other.deletedWithAccount == this.deletedWithAccount);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<LocalDate> date;
  final Value<LocalDate?> authorizedDate;
  final Value<bool> pending;
  final Value<String?> pendingTransactionId;
  final Value<String> name;
  final Value<String?> merchantName;
  final Value<Uri?> merchantLogoUrl;
  final Value<String?> plaidPrimaryCategory;
  final Value<String?> plaidDetailedCategory;
  final Value<String?> userCategoryId;
  final Value<String?> notes;
  final Value<String?> receiptPath;
  final Value<String?> receiptSha256;
  final Value<bool> hidden;
  final Value<DataSource> source;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<bool> deletedWithAccount;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.date = const Value.absent(),
    this.authorizedDate = const Value.absent(),
    this.pending = const Value.absent(),
    this.pendingTransactionId = const Value.absent(),
    this.name = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.merchantLogoUrl = const Value.absent(),
    this.plaidPrimaryCategory = const Value.absent(),
    this.plaidDetailedCategory = const Value.absent(),
    this.userCategoryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.receiptSha256 = const Value.absent(),
    this.hidden = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.deletedWithAccount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String accountId,
    required int amountMinor,
    required String currency,
    required LocalDate date,
    this.authorizedDate = const Value.absent(),
    required bool pending,
    this.pendingTransactionId = const Value.absent(),
    required String name,
    this.merchantName = const Value.absent(),
    this.merchantLogoUrl = const Value.absent(),
    this.plaidPrimaryCategory = const Value.absent(),
    this.plaidDetailedCategory = const Value.absent(),
    this.userCategoryId = const Value.absent(),
    this.notes = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.receiptSha256 = const Value.absent(),
    this.hidden = const Value.absent(),
    required DataSource source,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.deletedWithAccount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       date = Value(date),
       pending = Value(pending),
       name = Value(name),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? date,
    Expression<String>? authorizedDate,
    Expression<bool>? pending,
    Expression<String>? pendingTransactionId,
    Expression<String>? name,
    Expression<String>? merchantName,
    Expression<String>? merchantLogoUrl,
    Expression<String>? plaidPrimaryCategory,
    Expression<String>? plaidDetailedCategory,
    Expression<String>? userCategoryId,
    Expression<String>? notes,
    Expression<String>? receiptPath,
    Expression<String>? receiptSha256,
    Expression<bool>? hidden,
    Expression<String>? source,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncVersion,
    Expression<bool>? deletedWithAccount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (date != null) 'date': date,
      if (authorizedDate != null) 'authorized_date': authorizedDate,
      if (pending != null) 'pending': pending,
      if (pendingTransactionId != null)
        'pending_transaction_id': pendingTransactionId,
      if (name != null) 'name': name,
      if (merchantName != null) 'merchant_name': merchantName,
      if (merchantLogoUrl != null) 'merchant_logo_url': merchantLogoUrl,
      if (plaidPrimaryCategory != null)
        'plaid_primary_category': plaidPrimaryCategory,
      if (plaidDetailedCategory != null)
        'plaid_detailed_category': plaidDetailedCategory,
      if (userCategoryId != null) 'user_category_id': userCategoryId,
      if (notes != null) 'notes': notes,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (receiptSha256 != null) 'receipt_sha256': receiptSha256,
      if (hidden != null) 'hidden': hidden,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (deletedWithAccount != null)
        'deleted_with_account': deletedWithAccount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<LocalDate>? date,
    Value<LocalDate?>? authorizedDate,
    Value<bool>? pending,
    Value<String?>? pendingTransactionId,
    Value<String>? name,
    Value<String?>? merchantName,
    Value<Uri?>? merchantLogoUrl,
    Value<String?>? plaidPrimaryCategory,
    Value<String?>? plaidDetailedCategory,
    Value<String?>? userCategoryId,
    Value<String?>? notes,
    Value<String?>? receiptPath,
    Value<String?>? receiptSha256,
    Value<bool>? hidden,
    Value<DataSource>? source,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<bool>? deletedWithAccount,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      authorizedDate: authorizedDate ?? this.authorizedDate,
      pending: pending ?? this.pending,
      pendingTransactionId: pendingTransactionId ?? this.pendingTransactionId,
      name: name ?? this.name,
      merchantName: merchantName ?? this.merchantName,
      merchantLogoUrl: merchantLogoUrl ?? this.merchantLogoUrl,
      plaidPrimaryCategory: plaidPrimaryCategory ?? this.plaidPrimaryCategory,
      plaidDetailedCategory:
          plaidDetailedCategory ?? this.plaidDetailedCategory,
      userCategoryId: userCategoryId ?? this.userCategoryId,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
      receiptSha256: receiptSha256 ?? this.receiptSha256,
      hidden: hidden ?? this.hidden,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      deletedWithAccount: deletedWithAccount ?? this.deletedWithAccount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $TransactionsTable.$converterdate.toSql(date.value),
      );
    }
    if (authorizedDate.present) {
      map['authorized_date'] = Variable<String>(
        $TransactionsTable.$converterauthorizedDaten.toSql(
          authorizedDate.value,
        ),
      );
    }
    if (pending.present) {
      map['pending'] = Variable<bool>(pending.value);
    }
    if (pendingTransactionId.present) {
      map['pending_transaction_id'] = Variable<String>(
        pendingTransactionId.value,
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (merchantLogoUrl.present) {
      map['merchant_logo_url'] = Variable<String>(
        $TransactionsTable.$convertermerchantLogoUrln.toSql(
          merchantLogoUrl.value,
        ),
      );
    }
    if (plaidPrimaryCategory.present) {
      map['plaid_primary_category'] = Variable<String>(
        plaidPrimaryCategory.value,
      );
    }
    if (plaidDetailedCategory.present) {
      map['plaid_detailed_category'] = Variable<String>(
        plaidDetailedCategory.value,
      );
    }
    if (userCategoryId.present) {
      map['user_category_id'] = Variable<String>(userCategoryId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (receiptSha256.present) {
      map['receipt_sha256'] = Variable<String>(receiptSha256.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $TransactionsTable.$convertersource.toSql(source.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $TransactionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $TransactionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $TransactionsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (deletedWithAccount.present) {
      map['deleted_with_account'] = Variable<bool>(deletedWithAccount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('authorizedDate: $authorizedDate, ')
          ..write('pending: $pending, ')
          ..write('pendingTransactionId: $pendingTransactionId, ')
          ..write('name: $name, ')
          ..write('merchantName: $merchantName, ')
          ..write('merchantLogoUrl: $merchantLogoUrl, ')
          ..write('plaidPrimaryCategory: $plaidPrimaryCategory, ')
          ..write('plaidDetailedCategory: $plaidDetailedCategory, ')
          ..write('userCategoryId: $userCategoryId, ')
          ..write('notes: $notes, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('receiptSha256: $receiptSha256, ')
          ..write('hidden: $hidden, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('deletedWithAccount: $deletedWithAccount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionTagsTable extends TransactionTags
    with TableInfo<$TransactionTagsTable, TransactionTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [transactionId, position, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, position};
  @override
  TransactionTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionTagRow(
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $TransactionTagsTable createAlias(String alias) {
    return $TransactionTagsTable(attachedDatabase, alias);
  }
}

class TransactionTagRow extends DataClass
    implements Insertable<TransactionTagRow> {
  final String transactionId;
  final int position;
  final String tag;
  const TransactionTagRow({
    required this.transactionId,
    required this.position,
    required this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['position'] = Variable<int>(position);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  TransactionTagsCompanion toCompanion(bool nullToAbsent) {
    return TransactionTagsCompanion(
      transactionId: Value(transactionId),
      position: Value(position),
      tag: Value(tag),
    );
  }

  factory TransactionTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionTagRow(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      position: serializer.fromJson<int>(json['position']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'position': serializer.toJson<int>(position),
      'tag': serializer.toJson<String>(tag),
    };
  }

  TransactionTagRow copyWith({
    String? transactionId,
    int? position,
    String? tag,
  }) => TransactionTagRow(
    transactionId: transactionId ?? this.transactionId,
    position: position ?? this.position,
    tag: tag ?? this.tag,
  );
  TransactionTagRow copyWithCompanion(TransactionTagsCompanion data) {
    return TransactionTagRow(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      position: data.position.present ? data.position.value : this.position,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagRow(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(transactionId, position, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionTagRow &&
          other.transactionId == this.transactionId &&
          other.position == this.position &&
          other.tag == this.tag);
}

class TransactionTagsCompanion extends UpdateCompanion<TransactionTagRow> {
  final Value<String> transactionId;
  final Value<int> position;
  final Value<String> tag;
  final Value<int> rowid;
  const TransactionTagsCompanion({
    this.transactionId = const Value.absent(),
    this.position = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionTagsCompanion.insert({
    required String transactionId,
    required int position,
    required String tag,
    this.rowid = const Value.absent(),
  }) : transactionId = Value(transactionId),
       position = Value(position),
       tag = Value(tag);
  static Insertable<TransactionTagRow> custom({
    Expression<String>? transactionId,
    Expression<int>? position,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (position != null) 'position': position,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionTagsCompanion copyWith({
    Value<String>? transactionId,
    Value<int>? position,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return TransactionTagsCompanion(
      transactionId: transactionId ?? this.transactionId,
      position: position ?? this.position,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionTagsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionSplitsTable extends TransactionSplits
    with TableInfo<$TransactionSplitsTable, TransactionSplitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionSplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    transactionId,
    position,
    categoryId,
    amountMinor,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_splits';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionSplitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId, position};
  @override
  TransactionSplitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionSplitRow(
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TransactionSplitsTable createAlias(String alias) {
    return $TransactionSplitsTable(attachedDatabase, alias);
  }
}

class TransactionSplitRow extends DataClass
    implements Insertable<TransactionSplitRow> {
  final String transactionId;
  final int position;
  final String categoryId;
  final int amountMinor;
  final String? note;
  const TransactionSplitRow({
    required this.transactionId,
    required this.position,
    required this.categoryId,
    required this.amountMinor,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['position'] = Variable<int>(position);
    map['category_id'] = Variable<String>(categoryId);
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransactionSplitsCompanion toCompanion(bool nullToAbsent) {
    return TransactionSplitsCompanion(
      transactionId: Value(transactionId),
      position: Value(position),
      categoryId: Value(categoryId),
      amountMinor: Value(amountMinor),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TransactionSplitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionSplitRow(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      position: serializer.fromJson<int>(json['position']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'position': serializer.toJson<int>(position),
      'categoryId': serializer.toJson<String>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'note': serializer.toJson<String?>(note),
    };
  }

  TransactionSplitRow copyWith({
    String? transactionId,
    int? position,
    String? categoryId,
    int? amountMinor,
    Value<String?> note = const Value.absent(),
  }) => TransactionSplitRow(
    transactionId: transactionId ?? this.transactionId,
    position: position ?? this.position,
    categoryId: categoryId ?? this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    note: note.present ? note.value : this.note,
  );
  TransactionSplitRow copyWithCompanion(TransactionSplitsCompanion data) {
    return TransactionSplitRow(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      position: data.position.present ? data.position.value : this.position,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionSplitRow(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(transactionId, position, categoryId, amountMinor, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionSplitRow &&
          other.transactionId == this.transactionId &&
          other.position == this.position &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.note == this.note);
}

class TransactionSplitsCompanion extends UpdateCompanion<TransactionSplitRow> {
  final Value<String> transactionId;
  final Value<int> position;
  final Value<String> categoryId;
  final Value<int> amountMinor;
  final Value<String?> note;
  final Value<int> rowid;
  const TransactionSplitsCompanion({
    this.transactionId = const Value.absent(),
    this.position = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionSplitsCompanion.insert({
    required String transactionId,
    required int position,
    required String categoryId,
    required int amountMinor,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : transactionId = Value(transactionId),
       position = Value(position),
       categoryId = Value(categoryId),
       amountMinor = Value(amountMinor);
  static Insertable<TransactionSplitRow> custom({
    Expression<String>? transactionId,
    Expression<int>? position,
    Expression<String>? categoryId,
    Expression<int>? amountMinor,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (position != null) 'position': position,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionSplitsCompanion copyWith({
    Value<String>? transactionId,
    Value<int>? position,
    Value<String>? categoryId,
    Value<int>? amountMinor,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TransactionSplitsCompanion(
      transactionId: transactionId ?? this.transactionId,
      position: position ?? this.position,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionSplitsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('position: $position, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plaidCategoryMeta = const VerificationMeta(
    'plaidCategory',
  );
  @override
  late final GeneratedColumn<String> plaidCategory = GeneratedColumn<String>(
    'plaid_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CategoriesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CategoriesTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CategoriesTable.$converterdeletedAtn);
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    isSystem,
    icon,
    color,
    plaidCategory,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    } else if (isInserting) {
      context.missing(_isSystemMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('plaid_category')) {
      context.handle(
        _plaidCategoryMeta,
        plaidCategory.isAcceptableOrUnknown(
          data['plaid_category']!,
          _plaidCategoryMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      plaidCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plaid_category'],
      ),
      createdAt: $CategoriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $CategoriesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $CategoriesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String? parentId;
  final bool isSystem;
  final String icon;
  final int color;
  final String? plaidCategory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int syncVersion;
  const CategoryRow({
    required this.id,
    required this.name,
    this.parentId,
    required this.isSystem,
    required this.icon,
    required this.color,
    this.plaidCategory,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || plaidCategory != null) {
      map['plaid_category'] = Variable<String>(plaidCategory);
    }
    {
      map['created_at'] = Variable<int>(
        $CategoriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $CategoriesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $CategoriesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      isSystem: Value(isSystem),
      icon: Value(icon),
      color: Value(color),
      plaidCategory: plaidCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(plaidCategory),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      plaidCategory: serializer.fromJson<String?>(json['plaidCategory']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'isSystem': serializer.toJson<bool>(isSystem),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'plaidCategory': serializer.toJson<String?>(plaidCategory),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    bool? isSystem,
    String? icon,
    int? color,
    Value<String?> plaidCategory = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    isSystem: isSystem ?? this.isSystem,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    plaidCategory: plaidCategory.present
        ? plaidCategory.value
        : this.plaidCategory,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      plaidCategory: data.plaidCategory.present
          ? data.plaidCategory.value
          : this.plaidCategory,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('isSystem: $isSystem, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('plaidCategory: $plaidCategory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    parentId,
    isSystem,
    icon,
    color,
    plaidCategory,
    createdAt,
    updatedAt,
    deletedAt,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.isSystem == this.isSystem &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.plaidCategory == this.plaidCategory &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<bool> isSystem;
  final Value<String> icon;
  final Value<int> color;
  final Value<String?> plaidCategory;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.plaidCategory = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required bool isSystem,
    required String icon,
    required int color,
    this.plaidCategory = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       isSystem = Value(isSystem),
       icon = Value(icon),
       color = Value(color),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<bool>? isSystem,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<String>? plaidCategory,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (isSystem != null) 'is_system': isSystem,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (plaidCategory != null) 'plaid_category': plaidCategory,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<bool>? isSystem,
    Value<String>? icon,
    Value<int>? color,
    Value<String?>? plaidCategory,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      isSystem: isSystem ?? this.isSystem,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      plaidCategory: plaidCategory ?? this.plaidCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (plaidCategory.present) {
      map['plaid_category'] = Variable<String>(plaidCategory.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CategoriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $CategoriesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $CategoriesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('isSystem: $isSystem, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('plaidCategory: $plaidCategory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeLogTable extends ChangeLog
    with TableInfo<$ChangeLogTable, ChangeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rejectedReasonMeta = const VerificationMeta(
    'rejectedReason',
  );
  @override
  late final GeneratedColumn<String> rejectedReason = GeneratedColumn<String>(
    'rejected_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    entityType,
    entityId,
    operation,
    payload,
    hlc,
    deviceId,
    synced,
    rejectedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('rejected_reason')) {
      context.handle(
        _rejectedReasonMeta,
        rejectedReason.isAcceptableOrUnknown(
          data['rejected_reason']!,
          _rejectedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  ChangeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      rejectedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_reason'],
      ),
    );
  }

  @override
  $ChangeLogTable createAlias(String alias) {
    return $ChangeLogTable(attachedDatabase, alias);
  }
}

class ChangeLogRow extends DataClass implements Insertable<ChangeLogRow> {
  final int seq;
  final String entityType;
  final String entityId;
  final String operation;
  final String payload;
  final String hlc;
  final String deviceId;
  final bool synced;
  final String? rejectedReason;
  const ChangeLogRow({
    required this.seq,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.hlc,
    required this.deviceId,
    required this.synced,
    this.rejectedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    map['hlc'] = Variable<String>(hlc);
    map['device_id'] = Variable<String>(deviceId);
    map['synced'] = Variable<bool>(synced);
    if (!nullToAbsent || rejectedReason != null) {
      map['rejected_reason'] = Variable<String>(rejectedReason);
    }
    return map;
  }

  ChangeLogCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogCompanion(
      seq: Value(seq),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payload: Value(payload),
      hlc: Value(hlc),
      deviceId: Value(deviceId),
      synced: Value(synced),
      rejectedReason: rejectedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedReason),
    );
  }

  factory ChangeLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogRow(
      seq: serializer.fromJson<int>(json['seq']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      synced: serializer.fromJson<bool>(json['synced']),
      rejectedReason: serializer.fromJson<String?>(json['rejectedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'hlc': serializer.toJson<String>(hlc),
      'deviceId': serializer.toJson<String>(deviceId),
      'synced': serializer.toJson<bool>(synced),
      'rejectedReason': serializer.toJson<String?>(rejectedReason),
    };
  }

  ChangeLogRow copyWith({
    int? seq,
    String? entityType,
    String? entityId,
    String? operation,
    String? payload,
    String? hlc,
    String? deviceId,
    bool? synced,
    Value<String?> rejectedReason = const Value.absent(),
  }) => ChangeLogRow(
    seq: seq ?? this.seq,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    hlc: hlc ?? this.hlc,
    deviceId: deviceId ?? this.deviceId,
    synced: synced ?? this.synced,
    rejectedReason: rejectedReason.present
        ? rejectedReason.value
        : this.rejectedReason,
  );
  ChangeLogRow copyWithCompanion(ChangeLogCompanion data) {
    return ChangeLogRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      synced: data.synced.present ? data.synced.value : this.synced,
      rejectedReason: data.rejectedReason.present
          ? data.rejectedReason.value
          : this.rejectedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogRow(')
          ..write('seq: $seq, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('hlc: $hlc, ')
          ..write('deviceId: $deviceId, ')
          ..write('synced: $synced, ')
          ..write('rejectedReason: $rejectedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    entityType,
    entityId,
    operation,
    payload,
    hlc,
    deviceId,
    synced,
    rejectedReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogRow &&
          other.seq == this.seq &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.hlc == this.hlc &&
          other.deviceId == this.deviceId &&
          other.synced == this.synced &&
          other.rejectedReason == this.rejectedReason);
}

class ChangeLogCompanion extends UpdateCompanion<ChangeLogRow> {
  final Value<int> seq;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<String> hlc;
  final Value<String> deviceId;
  final Value<bool> synced;
  final Value<String?> rejectedReason;
  const ChangeLogCompanion({
    this.seq = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.synced = const Value.absent(),
    this.rejectedReason = const Value.absent(),
  });
  ChangeLogCompanion.insert({
    this.seq = const Value.absent(),
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
    required String hlc,
    required String deviceId,
    this.synced = const Value.absent(),
    this.rejectedReason = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       hlc = Value(hlc),
       deviceId = Value(deviceId);
  static Insertable<ChangeLogRow> custom({
    Expression<int>? seq,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<String>? hlc,
    Expression<String>? deviceId,
    Expression<bool>? synced,
    Expression<String>? rejectedReason,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (hlc != null) 'hlc': hlc,
      if (deviceId != null) 'device_id': deviceId,
      if (synced != null) 'synced': synced,
      if (rejectedReason != null) 'rejected_reason': rejectedReason,
    });
  }

  ChangeLogCompanion copyWith({
    Value<int>? seq,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payload,
    Value<String>? hlc,
    Value<String>? deviceId,
    Value<bool>? synced,
    Value<String?>? rejectedReason,
  }) {
    return ChangeLogCompanion(
      seq: seq ?? this.seq,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      hlc: hlc ?? this.hlc,
      deviceId: deviceId ?? this.deviceId,
      synced: synced ?? this.synced,
      rejectedReason: rejectedReason ?? this.rejectedReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rejectedReason.present) {
      map['rejected_reason'] = Variable<String>(rejectedReason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogCompanion(')
          ..write('seq: $seq, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('hlc: $hlc, ')
          ..write('deviceId: $deviceId, ')
          ..write('synced: $synced, ')
          ..write('rejectedReason: $rejectedReason')
          ..write(')'))
        .toString();
  }
}

class $RecordClocksTable extends RecordClocks
    with TableInfo<$RecordClocksTable, RecordClockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordClocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityType, entityId, field, hlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_clocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordClockRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId, field};
  @override
  RecordClockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordClockRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
    );
  }

  @override
  $RecordClocksTable createAlias(String alias) {
    return $RecordClocksTable(attachedDatabase, alias);
  }
}

class RecordClockRow extends DataClass implements Insertable<RecordClockRow> {
  final String entityType;
  final String entityId;
  final String field;
  final String hlc;
  const RecordClockRow({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.hlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['field'] = Variable<String>(field);
    map['hlc'] = Variable<String>(hlc);
    return map;
  }

  RecordClocksCompanion toCompanion(bool nullToAbsent) {
    return RecordClocksCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      field: Value(field),
      hlc: Value(hlc),
    );
  }

  factory RecordClockRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordClockRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      field: serializer.fromJson<String>(json['field']),
      hlc: serializer.fromJson<String>(json['hlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'field': serializer.toJson<String>(field),
      'hlc': serializer.toJson<String>(hlc),
    };
  }

  RecordClockRow copyWith({
    String? entityType,
    String? entityId,
    String? field,
    String? hlc,
  }) => RecordClockRow(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    field: field ?? this.field,
    hlc: hlc ?? this.hlc,
  );
  RecordClockRow copyWithCompanion(RecordClocksCompanion data) {
    return RecordClockRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      field: data.field.present ? data.field.value : this.field,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordClockRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('hlc: $hlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, field, hlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordClockRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.field == this.field &&
          other.hlc == this.hlc);
}

class RecordClocksCompanion extends UpdateCompanion<RecordClockRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> field;
  final Value<String> hlc;
  final Value<int> rowid;
  const RecordClocksCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.field = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordClocksCompanion.insert({
    required String entityType,
    required String entityId,
    required String field,
    required String hlc,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       field = Value(field),
       hlc = Value(hlc);
  static Insertable<RecordClockRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? field,
    Expression<String>? hlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (field != null) 'field': field,
      if (hlc != null) 'hlc': hlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordClocksCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? field,
    Value<String>? hlc,
    Value<int>? rowid,
  }) {
    return RecordClocksCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      field: field ?? this.field,
      hlc: hlc ?? this.hlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordClocksCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('hlc: $hlc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String key;
  final String value;
  const SyncMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(key: Value(key), value: Value(value));
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaRow copyWith({String? key, String? value}) =>
      SyncMetaRow(key: key ?? this.key, value: value ?? this.value);
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HeldRecordsTable extends HeldRecords
    with TableInfo<$HeldRecordsTable, HeldRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HeldRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldsMeta = const VerificationMeta('fields');
  @override
  late final GeneratedColumn<String> fields = GeneratedColumn<String>(
    'fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entityType, entityId, fields, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'held_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<HeldRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('fields')) {
      context.handle(
        _fieldsMeta,
        fields.isAcceptableOrUnknown(data['fields']!, _fieldsMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldsMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId};
  @override
  HeldRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HeldRecordRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      fields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $HeldRecordsTable createAlias(String alias) {
    return $HeldRecordsTable(attachedDatabase, alias);
  }
}

class HeldRecordRow extends DataClass implements Insertable<HeldRecordRow> {
  final String entityType;
  final String entityId;
  final String fields;
  final String reason;
  const HeldRecordRow({
    required this.entityType,
    required this.entityId,
    required this.fields,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['fields'] = Variable<String>(fields);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  HeldRecordsCompanion toCompanion(bool nullToAbsent) {
    return HeldRecordsCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      fields: Value(fields),
      reason: Value(reason),
    );
  }

  factory HeldRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HeldRecordRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      fields: serializer.fromJson<String>(json['fields']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'fields': serializer.toJson<String>(fields),
      'reason': serializer.toJson<String>(reason),
    };
  }

  HeldRecordRow copyWith({
    String? entityType,
    String? entityId,
    String? fields,
    String? reason,
  }) => HeldRecordRow(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    fields: fields ?? this.fields,
    reason: reason ?? this.reason,
  );
  HeldRecordRow copyWithCompanion(HeldRecordsCompanion data) {
    return HeldRecordRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      fields: data.fields.present ? data.fields.value : this.fields,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HeldRecordRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fields: $fields, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, fields, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeldRecordRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.fields == this.fields &&
          other.reason == this.reason);
}

class HeldRecordsCompanion extends UpdateCompanion<HeldRecordRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> fields;
  final Value<String> reason;
  final Value<int> rowid;
  const HeldRecordsCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.fields = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HeldRecordsCompanion.insert({
    required String entityType,
    required String entityId,
    required String fields,
    required String reason,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       fields = Value(fields),
       reason = Value(reason);
  static Insertable<HeldRecordRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? fields,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (fields != null) 'fields': fields,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HeldRecordsCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? fields,
    Value<String>? reason,
    Value<int>? rowid,
  }) {
    return HeldRecordsCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      fields: fields ?? this.fields,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (fields.present) {
      map['fields'] = Variable<String>(fields.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HeldRecordsCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('fields: $fields, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionIdMeta = const VerificationMeta(
    'institutionId',
  );
  @override
  late final GeneratedColumn<String> institutionId = GeneratedColumn<String>(
    'institution_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _institutionNameMeta = const VerificationMeta(
    'institutionName',
  );
  @override
  late final GeneratedColumn<String> institutionName = GeneratedColumn<String>(
    'institution_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Uri?, String> institutionLogoUrl =
      GeneratedColumn<String>(
        'institution_logo_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Uri?>($ItemsTable.$converterinstitutionLogoUrln);
  static const VerificationMeta _institutionLogoMeta = const VerificationMeta(
    'institutionLogo',
  );
  @override
  late final GeneratedColumn<Uint8List> institutionLogo =
      GeneratedColumn<Uint8List>(
        'institution_logo',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _institutionColorMeta = const VerificationMeta(
    'institutionColor',
  );
  @override
  late final GeneratedColumn<int> institutionColor = GeneratedColumn<int>(
    'institution_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemStatus>($ItemsTable.$converterstatus);
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  lastSuccessfulSyncAt = GeneratedColumn<int>(
    'last_successful_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($ItemsTable.$converterlastSuccessfulSyncAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ItemsTable.$converterpulledAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    institutionId,
    institutionName,
    institutionLogoUrl,
    institutionLogo,
    institutionColor,
    status,
    errorCode,
    lastSuccessfulSyncAt,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('institution_id')) {
      context.handle(
        _institutionIdMeta,
        institutionId.isAcceptableOrUnknown(
          data['institution_id']!,
          _institutionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionIdMeta);
    }
    if (data.containsKey('institution_name')) {
      context.handle(
        _institutionNameMeta,
        institutionName.isAcceptableOrUnknown(
          data['institution_name']!,
          _institutionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionNameMeta);
    }
    if (data.containsKey('institution_logo')) {
      context.handle(
        _institutionLogoMeta,
        institutionLogo.isAcceptableOrUnknown(
          data['institution_logo']!,
          _institutionLogoMeta,
        ),
      );
    }
    if (data.containsKey('institution_color')) {
      context.handle(
        _institutionColorMeta,
        institutionColor.isAcceptableOrUnknown(
          data['institution_color']!,
          _institutionColorMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      institutionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_id'],
      )!,
      institutionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_name'],
      )!,
      institutionLogoUrl: $ItemsTable.$converterinstitutionLogoUrln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}institution_logo_url'],
        ),
      ),
      institutionLogo: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}institution_logo'],
      ),
      institutionColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}institution_color'],
      ),
      status: $ItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      lastSuccessfulSyncAt: $ItemsTable.$converterlastSuccessfulSyncAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_successful_sync_at'],
        ),
      ),
      pulledAt: $ItemsTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<Uri, String> $converterinstitutionLogoUrl =
      const UriColumnConverter();
  static TypeConverter<Uri?, String?> $converterinstitutionLogoUrln =
      NullAwareTypeConverter.wrap($converterinstitutionLogoUrl);
  static TypeConverter<ItemStatus, String> $converterstatus =
      const ItemStatusColumnConverter();
  static TypeConverter<DateTime, int> $converterlastSuccessfulSyncAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterlastSuccessfulSyncAtn =
      NullAwareTypeConverter.wrap($converterlastSuccessfulSyncAt);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final String id;
  final String institutionId;
  final String institutionName;
  final Uri? institutionLogoUrl;
  final Uint8List? institutionLogo;
  final int? institutionColor;
  final ItemStatus status;
  final String? errorCode;
  final DateTime? lastSuccessfulSyncAt;
  final DateTime pulledAt;
  const ItemRow({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    this.institutionLogoUrl,
    this.institutionLogo,
    this.institutionColor,
    required this.status,
    this.errorCode,
    this.lastSuccessfulSyncAt,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['institution_id'] = Variable<String>(institutionId);
    map['institution_name'] = Variable<String>(institutionName);
    if (!nullToAbsent || institutionLogoUrl != null) {
      map['institution_logo_url'] = Variable<String>(
        $ItemsTable.$converterinstitutionLogoUrln.toSql(institutionLogoUrl),
      );
    }
    if (!nullToAbsent || institutionLogo != null) {
      map['institution_logo'] = Variable<Uint8List>(institutionLogo);
    }
    if (!nullToAbsent || institutionColor != null) {
      map['institution_color'] = Variable<int>(institutionColor);
    }
    {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<int>(
        $ItemsTable.$converterlastSuccessfulSyncAtn.toSql(lastSuccessfulSyncAt),
      );
    }
    {
      map['pulled_at'] = Variable<int>(
        $ItemsTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      institutionId: Value(institutionId),
      institutionName: Value(institutionName),
      institutionLogoUrl: institutionLogoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionLogoUrl),
      institutionLogo: institutionLogo == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionLogo),
      institutionColor: institutionColor == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionColor),
      status: Value(status),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      pulledAt: Value(pulledAt),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      id: serializer.fromJson<String>(json['id']),
      institutionId: serializer.fromJson<String>(json['institutionId']),
      institutionName: serializer.fromJson<String>(json['institutionName']),
      institutionLogoUrl: serializer.fromJson<Uri?>(json['institutionLogoUrl']),
      institutionLogo: serializer.fromJson<Uint8List?>(json['institutionLogo']),
      institutionColor: serializer.fromJson<int?>(json['institutionColor']),
      status: serializer.fromJson<ItemStatus>(json['status']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'institutionId': serializer.toJson<String>(institutionId),
      'institutionName': serializer.toJson<String>(institutionName),
      'institutionLogoUrl': serializer.toJson<Uri?>(institutionLogoUrl),
      'institutionLogo': serializer.toJson<Uint8List?>(institutionLogo),
      'institutionColor': serializer.toJson<int?>(institutionColor),
      'status': serializer.toJson<ItemStatus>(status),
      'errorCode': serializer.toJson<String?>(errorCode),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  ItemRow copyWith({
    String? id,
    String? institutionId,
    String? institutionName,
    Value<Uri?> institutionLogoUrl = const Value.absent(),
    Value<Uint8List?> institutionLogo = const Value.absent(),
    Value<int?> institutionColor = const Value.absent(),
    ItemStatus? status,
    Value<String?> errorCode = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    DateTime? pulledAt,
  }) => ItemRow(
    id: id ?? this.id,
    institutionId: institutionId ?? this.institutionId,
    institutionName: institutionName ?? this.institutionName,
    institutionLogoUrl: institutionLogoUrl.present
        ? institutionLogoUrl.value
        : this.institutionLogoUrl,
    institutionLogo: institutionLogo.present
        ? institutionLogo.value
        : this.institutionLogo,
    institutionColor: institutionColor.present
        ? institutionColor.value
        : this.institutionColor,
    status: status ?? this.status,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      id: data.id.present ? data.id.value : this.id,
      institutionId: data.institutionId.present
          ? data.institutionId.value
          : this.institutionId,
      institutionName: data.institutionName.present
          ? data.institutionName.value
          : this.institutionName,
      institutionLogoUrl: data.institutionLogoUrl.present
          ? data.institutionLogoUrl.value
          : this.institutionLogoUrl,
      institutionLogo: data.institutionLogo.present
          ? data.institutionLogo.value
          : this.institutionLogo,
      institutionColor: data.institutionColor.present
          ? data.institutionColor.value
          : this.institutionColor,
      status: data.status.present ? data.status.value : this.status,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('id: $id, ')
          ..write('institutionId: $institutionId, ')
          ..write('institutionName: $institutionName, ')
          ..write('institutionLogoUrl: $institutionLogoUrl, ')
          ..write('institutionLogo: $institutionLogo, ')
          ..write('institutionColor: $institutionColor, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    institutionId,
    institutionName,
    institutionLogoUrl,
    $driftBlobEquality.hash(institutionLogo),
    institutionColor,
    status,
    errorCode,
    lastSuccessfulSyncAt,
    pulledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.id == this.id &&
          other.institutionId == this.institutionId &&
          other.institutionName == this.institutionName &&
          other.institutionLogoUrl == this.institutionLogoUrl &&
          $driftBlobEquality.equals(
            other.institutionLogo,
            this.institutionLogo,
          ) &&
          other.institutionColor == this.institutionColor &&
          other.status == this.status &&
          other.errorCode == this.errorCode &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.pulledAt == this.pulledAt);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<String> id;
  final Value<String> institutionId;
  final Value<String> institutionName;
  final Value<Uri?> institutionLogoUrl;
  final Value<Uint8List?> institutionLogo;
  final Value<int?> institutionColor;
  final Value<ItemStatus> status;
  final Value<String?> errorCode;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.institutionId = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.institutionLogoUrl = const Value.absent(),
    this.institutionLogo = const Value.absent(),
    this.institutionColor = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String institutionId,
    required String institutionName,
    this.institutionLogoUrl = const Value.absent(),
    this.institutionLogo = const Value.absent(),
    this.institutionColor = const Value.absent(),
    required ItemStatus status,
    this.errorCode = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       institutionId = Value(institutionId),
       institutionName = Value(institutionName),
       status = Value(status),
       pulledAt = Value(pulledAt);
  static Insertable<ItemRow> custom({
    Expression<String>? id,
    Expression<String>? institutionId,
    Expression<String>? institutionName,
    Expression<String>? institutionLogoUrl,
    Expression<Uint8List>? institutionLogo,
    Expression<int>? institutionColor,
    Expression<String>? status,
    Expression<String>? errorCode,
    Expression<int>? lastSuccessfulSyncAt,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (institutionId != null) 'institution_id': institutionId,
      if (institutionName != null) 'institution_name': institutionName,
      if (institutionLogoUrl != null)
        'institution_logo_url': institutionLogoUrl,
      if (institutionLogo != null) 'institution_logo': institutionLogo,
      if (institutionColor != null) 'institution_color': institutionColor,
      if (status != null) 'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? institutionId,
    Value<String>? institutionName,
    Value<Uri?>? institutionLogoUrl,
    Value<Uint8List?>? institutionLogo,
    Value<int?>? institutionColor,
    Value<ItemStatus>? status,
    Value<String?>? errorCode,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      institutionId: institutionId ?? this.institutionId,
      institutionName: institutionName ?? this.institutionName,
      institutionLogoUrl: institutionLogoUrl ?? this.institutionLogoUrl,
      institutionLogo: institutionLogo ?? this.institutionLogo,
      institutionColor: institutionColor ?? this.institutionColor,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (institutionId.present) {
      map['institution_id'] = Variable<String>(institutionId.value);
    }
    if (institutionName.present) {
      map['institution_name'] = Variable<String>(institutionName.value);
    }
    if (institutionLogoUrl.present) {
      map['institution_logo_url'] = Variable<String>(
        $ItemsTable.$converterinstitutionLogoUrln.toSql(
          institutionLogoUrl.value,
        ),
      );
    }
    if (institutionLogo.present) {
      map['institution_logo'] = Variable<Uint8List>(institutionLogo.value);
    }
    if (institutionColor.present) {
      map['institution_color'] = Variable<int>(institutionColor.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<int>(
        $ItemsTable.$converterlastSuccessfulSyncAtn.toSql(
          lastSuccessfulSyncAt.value,
        ),
      );
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $ItemsTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('institutionId: $institutionId, ')
          ..write('institutionName: $institutionName, ')
          ..write('institutionLogoUrl: $institutionLogoUrl, ')
          ..write('institutionLogo: $institutionLogo, ')
          ..write('institutionColor: $institutionColor, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RulesTable extends Rules with TableInfo<$RulesTable, RuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionsMeta = const VerificationMeta(
    'conditions',
  );
  @override
  late final GeneratedColumn<String> conditions = GeneratedColumn<String>(
    'conditions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionsMeta = const VerificationMeta(
    'actions',
  );
  @override
  late final GeneratedColumn<String> actions = GeneratedColumn<String>(
    'actions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RulesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RulesTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($RulesTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    conditions,
    actions,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('conditions')) {
      context.handle(
        _conditionsMeta,
        conditions.isAcceptableOrUnknown(data['conditions']!, _conditionsMeta),
      );
    } else if (isInserting) {
      context.missing(_conditionsMeta);
    }
    if (data.containsKey('actions')) {
      context.handle(
        _actionsMeta,
        actions.isAcceptableOrUnknown(data['actions']!, _actionsMeta),
      );
    } else if (isInserting) {
      context.missing(_actionsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      conditions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conditions'],
      )!,
      actions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actions'],
      )!,
      createdAt: $RulesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $RulesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $RulesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $RulesTable createAlias(String alias) {
    return $RulesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class RuleRow extends DataClass implements Insertable<RuleRow> {
  final String id;
  final String name;
  final int position;
  final String conditions;
  final String actions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const RuleRow({
    required this.id,
    required this.name,
    required this.position,
    required this.conditions,
    required this.actions,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['conditions'] = Variable<String>(conditions);
    map['actions'] = Variable<String>(actions);
    {
      map['created_at'] = Variable<int>(
        $RulesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $RulesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $RulesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  RulesCompanion toCompanion(bool nullToAbsent) {
    return RulesCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      conditions: Value(conditions),
      actions: Value(actions),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      conditions: serializer.fromJson<String>(json['conditions']),
      actions: serializer.fromJson<String>(json['actions']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'conditions': serializer.toJson<String>(conditions),
      'actions': serializer.toJson<String>(actions),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  RuleRow copyWith({
    String? id,
    String? name,
    int? position,
    String? conditions,
    String? actions,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => RuleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    conditions: conditions ?? this.conditions,
    actions: actions ?? this.actions,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RuleRow copyWithCompanion(RulesCompanion data) {
    return RuleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      conditions: data.conditions.present
          ? data.conditions.value
          : this.conditions,
      actions: data.actions.present ? data.actions.value : this.actions,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('conditions: $conditions, ')
          ..write('actions: $actions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    position,
    conditions,
    actions,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.conditions == this.conditions &&
          other.actions == this.actions &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RulesCompanion extends UpdateCompanion<RuleRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<String> conditions;
  final Value<String> actions;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const RulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.conditions = const Value.absent(),
    this.actions = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RulesCompanion.insert({
    required String id,
    required String name,
    required int position,
    required String conditions,
    required String actions,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position),
       conditions = Value(conditions),
       actions = Value(actions),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RuleRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? conditions,
    Expression<String>? actions,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (conditions != null) 'conditions': conditions,
      if (actions != null) 'actions': actions,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<String>? conditions,
    Value<String>? actions,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return RulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (conditions.present) {
      map['conditions'] = Variable<String>(conditions.value);
    }
    if (actions.present) {
      map['actions'] = Variable<String>(actions.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $RulesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $RulesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $RulesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('conditions: $conditions, ')
          ..write('actions: $actions, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BudgetPeriodKind, String> period =
      GeneratedColumn<String>(
        'period',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BudgetPeriodKind>($BudgetsTable.$converterperiod);
  static const VerificationMeta _periodStartDayMeta = const VerificationMeta(
    'periodStartDay',
  );
  @override
  late final GeneratedColumn<int> periodStartDay = GeneratedColumn<int>(
    'period_start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolloverMeta = const VerificationMeta(
    'rollover',
  );
  @override
  late final GeneratedColumn<bool> rollover = GeneratedColumn<bool>(
    'rollover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rollover" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> startDate =
      GeneratedColumn<String>(
        'start_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($BudgetsTable.$converterstartDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BudgetsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BudgetsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($BudgetsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    period,
    periodStartDay,
    amountMinor,
    currency,
    rollover,
    startDate,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('period_start_day')) {
      context.handle(
        _periodStartDayMeta,
        periodStartDay.isAcceptableOrUnknown(
          data['period_start_day']!,
          _periodStartDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartDayMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('rollover')) {
      context.handle(
        _rolloverMeta,
        rollover.isAcceptableOrUnknown(data['rollover']!, _rolloverMeta),
      );
    } else if (isInserting) {
      context.missing(_rolloverMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      period: $BudgetsTable.$converterperiod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}period'],
        )!,
      ),
      periodStartDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}period_start_day'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      rollover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rollover'],
      )!,
      startDate: $BudgetsTable.$converterstartDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}start_date'],
        )!,
      ),
      createdAt: $BudgetsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $BudgetsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $BudgetsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BudgetPeriodKind, String, String> $converterperiod =
      const EnumNameConverter<BudgetPeriodKind>(BudgetPeriodKind.values);
  static TypeConverter<LocalDate, String> $converterstartDate =
      const LocalDateColumnConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class BudgetRow extends DataClass implements Insertable<BudgetRow> {
  final String id;
  final String categoryId;
  final BudgetPeriodKind period;
  final int periodStartDay;
  final int amountMinor;
  final String currency;
  final bool rollover;
  final LocalDate startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const BudgetRow({
    required this.id,
    required this.categoryId,
    required this.period,
    required this.periodStartDay,
    required this.amountMinor,
    required this.currency,
    required this.rollover,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    {
      map['period'] = Variable<String>(
        $BudgetsTable.$converterperiod.toSql(period),
      );
    }
    map['period_start_day'] = Variable<int>(periodStartDay);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['rollover'] = Variable<bool>(rollover);
    {
      map['start_date'] = Variable<String>(
        $BudgetsTable.$converterstartDate.toSql(startDate),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $BudgetsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $BudgetsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $BudgetsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      period: Value(period),
      periodStartDay: Value(periodStartDay),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      rollover: Value(rollover),
      startDate: Value(startDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      period: $BudgetsTable.$converterperiod.fromJson(
        serializer.fromJson<String>(json['period']),
      ),
      periodStartDay: serializer.fromJson<int>(json['periodStartDay']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      rollover: serializer.fromJson<bool>(json['rollover']),
      startDate: serializer.fromJson<LocalDate>(json['startDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'period': serializer.toJson<String>(
        $BudgetsTable.$converterperiod.toJson(period),
      ),
      'periodStartDay': serializer.toJson<int>(periodStartDay),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'rollover': serializer.toJson<bool>(rollover),
      'startDate': serializer.toJson<LocalDate>(startDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BudgetRow copyWith({
    String? id,
    String? categoryId,
    BudgetPeriodKind? period,
    int? periodStartDay,
    int? amountMinor,
    String? currency,
    bool? rollover,
    LocalDate? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BudgetRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    period: period ?? this.period,
    periodStartDay: periodStartDay ?? this.periodStartDay,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    rollover: rollover ?? this.rollover,
    startDate: startDate ?? this.startDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BudgetRow copyWithCompanion(BudgetsCompanion data) {
    return BudgetRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      period: data.period.present ? data.period.value : this.period,
      periodStartDay: data.periodStartDay.present
          ? data.periodStartDay.value
          : this.periodStartDay,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      rollover: data.rollover.present ? data.rollover.value : this.rollover,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('rollover: $rollover, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    period,
    periodStartDay,
    amountMinor,
    currency,
    rollover,
    startDate,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.period == this.period &&
          other.periodStartDay == this.periodStartDay &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.rollover == this.rollover &&
          other.startDate == this.startDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BudgetsCompanion extends UpdateCompanion<BudgetRow> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<BudgetPeriodKind> period;
  final Value<int> periodStartDay;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<bool> rollover;
  final Value<LocalDate> startDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.period = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.rollover = const Value.absent(),
    this.startDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String categoryId,
    required BudgetPeriodKind period,
    required int periodStartDay,
    required int amountMinor,
    required String currency,
    required bool rollover,
    required LocalDate startDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       period = Value(period),
       periodStartDay = Value(periodStartDay),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       rollover = Value(rollover),
       startDate = Value(startDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BudgetRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? period,
    Expression<int>? periodStartDay,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<bool>? rollover,
    Expression<String>? startDate,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (period != null) 'period': period,
      if (periodStartDay != null) 'period_start_day': periodStartDay,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (rollover != null) 'rollover': rollover,
      if (startDate != null) 'start_date': startDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<BudgetPeriodKind>? period,
    Value<int>? periodStartDay,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<bool>? rollover,
    Value<LocalDate>? startDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      periodStartDay: periodStartDay ?? this.periodStartDay,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      rollover: rollover ?? this.rollover,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(
        $BudgetsTable.$converterperiod.toSql(period.value),
      );
    }
    if (periodStartDay.present) {
      map['period_start_day'] = Variable<int>(periodStartDay.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rollover.present) {
      map['rollover'] = Variable<bool>(rollover.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(
        $BudgetsTable.$converterstartDate.toSql(startDate.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BudgetsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $BudgetsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $BudgetsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('period: $period, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('rollover: $rollover, ')
          ..write('startDate: $startDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetAlertsTable extends BudgetAlerts
    with TableInfo<$BudgetAlertsTable, BudgetAlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _budgetIdMeta = const VerificationMeta(
    'budgetId',
  );
  @override
  late final GeneratedColumn<String> budgetId = GeneratedColumn<String>(
    'budget_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> periodStart =
      GeneratedColumn<String>(
        'period_start',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($BudgetAlertsTable.$converterperiodStart);
  static const VerificationMeta _thresholdBpMeta = const VerificationMeta(
    'thresholdBp',
  );
  @override
  late final GeneratedColumn<int> thresholdBp = GeneratedColumn<int>(
    'threshold_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> raisedAt =
      GeneratedColumn<int>(
        'raised_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BudgetAlertsTable.$converterraisedAt);
  @override
  List<GeneratedColumn> get $columns => [
    budgetId,
    periodStart,
    thresholdBp,
    raisedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetAlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('budget_id')) {
      context.handle(
        _budgetIdMeta,
        budgetId.isAcceptableOrUnknown(data['budget_id']!, _budgetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetIdMeta);
    }
    if (data.containsKey('threshold_bp')) {
      context.handle(
        _thresholdBpMeta,
        thresholdBp.isAcceptableOrUnknown(
          data['threshold_bp']!,
          _thresholdBpMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thresholdBpMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {budgetId, periodStart, thresholdBp};
  @override
  BudgetAlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetAlertRow(
      budgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_id'],
      )!,
      periodStart: $BudgetAlertsTable.$converterperiodStart.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}period_start'],
        )!,
      ),
      thresholdBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}threshold_bp'],
      )!,
      raisedAt: $BudgetAlertsTable.$converterraisedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}raised_at'],
        )!,
      ),
    );
  }

  @override
  $BudgetAlertsTable createAlias(String alias) {
    return $BudgetAlertsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterperiodStart =
      const LocalDateColumnConverter();
  static TypeConverter<DateTime, int> $converterraisedAt =
      const UtcMillisColumnConverter();
}

class BudgetAlertRow extends DataClass implements Insertable<BudgetAlertRow> {
  final String budgetId;
  final LocalDate periodStart;
  final int thresholdBp;
  final DateTime raisedAt;
  const BudgetAlertRow({
    required this.budgetId,
    required this.periodStart,
    required this.thresholdBp,
    required this.raisedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['budget_id'] = Variable<String>(budgetId);
    {
      map['period_start'] = Variable<String>(
        $BudgetAlertsTable.$converterperiodStart.toSql(periodStart),
      );
    }
    map['threshold_bp'] = Variable<int>(thresholdBp);
    {
      map['raised_at'] = Variable<int>(
        $BudgetAlertsTable.$converterraisedAt.toSql(raisedAt),
      );
    }
    return map;
  }

  BudgetAlertsCompanion toCompanion(bool nullToAbsent) {
    return BudgetAlertsCompanion(
      budgetId: Value(budgetId),
      periodStart: Value(periodStart),
      thresholdBp: Value(thresholdBp),
      raisedAt: Value(raisedAt),
    );
  }

  factory BudgetAlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetAlertRow(
      budgetId: serializer.fromJson<String>(json['budgetId']),
      periodStart: serializer.fromJson<LocalDate>(json['periodStart']),
      thresholdBp: serializer.fromJson<int>(json['thresholdBp']),
      raisedAt: serializer.fromJson<DateTime>(json['raisedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'budgetId': serializer.toJson<String>(budgetId),
      'periodStart': serializer.toJson<LocalDate>(periodStart),
      'thresholdBp': serializer.toJson<int>(thresholdBp),
      'raisedAt': serializer.toJson<DateTime>(raisedAt),
    };
  }

  BudgetAlertRow copyWith({
    String? budgetId,
    LocalDate? periodStart,
    int? thresholdBp,
    DateTime? raisedAt,
  }) => BudgetAlertRow(
    budgetId: budgetId ?? this.budgetId,
    periodStart: periodStart ?? this.periodStart,
    thresholdBp: thresholdBp ?? this.thresholdBp,
    raisedAt: raisedAt ?? this.raisedAt,
  );
  BudgetAlertRow copyWithCompanion(BudgetAlertsCompanion data) {
    return BudgetAlertRow(
      budgetId: data.budgetId.present ? data.budgetId.value : this.budgetId,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      thresholdBp: data.thresholdBp.present
          ? data.thresholdBp.value
          : this.thresholdBp,
      raisedAt: data.raisedAt.present ? data.raisedAt.value : this.raisedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAlertRow(')
          ..write('budgetId: $budgetId, ')
          ..write('periodStart: $periodStart, ')
          ..write('thresholdBp: $thresholdBp, ')
          ..write('raisedAt: $raisedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(budgetId, periodStart, thresholdBp, raisedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetAlertRow &&
          other.budgetId == this.budgetId &&
          other.periodStart == this.periodStart &&
          other.thresholdBp == this.thresholdBp &&
          other.raisedAt == this.raisedAt);
}

class BudgetAlertsCompanion extends UpdateCompanion<BudgetAlertRow> {
  final Value<String> budgetId;
  final Value<LocalDate> periodStart;
  final Value<int> thresholdBp;
  final Value<DateTime> raisedAt;
  final Value<int> rowid;
  const BudgetAlertsCompanion({
    this.budgetId = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.thresholdBp = const Value.absent(),
    this.raisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetAlertsCompanion.insert({
    required String budgetId,
    required LocalDate periodStart,
    required int thresholdBp,
    required DateTime raisedAt,
    this.rowid = const Value.absent(),
  }) : budgetId = Value(budgetId),
       periodStart = Value(periodStart),
       thresholdBp = Value(thresholdBp),
       raisedAt = Value(raisedAt);
  static Insertable<BudgetAlertRow> custom({
    Expression<String>? budgetId,
    Expression<String>? periodStart,
    Expression<int>? thresholdBp,
    Expression<int>? raisedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (budgetId != null) 'budget_id': budgetId,
      if (periodStart != null) 'period_start': periodStart,
      if (thresholdBp != null) 'threshold_bp': thresholdBp,
      if (raisedAt != null) 'raised_at': raisedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetAlertsCompanion copyWith({
    Value<String>? budgetId,
    Value<LocalDate>? periodStart,
    Value<int>? thresholdBp,
    Value<DateTime>? raisedAt,
    Value<int>? rowid,
  }) {
    return BudgetAlertsCompanion(
      budgetId: budgetId ?? this.budgetId,
      periodStart: periodStart ?? this.periodStart,
      thresholdBp: thresholdBp ?? this.thresholdBp,
      raisedAt: raisedAt ?? this.raisedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (budgetId.present) {
      map['budget_id'] = Variable<String>(budgetId.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<String>(
        $BudgetAlertsTable.$converterperiodStart.toSql(periodStart.value),
      );
    }
    if (thresholdBp.present) {
      map['threshold_bp'] = Variable<int>(thresholdBp.value);
    }
    if (raisedAt.present) {
      map['raised_at'] = Variable<int>(
        $BudgetAlertsTable.$converterraisedAt.toSql(raisedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAlertsCompanion(')
          ..write('budgetId: $budgetId, ')
          ..write('periodStart: $periodStart, ')
          ..write('thresholdBp: $thresholdBp, ')
          ..write('raisedAt: $raisedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DismissedPairsTable extends DismissedPairs
    with TableInfo<$DismissedPairsTable, DismissedPairRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DismissedPairsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idAMeta = const VerificationMeta('idA');
  @override
  late final GeneratedColumn<String> idA = GeneratedColumn<String>(
    'id_a',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idBMeta = const VerificationMeta('idB');
  @override
  late final GeneratedColumn<String> idB = GeneratedColumn<String>(
    'id_b',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> dismissedAt =
      GeneratedColumn<int>(
        'dismissed_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DismissedPairsTable.$converterdismissedAt);
  @override
  List<GeneratedColumn> get $columns => [idA, idB, dismissedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dismissed_pairs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DismissedPairRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_a')) {
      context.handle(
        _idAMeta,
        idA.isAcceptableOrUnknown(data['id_a']!, _idAMeta),
      );
    } else if (isInserting) {
      context.missing(_idAMeta);
    }
    if (data.containsKey('id_b')) {
      context.handle(
        _idBMeta,
        idB.isAcceptableOrUnknown(data['id_b']!, _idBMeta),
      );
    } else if (isInserting) {
      context.missing(_idBMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idA, idB};
  @override
  DismissedPairRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DismissedPairRow(
      idA: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_a'],
      )!,
      idB: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_b'],
      )!,
      dismissedAt: $DismissedPairsTable.$converterdismissedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}dismissed_at'],
        )!,
      ),
    );
  }

  @override
  $DismissedPairsTable createAlias(String alias) {
    return $DismissedPairsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterdismissedAt =
      const UtcMillisColumnConverter();
}

class DismissedPairRow extends DataClass
    implements Insertable<DismissedPairRow> {
  final String idA;
  final String idB;
  final DateTime dismissedAt;
  const DismissedPairRow({
    required this.idA,
    required this.idB,
    required this.dismissedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_a'] = Variable<String>(idA);
    map['id_b'] = Variable<String>(idB);
    {
      map['dismissed_at'] = Variable<int>(
        $DismissedPairsTable.$converterdismissedAt.toSql(dismissedAt),
      );
    }
    return map;
  }

  DismissedPairsCompanion toCompanion(bool nullToAbsent) {
    return DismissedPairsCompanion(
      idA: Value(idA),
      idB: Value(idB),
      dismissedAt: Value(dismissedAt),
    );
  }

  factory DismissedPairRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DismissedPairRow(
      idA: serializer.fromJson<String>(json['idA']),
      idB: serializer.fromJson<String>(json['idB']),
      dismissedAt: serializer.fromJson<DateTime>(json['dismissedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idA': serializer.toJson<String>(idA),
      'idB': serializer.toJson<String>(idB),
      'dismissedAt': serializer.toJson<DateTime>(dismissedAt),
    };
  }

  DismissedPairRow copyWith({
    String? idA,
    String? idB,
    DateTime? dismissedAt,
  }) => DismissedPairRow(
    idA: idA ?? this.idA,
    idB: idB ?? this.idB,
    dismissedAt: dismissedAt ?? this.dismissedAt,
  );
  DismissedPairRow copyWithCompanion(DismissedPairsCompanion data) {
    return DismissedPairRow(
      idA: data.idA.present ? data.idA.value : this.idA,
      idB: data.idB.present ? data.idB.value : this.idB,
      dismissedAt: data.dismissedAt.present
          ? data.dismissedAt.value
          : this.dismissedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DismissedPairRow(')
          ..write('idA: $idA, ')
          ..write('idB: $idB, ')
          ..write('dismissedAt: $dismissedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(idA, idB, dismissedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DismissedPairRow &&
          other.idA == this.idA &&
          other.idB == this.idB &&
          other.dismissedAt == this.dismissedAt);
}

class DismissedPairsCompanion extends UpdateCompanion<DismissedPairRow> {
  final Value<String> idA;
  final Value<String> idB;
  final Value<DateTime> dismissedAt;
  final Value<int> rowid;
  const DismissedPairsCompanion({
    this.idA = const Value.absent(),
    this.idB = const Value.absent(),
    this.dismissedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DismissedPairsCompanion.insert({
    required String idA,
    required String idB,
    required DateTime dismissedAt,
    this.rowid = const Value.absent(),
  }) : idA = Value(idA),
       idB = Value(idB),
       dismissedAt = Value(dismissedAt);
  static Insertable<DismissedPairRow> custom({
    Expression<String>? idA,
    Expression<String>? idB,
    Expression<int>? dismissedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idA != null) 'id_a': idA,
      if (idB != null) 'id_b': idB,
      if (dismissedAt != null) 'dismissed_at': dismissedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DismissedPairsCompanion copyWith({
    Value<String>? idA,
    Value<String>? idB,
    Value<DateTime>? dismissedAt,
    Value<int>? rowid,
  }) {
    return DismissedPairsCompanion(
      idA: idA ?? this.idA,
      idB: idB ?? this.idB,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idA.present) {
      map['id_a'] = Variable<String>(idA.value);
    }
    if (idB.present) {
      map['id_b'] = Variable<String>(idB.value);
    }
    if (dismissedAt.present) {
      map['dismissed_at'] = Variable<int>(
        $DismissedPairsTable.$converterdismissedAt.toSql(dismissedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DismissedPairsCompanion(')
          ..write('idA: $idA, ')
          ..write('idB: $idB, ')
          ..write('dismissedAt: $dismissedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedFiltersTable extends SavedFilters
    with TableInfo<$SavedFiltersTable, SavedFilterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedFiltersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryJsonMeta = const VerificationMeta(
    'queryJson',
  );
  @override
  late final GeneratedColumn<String> queryJson = GeneratedColumn<String>(
    'query_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SavedFiltersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SavedFiltersTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    queryJson,
    position,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_filters';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedFilterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('query_json')) {
      context.handle(
        _queryJsonMeta,
        queryJson.isAcceptableOrUnknown(data['query_json']!, _queryJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_queryJsonMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedFilterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedFilterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      queryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query_json'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: $SavedFiltersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SavedFiltersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SavedFiltersTable createAlias(String alias) {
    return $SavedFiltersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
}

class SavedFilterRow extends DataClass implements Insertable<SavedFilterRow> {
  final String id;
  final String name;
  final String queryJson;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedFilterRow({
    required this.id,
    required this.name,
    required this.queryJson,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['query_json'] = Variable<String>(queryJson);
    map['position'] = Variable<int>(position);
    {
      map['created_at'] = Variable<int>(
        $SavedFiltersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $SavedFiltersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SavedFiltersCompanion toCompanion(bool nullToAbsent) {
    return SavedFiltersCompanion(
      id: Value(id),
      name: Value(name),
      queryJson: Value(queryJson),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedFilterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedFilterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      queryJson: serializer.fromJson<String>(json['queryJson']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'queryJson': serializer.toJson<String>(queryJson),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedFilterRow copyWith({
    String? id,
    String? name,
    String? queryJson,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedFilterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    queryJson: queryJson ?? this.queryJson,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedFilterRow copyWithCompanion(SavedFiltersCompanion data) {
    return SavedFilterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      queryJson: data.queryJson.present ? data.queryJson.value : this.queryJson,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedFilterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('queryJson: $queryJson, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, queryJson, position, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedFilterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.queryJson == this.queryJson &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedFiltersCompanion extends UpdateCompanion<SavedFilterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> queryJson;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedFiltersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.queryJson = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedFiltersCompanion.insert({
    required String id,
    required String name,
    required String queryJson,
    required int position,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       queryJson = Value(queryJson),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedFilterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? queryJson,
    Expression<int>? position,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (queryJson != null) 'query_json': queryJson,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedFiltersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? queryJson,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavedFiltersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      queryJson: queryJson ?? this.queryJson,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (queryJson.present) {
      map['query_json'] = Variable<String>(queryJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SavedFiltersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $SavedFiltersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedFiltersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('queryJson: $queryJson, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringStreamsTable extends RecurringStreams
    with TableInfo<$RecurringStreamsTable, RecurringStreamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringStreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurringCadence, String>
  cadence = GeneratedColumn<String>(
    'cadence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RecurringCadence>($RecurringStreamsTable.$convertercadence);
  static const VerificationMeta _averageAmountMinorMeta =
      const VerificationMeta('averageAmountMinor');
  @override
  late final GeneratedColumn<int> averageAmountMinor = GeneratedColumn<int>(
    'average_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> lastExpected =
      GeneratedColumn<String>(
        'last_expected',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>(
        $RecurringStreamsTable.$converterlastExpectedn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> nextExpected =
      GeneratedColumn<String>(
        'next_expected',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>(
        $RecurringStreamsTable.$converternextExpectedn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<RecurringStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecurringStatus>($RecurringStreamsTable.$converterstatus);
  static const VerificationMeta _isSubscriptionMeta = const VerificationMeta(
    'isSubscription',
  );
  @override
  late final GeneratedColumn<bool> isSubscription = GeneratedColumn<bool>(
    'is_subscription',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscription" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurringSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RecurringSource>($RecurringStreamsTable.$convertersource);
  static const VerificationMeta _transactionIdsMeta = const VerificationMeta(
    'transactionIds',
  );
  @override
  late final GeneratedColumn<String> transactionIds = GeneratedColumn<String>(
    'transaction_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($RecurringStreamsTable.$converterpulledAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    merchantName,
    cadence,
    averageAmountMinor,
    currency,
    lastExpected,
    nextExpected,
    status,
    isSubscription,
    source,
    transactionIds,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_streams';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringStreamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantNameMeta);
    }
    if (data.containsKey('average_amount_minor')) {
      context.handle(
        _averageAmountMinorMeta,
        averageAmountMinor.isAcceptableOrUnknown(
          data['average_amount_minor']!,
          _averageAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageAmountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('is_subscription')) {
      context.handle(
        _isSubscriptionMeta,
        isSubscription.isAcceptableOrUnknown(
          data['is_subscription']!,
          _isSubscriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSubscriptionMeta);
    }
    if (data.containsKey('transaction_ids')) {
      context.handle(
        _transactionIdsMeta,
        transactionIds.isAcceptableOrUnknown(
          data['transaction_ids']!,
          _transactionIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringStreamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringStreamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      )!,
      cadence: $RecurringStreamsTable.$convertercadence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cadence'],
        )!,
      ),
      averageAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      lastExpected: $RecurringStreamsTable.$converterlastExpectedn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_expected'],
        ),
      ),
      nextExpected: $RecurringStreamsTable.$converternextExpectedn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}next_expected'],
        ),
      ),
      status: $RecurringStreamsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      isSubscription: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscription'],
      )!,
      source: $RecurringStreamsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      transactionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_ids'],
      )!,
      pulledAt: $RecurringStreamsTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $RecurringStreamsTable createAlias(String alias) {
    return $RecurringStreamsTable(attachedDatabase, alias);
  }

  static TypeConverter<RecurringCadence, String> $convertercadence =
      const RecurringCadenceColumnConverter();
  static TypeConverter<LocalDate, String> $converterlastExpected =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterlastExpectedn =
      NullAwareTypeConverter.wrap($converterlastExpected);
  static TypeConverter<LocalDate, String> $converternextExpected =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converternextExpectedn =
      NullAwareTypeConverter.wrap($converternextExpected);
  static JsonTypeConverter2<RecurringStatus, String, String> $converterstatus =
      const EnumNameConverter<RecurringStatus>(RecurringStatus.values);
  static JsonTypeConverter2<RecurringSource, String, String> $convertersource =
      const EnumNameConverter<RecurringSource>(RecurringSource.values);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class RecurringStreamRow extends DataClass
    implements Insertable<RecurringStreamRow> {
  final String id;
  final String accountId;
  final String merchantName;
  final RecurringCadence cadence;
  final int averageAmountMinor;
  final String currency;
  final LocalDate? lastExpected;
  final LocalDate? nextExpected;
  final RecurringStatus status;
  final bool isSubscription;
  final RecurringSource source;
  final String transactionIds;
  final DateTime pulledAt;
  const RecurringStreamRow({
    required this.id,
    required this.accountId,
    required this.merchantName,
    required this.cadence,
    required this.averageAmountMinor,
    required this.currency,
    this.lastExpected,
    this.nextExpected,
    required this.status,
    required this.isSubscription,
    required this.source,
    required this.transactionIds,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['merchant_name'] = Variable<String>(merchantName);
    {
      map['cadence'] = Variable<String>(
        $RecurringStreamsTable.$convertercadence.toSql(cadence),
      );
    }
    map['average_amount_minor'] = Variable<int>(averageAmountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || lastExpected != null) {
      map['last_expected'] = Variable<String>(
        $RecurringStreamsTable.$converterlastExpectedn.toSql(lastExpected),
      );
    }
    if (!nullToAbsent || nextExpected != null) {
      map['next_expected'] = Variable<String>(
        $RecurringStreamsTable.$converternextExpectedn.toSql(nextExpected),
      );
    }
    {
      map['status'] = Variable<String>(
        $RecurringStreamsTable.$converterstatus.toSql(status),
      );
    }
    map['is_subscription'] = Variable<bool>(isSubscription);
    {
      map['source'] = Variable<String>(
        $RecurringStreamsTable.$convertersource.toSql(source),
      );
    }
    map['transaction_ids'] = Variable<String>(transactionIds);
    {
      map['pulled_at'] = Variable<int>(
        $RecurringStreamsTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  RecurringStreamsCompanion toCompanion(bool nullToAbsent) {
    return RecurringStreamsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      merchantName: Value(merchantName),
      cadence: Value(cadence),
      averageAmountMinor: Value(averageAmountMinor),
      currency: Value(currency),
      lastExpected: lastExpected == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExpected),
      nextExpected: nextExpected == null && nullToAbsent
          ? const Value.absent()
          : Value(nextExpected),
      status: Value(status),
      isSubscription: Value(isSubscription),
      source: Value(source),
      transactionIds: Value(transactionIds),
      pulledAt: Value(pulledAt),
    );
  }

  factory RecurringStreamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringStreamRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      merchantName: serializer.fromJson<String>(json['merchantName']),
      cadence: serializer.fromJson<RecurringCadence>(json['cadence']),
      averageAmountMinor: serializer.fromJson<int>(json['averageAmountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      lastExpected: serializer.fromJson<LocalDate?>(json['lastExpected']),
      nextExpected: serializer.fromJson<LocalDate?>(json['nextExpected']),
      status: $RecurringStreamsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      isSubscription: serializer.fromJson<bool>(json['isSubscription']),
      source: $RecurringStreamsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      transactionIds: serializer.fromJson<String>(json['transactionIds']),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'merchantName': serializer.toJson<String>(merchantName),
      'cadence': serializer.toJson<RecurringCadence>(cadence),
      'averageAmountMinor': serializer.toJson<int>(averageAmountMinor),
      'currency': serializer.toJson<String>(currency),
      'lastExpected': serializer.toJson<LocalDate?>(lastExpected),
      'nextExpected': serializer.toJson<LocalDate?>(nextExpected),
      'status': serializer.toJson<String>(
        $RecurringStreamsTable.$converterstatus.toJson(status),
      ),
      'isSubscription': serializer.toJson<bool>(isSubscription),
      'source': serializer.toJson<String>(
        $RecurringStreamsTable.$convertersource.toJson(source),
      ),
      'transactionIds': serializer.toJson<String>(transactionIds),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  RecurringStreamRow copyWith({
    String? id,
    String? accountId,
    String? merchantName,
    RecurringCadence? cadence,
    int? averageAmountMinor,
    String? currency,
    Value<LocalDate?> lastExpected = const Value.absent(),
    Value<LocalDate?> nextExpected = const Value.absent(),
    RecurringStatus? status,
    bool? isSubscription,
    RecurringSource? source,
    String? transactionIds,
    DateTime? pulledAt,
  }) => RecurringStreamRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    merchantName: merchantName ?? this.merchantName,
    cadence: cadence ?? this.cadence,
    averageAmountMinor: averageAmountMinor ?? this.averageAmountMinor,
    currency: currency ?? this.currency,
    lastExpected: lastExpected.present ? lastExpected.value : this.lastExpected,
    nextExpected: nextExpected.present ? nextExpected.value : this.nextExpected,
    status: status ?? this.status,
    isSubscription: isSubscription ?? this.isSubscription,
    source: source ?? this.source,
    transactionIds: transactionIds ?? this.transactionIds,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  RecurringStreamRow copyWithCompanion(RecurringStreamsCompanion data) {
    return RecurringStreamRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      averageAmountMinor: data.averageAmountMinor.present
          ? data.averageAmountMinor.value
          : this.averageAmountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      lastExpected: data.lastExpected.present
          ? data.lastExpected.value
          : this.lastExpected,
      nextExpected: data.nextExpected.present
          ? data.nextExpected.value
          : this.nextExpected,
      status: data.status.present ? data.status.value : this.status,
      isSubscription: data.isSubscription.present
          ? data.isSubscription.value
          : this.isSubscription,
      source: data.source.present ? data.source.value : this.source,
      transactionIds: data.transactionIds.present
          ? data.transactionIds.value
          : this.transactionIds,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringStreamRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('merchantName: $merchantName, ')
          ..write('cadence: $cadence, ')
          ..write('averageAmountMinor: $averageAmountMinor, ')
          ..write('currency: $currency, ')
          ..write('lastExpected: $lastExpected, ')
          ..write('nextExpected: $nextExpected, ')
          ..write('status: $status, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('source: $source, ')
          ..write('transactionIds: $transactionIds, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    merchantName,
    cadence,
    averageAmountMinor,
    currency,
    lastExpected,
    nextExpected,
    status,
    isSubscription,
    source,
    transactionIds,
    pulledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringStreamRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.merchantName == this.merchantName &&
          other.cadence == this.cadence &&
          other.averageAmountMinor == this.averageAmountMinor &&
          other.currency == this.currency &&
          other.lastExpected == this.lastExpected &&
          other.nextExpected == this.nextExpected &&
          other.status == this.status &&
          other.isSubscription == this.isSubscription &&
          other.source == this.source &&
          other.transactionIds == this.transactionIds &&
          other.pulledAt == this.pulledAt);
}

class RecurringStreamsCompanion extends UpdateCompanion<RecurringStreamRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> merchantName;
  final Value<RecurringCadence> cadence;
  final Value<int> averageAmountMinor;
  final Value<String> currency;
  final Value<LocalDate?> lastExpected;
  final Value<LocalDate?> nextExpected;
  final Value<RecurringStatus> status;
  final Value<bool> isSubscription;
  final Value<RecurringSource> source;
  final Value<String> transactionIds;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const RecurringStreamsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.cadence = const Value.absent(),
    this.averageAmountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.lastExpected = const Value.absent(),
    this.nextExpected = const Value.absent(),
    this.status = const Value.absent(),
    this.isSubscription = const Value.absent(),
    this.source = const Value.absent(),
    this.transactionIds = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringStreamsCompanion.insert({
    required String id,
    required String accountId,
    required String merchantName,
    required RecurringCadence cadence,
    required int averageAmountMinor,
    required String currency,
    this.lastExpected = const Value.absent(),
    this.nextExpected = const Value.absent(),
    required RecurringStatus status,
    required bool isSubscription,
    required RecurringSource source,
    required String transactionIds,
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       merchantName = Value(merchantName),
       cadence = Value(cadence),
       averageAmountMinor = Value(averageAmountMinor),
       currency = Value(currency),
       status = Value(status),
       isSubscription = Value(isSubscription),
       source = Value(source),
       transactionIds = Value(transactionIds),
       pulledAt = Value(pulledAt);
  static Insertable<RecurringStreamRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? merchantName,
    Expression<String>? cadence,
    Expression<int>? averageAmountMinor,
    Expression<String>? currency,
    Expression<String>? lastExpected,
    Expression<String>? nextExpected,
    Expression<String>? status,
    Expression<bool>? isSubscription,
    Expression<String>? source,
    Expression<String>? transactionIds,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (merchantName != null) 'merchant_name': merchantName,
      if (cadence != null) 'cadence': cadence,
      if (averageAmountMinor != null)
        'average_amount_minor': averageAmountMinor,
      if (currency != null) 'currency': currency,
      if (lastExpected != null) 'last_expected': lastExpected,
      if (nextExpected != null) 'next_expected': nextExpected,
      if (status != null) 'status': status,
      if (isSubscription != null) 'is_subscription': isSubscription,
      if (source != null) 'source': source,
      if (transactionIds != null) 'transaction_ids': transactionIds,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringStreamsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? merchantName,
    Value<RecurringCadence>? cadence,
    Value<int>? averageAmountMinor,
    Value<String>? currency,
    Value<LocalDate?>? lastExpected,
    Value<LocalDate?>? nextExpected,
    Value<RecurringStatus>? status,
    Value<bool>? isSubscription,
    Value<RecurringSource>? source,
    Value<String>? transactionIds,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return RecurringStreamsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      merchantName: merchantName ?? this.merchantName,
      cadence: cadence ?? this.cadence,
      averageAmountMinor: averageAmountMinor ?? this.averageAmountMinor,
      currency: currency ?? this.currency,
      lastExpected: lastExpected ?? this.lastExpected,
      nextExpected: nextExpected ?? this.nextExpected,
      status: status ?? this.status,
      isSubscription: isSubscription ?? this.isSubscription,
      source: source ?? this.source,
      transactionIds: transactionIds ?? this.transactionIds,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(
        $RecurringStreamsTable.$convertercadence.toSql(cadence.value),
      );
    }
    if (averageAmountMinor.present) {
      map['average_amount_minor'] = Variable<int>(averageAmountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (lastExpected.present) {
      map['last_expected'] = Variable<String>(
        $RecurringStreamsTable.$converterlastExpectedn.toSql(
          lastExpected.value,
        ),
      );
    }
    if (nextExpected.present) {
      map['next_expected'] = Variable<String>(
        $RecurringStreamsTable.$converternextExpectedn.toSql(
          nextExpected.value,
        ),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $RecurringStreamsTable.$converterstatus.toSql(status.value),
      );
    }
    if (isSubscription.present) {
      map['is_subscription'] = Variable<bool>(isSubscription.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $RecurringStreamsTable.$convertersource.toSql(source.value),
      );
    }
    if (transactionIds.present) {
      map['transaction_ids'] = Variable<String>(transactionIds.value);
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $RecurringStreamsTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringStreamsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('merchantName: $merchantName, ')
          ..write('cadence: $cadence, ')
          ..write('averageAmountMinor: $averageAmountMinor, ')
          ..write('currency: $currency, ')
          ..write('lastExpected: $lastExpected, ')
          ..write('nextExpected: $nextExpected, ')
          ..write('status: $status, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('source: $source, ')
          ..write('transactionIds: $transactionIds, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreamOverridesTable extends StreamOverrides
    with TableInfo<$StreamOverridesTable, StreamOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
    'muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSubscriptionMeta = const VerificationMeta(
    'isSubscription',
  );
  @override
  late final GeneratedColumn<bool> isSubscription = GeneratedColumn<bool>(
    'is_subscription',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscription" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StreamOverridesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($StreamOverridesTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($StreamOverridesTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    streamId,
    muted,
    isSubscription,
    displayName,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stream_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreamOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('muted')) {
      context.handle(
        _mutedMeta,
        muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta),
      );
    }
    if (data.containsKey('is_subscription')) {
      context.handle(
        _isSubscriptionMeta,
        isSubscription.isAcceptableOrUnknown(
          data['is_subscription']!,
          _isSubscriptionMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {streamId};
  @override
  StreamOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreamOverrideRow(
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      )!,
      muted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}muted'],
      )!,
      isSubscription: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscription'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      createdAt: $StreamOverridesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $StreamOverridesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $StreamOverridesTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $StreamOverridesTable createAlias(String alias) {
    return $StreamOverridesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class StreamOverrideRow extends DataClass
    implements Insertable<StreamOverrideRow> {
  final String streamId;
  final bool muted;
  final bool? isSubscription;
  final String? displayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const StreamOverrideRow({
    required this.streamId,
    required this.muted,
    this.isSubscription,
    this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stream_id'] = Variable<String>(streamId);
    map['muted'] = Variable<bool>(muted);
    if (!nullToAbsent || isSubscription != null) {
      map['is_subscription'] = Variable<bool>(isSubscription);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    {
      map['created_at'] = Variable<int>(
        $StreamOverridesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $StreamOverridesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $StreamOverridesTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  StreamOverridesCompanion toCompanion(bool nullToAbsent) {
    return StreamOverridesCompanion(
      streamId: Value(streamId),
      muted: Value(muted),
      isSubscription: isSubscription == null && nullToAbsent
          ? const Value.absent()
          : Value(isSubscription),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory StreamOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreamOverrideRow(
      streamId: serializer.fromJson<String>(json['streamId']),
      muted: serializer.fromJson<bool>(json['muted']),
      isSubscription: serializer.fromJson<bool?>(json['isSubscription']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'streamId': serializer.toJson<String>(streamId),
      'muted': serializer.toJson<bool>(muted),
      'isSubscription': serializer.toJson<bool?>(isSubscription),
      'displayName': serializer.toJson<String?>(displayName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  StreamOverrideRow copyWith({
    String? streamId,
    bool? muted,
    Value<bool?> isSubscription = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => StreamOverrideRow(
    streamId: streamId ?? this.streamId,
    muted: muted ?? this.muted,
    isSubscription: isSubscription.present
        ? isSubscription.value
        : this.isSubscription,
    displayName: displayName.present ? displayName.value : this.displayName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  StreamOverrideRow copyWithCompanion(StreamOverridesCompanion data) {
    return StreamOverrideRow(
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      muted: data.muted.present ? data.muted.value : this.muted,
      isSubscription: data.isSubscription.present
          ? data.isSubscription.value
          : this.isSubscription,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreamOverrideRow(')
          ..write('streamId: $streamId, ')
          ..write('muted: $muted, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    streamId,
    muted,
    isSubscription,
    displayName,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreamOverrideRow &&
          other.streamId == this.streamId &&
          other.muted == this.muted &&
          other.isSubscription == this.isSubscription &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class StreamOverridesCompanion extends UpdateCompanion<StreamOverrideRow> {
  final Value<String> streamId;
  final Value<bool> muted;
  final Value<bool?> isSubscription;
  final Value<String?> displayName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const StreamOverridesCompanion({
    this.streamId = const Value.absent(),
    this.muted = const Value.absent(),
    this.isSubscription = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreamOverridesCompanion.insert({
    required String streamId,
    this.muted = const Value.absent(),
    this.isSubscription = const Value.absent(),
    this.displayName = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : streamId = Value(streamId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StreamOverrideRow> custom({
    Expression<String>? streamId,
    Expression<bool>? muted,
    Expression<bool>? isSubscription,
    Expression<String>? displayName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (streamId != null) 'stream_id': streamId,
      if (muted != null) 'muted': muted,
      if (isSubscription != null) 'is_subscription': isSubscription,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreamOverridesCompanion copyWith({
    Value<String>? streamId,
    Value<bool>? muted,
    Value<bool?>? isSubscription,
    Value<String?>? displayName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return StreamOverridesCompanion(
      streamId: streamId ?? this.streamId,
      muted: muted ?? this.muted,
      isSubscription: isSubscription ?? this.isSubscription,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (isSubscription.present) {
      map['is_subscription'] = Variable<bool>(isSubscription.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $StreamOverridesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $StreamOverridesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $StreamOverridesTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamOverridesCompanion(')
          ..write('streamId: $streamId, ')
          ..write('muted: $muted, ')
          ..write('isSubscription: $isSubscription, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiabilitiesTable extends Liabilities
    with TableInfo<$LiabilitiesTable, LiabilityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiabilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LiabilityKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LiabilityKind>($LiabilitiesTable.$converterkind);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  nextPaymentDueDate = GeneratedColumn<String>(
    'next_payment_due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($LiabilitiesTable.$converternextPaymentDueDaten);
  static const VerificationMeta _minimumPaymentMinorMeta =
      const VerificationMeta('minimumPaymentMinor');
  @override
  late final GeneratedColumn<int> minimumPaymentMinor = GeneratedColumn<int>(
    'minimum_payment_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastStatementBalanceMinorMeta =
      const VerificationMeta('lastStatementBalanceMinor');
  @override
  late final GeneratedColumn<int> lastStatementBalanceMinor =
      GeneratedColumn<int>(
        'last_statement_balance_minor',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  lastStatementIssueDate =
      GeneratedColumn<String>(
        'last_statement_issue_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>(
        $LiabilitiesTable.$converterlastStatementIssueDaten,
      );
  static const VerificationMeta _lastPaymentMinorMeta = const VerificationMeta(
    'lastPaymentMinor',
  );
  @override
  late final GeneratedColumn<int> lastPaymentMinor = GeneratedColumn<int>(
    'last_payment_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  lastPaymentDate = GeneratedColumn<String>(
    'last_payment_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($LiabilitiesTable.$converterlastPaymentDaten);
  static const VerificationMeta _isOverdueMeta = const VerificationMeta(
    'isOverdue',
  );
  @override
  late final GeneratedColumn<bool> isOverdue = GeneratedColumn<bool>(
    'is_overdue',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_overdue" IN (0, 1))',
    ),
  );
  static const VerificationMeta _aprsMeta = const VerificationMeta('aprs');
  @override
  late final GeneratedColumn<String> aprs = GeneratedColumn<String>(
    'aprs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _interestRateBpMeta = const VerificationMeta(
    'interestRateBp',
  );
  @override
  late final GeneratedColumn<int> interestRateBp = GeneratedColumn<int>(
    'interest_rate_bp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  originationDate = GeneratedColumn<String>(
    'origination_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($LiabilitiesTable.$converteroriginationDaten);
  static const VerificationMeta _originationPrincipalMinorMeta =
      const VerificationMeta('originationPrincipalMinor');
  @override
  late final GeneratedColumn<int> originationPrincipalMinor =
      GeneratedColumn<int>(
        'origination_principal_minor',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _loanTermMeta = const VerificationMeta(
    'loanTerm',
  );
  @override
  late final GeneratedColumn<String> loanTerm = GeneratedColumn<String>(
    'loan_term',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextMonthlyPaymentMinorMeta =
      const VerificationMeta('nextMonthlyPaymentMinor');
  @override
  late final GeneratedColumn<int> nextMonthlyPaymentMinor =
      GeneratedColumn<int>(
        'next_monthly_payment_minor',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ytdInterestPaidMinorMeta =
      const VerificationMeta('ytdInterestPaidMinor');
  @override
  late final GeneratedColumn<int> ytdInterestPaidMinor = GeneratedColumn<int>(
    'ytd_interest_paid_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ytdPrincipalPaidMinorMeta =
      const VerificationMeta('ytdPrincipalPaidMinor');
  @override
  late final GeneratedColumn<int> ytdPrincipalPaidMinor = GeneratedColumn<int>(
    'ytd_principal_paid_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>($LiabilitiesTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($LiabilitiesTable.$converterpulledAt);
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    kind,
    currency,
    nextPaymentDueDate,
    minimumPaymentMinor,
    lastStatementBalanceMinor,
    lastStatementIssueDate,
    lastPaymentMinor,
    lastPaymentDate,
    isOverdue,
    aprs,
    interestRateBp,
    originationDate,
    originationPrincipalMinor,
    loanTerm,
    nextMonthlyPaymentMinor,
    ytdInterestPaidMinor,
    ytdPrincipalPaidMinor,
    payload,
    source,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liabilities';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiabilityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('minimum_payment_minor')) {
      context.handle(
        _minimumPaymentMinorMeta,
        minimumPaymentMinor.isAcceptableOrUnknown(
          data['minimum_payment_minor']!,
          _minimumPaymentMinorMeta,
        ),
      );
    }
    if (data.containsKey('last_statement_balance_minor')) {
      context.handle(
        _lastStatementBalanceMinorMeta,
        lastStatementBalanceMinor.isAcceptableOrUnknown(
          data['last_statement_balance_minor']!,
          _lastStatementBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('last_payment_minor')) {
      context.handle(
        _lastPaymentMinorMeta,
        lastPaymentMinor.isAcceptableOrUnknown(
          data['last_payment_minor']!,
          _lastPaymentMinorMeta,
        ),
      );
    }
    if (data.containsKey('is_overdue')) {
      context.handle(
        _isOverdueMeta,
        isOverdue.isAcceptableOrUnknown(data['is_overdue']!, _isOverdueMeta),
      );
    }
    if (data.containsKey('aprs')) {
      context.handle(
        _aprsMeta,
        aprs.isAcceptableOrUnknown(data['aprs']!, _aprsMeta),
      );
    } else if (isInserting) {
      context.missing(_aprsMeta);
    }
    if (data.containsKey('interest_rate_bp')) {
      context.handle(
        _interestRateBpMeta,
        interestRateBp.isAcceptableOrUnknown(
          data['interest_rate_bp']!,
          _interestRateBpMeta,
        ),
      );
    }
    if (data.containsKey('origination_principal_minor')) {
      context.handle(
        _originationPrincipalMinorMeta,
        originationPrincipalMinor.isAcceptableOrUnknown(
          data['origination_principal_minor']!,
          _originationPrincipalMinorMeta,
        ),
      );
    }
    if (data.containsKey('loan_term')) {
      context.handle(
        _loanTermMeta,
        loanTerm.isAcceptableOrUnknown(data['loan_term']!, _loanTermMeta),
      );
    }
    if (data.containsKey('next_monthly_payment_minor')) {
      context.handle(
        _nextMonthlyPaymentMinorMeta,
        nextMonthlyPaymentMinor.isAcceptableOrUnknown(
          data['next_monthly_payment_minor']!,
          _nextMonthlyPaymentMinorMeta,
        ),
      );
    }
    if (data.containsKey('ytd_interest_paid_minor')) {
      context.handle(
        _ytdInterestPaidMinorMeta,
        ytdInterestPaidMinor.isAcceptableOrUnknown(
          data['ytd_interest_paid_minor']!,
          _ytdInterestPaidMinorMeta,
        ),
      );
    }
    if (data.containsKey('ytd_principal_paid_minor')) {
      context.handle(
        _ytdPrincipalPaidMinorMeta,
        ytdPrincipalPaidMinor.isAcceptableOrUnknown(
          data['ytd_principal_paid_minor']!,
          _ytdPrincipalPaidMinorMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, kind};
  @override
  LiabilityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiabilityRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      kind: $LiabilitiesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      nextPaymentDueDate: $LiabilitiesTable.$converternextPaymentDueDaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}next_payment_due_date'],
            ),
          ),
      minimumPaymentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minimum_payment_minor'],
      ),
      lastStatementBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_statement_balance_minor'],
      ),
      lastStatementIssueDate: $LiabilitiesTable
          .$converterlastStatementIssueDaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}last_statement_issue_date'],
            ),
          ),
      lastPaymentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_payment_minor'],
      ),
      lastPaymentDate: $LiabilitiesTable.$converterlastPaymentDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_payment_date'],
        ),
      ),
      isOverdue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_overdue'],
      ),
      aprs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aprs'],
      )!,
      interestRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interest_rate_bp'],
      ),
      originationDate: $LiabilitiesTable.$converteroriginationDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origination_date'],
        ),
      ),
      originationPrincipalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origination_principal_minor'],
      ),
      loanTerm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_term'],
      ),
      nextMonthlyPaymentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_monthly_payment_minor'],
      ),
      ytdInterestPaidMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ytd_interest_paid_minor'],
      ),
      ytdPrincipalPaidMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ytd_principal_paid_minor'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      source: $LiabilitiesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      pulledAt: $LiabilitiesTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $LiabilitiesTable createAlias(String alias) {
    return $LiabilitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LiabilityKind, String, String> $converterkind =
      const EnumNameConverter<LiabilityKind>(LiabilityKind.values);
  static TypeConverter<LocalDate, String> $converternextPaymentDueDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converternextPaymentDueDaten =
      NullAwareTypeConverter.wrap($converternextPaymentDueDate);
  static TypeConverter<LocalDate, String> $converterlastStatementIssueDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterlastStatementIssueDaten =
      NullAwareTypeConverter.wrap($converterlastStatementIssueDate);
  static TypeConverter<LocalDate, String> $converterlastPaymentDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterlastPaymentDaten =
      NullAwareTypeConverter.wrap($converterlastPaymentDate);
  static TypeConverter<LocalDate, String> $converteroriginationDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converteroriginationDaten =
      NullAwareTypeConverter.wrap($converteroriginationDate);
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class LiabilityRow extends DataClass implements Insertable<LiabilityRow> {
  final String accountId;
  final LiabilityKind kind;
  final String? currency;
  final LocalDate? nextPaymentDueDate;
  final int? minimumPaymentMinor;
  final int? lastStatementBalanceMinor;
  final LocalDate? lastStatementIssueDate;
  final int? lastPaymentMinor;
  final LocalDate? lastPaymentDate;
  final bool? isOverdue;
  final String aprs;
  final int? interestRateBp;
  final LocalDate? originationDate;
  final int? originationPrincipalMinor;
  final String? loanTerm;
  final int? nextMonthlyPaymentMinor;
  final int? ytdInterestPaidMinor;
  final int? ytdPrincipalPaidMinor;
  final String payload;
  final DataSource source;
  final DateTime pulledAt;
  const LiabilityRow({
    required this.accountId,
    required this.kind,
    this.currency,
    this.nextPaymentDueDate,
    this.minimumPaymentMinor,
    this.lastStatementBalanceMinor,
    this.lastStatementIssueDate,
    this.lastPaymentMinor,
    this.lastPaymentDate,
    this.isOverdue,
    required this.aprs,
    this.interestRateBp,
    this.originationDate,
    this.originationPrincipalMinor,
    this.loanTerm,
    this.nextMonthlyPaymentMinor,
    this.ytdInterestPaidMinor,
    this.ytdPrincipalPaidMinor,
    required this.payload,
    required this.source,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    {
      map['kind'] = Variable<String>(
        $LiabilitiesTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    if (!nullToAbsent || nextPaymentDueDate != null) {
      map['next_payment_due_date'] = Variable<String>(
        $LiabilitiesTable.$converternextPaymentDueDaten.toSql(
          nextPaymentDueDate,
        ),
      );
    }
    if (!nullToAbsent || minimumPaymentMinor != null) {
      map['minimum_payment_minor'] = Variable<int>(minimumPaymentMinor);
    }
    if (!nullToAbsent || lastStatementBalanceMinor != null) {
      map['last_statement_balance_minor'] = Variable<int>(
        lastStatementBalanceMinor,
      );
    }
    if (!nullToAbsent || lastStatementIssueDate != null) {
      map['last_statement_issue_date'] = Variable<String>(
        $LiabilitiesTable.$converterlastStatementIssueDaten.toSql(
          lastStatementIssueDate,
        ),
      );
    }
    if (!nullToAbsent || lastPaymentMinor != null) {
      map['last_payment_minor'] = Variable<int>(lastPaymentMinor);
    }
    if (!nullToAbsent || lastPaymentDate != null) {
      map['last_payment_date'] = Variable<String>(
        $LiabilitiesTable.$converterlastPaymentDaten.toSql(lastPaymentDate),
      );
    }
    if (!nullToAbsent || isOverdue != null) {
      map['is_overdue'] = Variable<bool>(isOverdue);
    }
    map['aprs'] = Variable<String>(aprs);
    if (!nullToAbsent || interestRateBp != null) {
      map['interest_rate_bp'] = Variable<int>(interestRateBp);
    }
    if (!nullToAbsent || originationDate != null) {
      map['origination_date'] = Variable<String>(
        $LiabilitiesTable.$converteroriginationDaten.toSql(originationDate),
      );
    }
    if (!nullToAbsent || originationPrincipalMinor != null) {
      map['origination_principal_minor'] = Variable<int>(
        originationPrincipalMinor,
      );
    }
    if (!nullToAbsent || loanTerm != null) {
      map['loan_term'] = Variable<String>(loanTerm);
    }
    if (!nullToAbsent || nextMonthlyPaymentMinor != null) {
      map['next_monthly_payment_minor'] = Variable<int>(
        nextMonthlyPaymentMinor,
      );
    }
    if (!nullToAbsent || ytdInterestPaidMinor != null) {
      map['ytd_interest_paid_minor'] = Variable<int>(ytdInterestPaidMinor);
    }
    if (!nullToAbsent || ytdPrincipalPaidMinor != null) {
      map['ytd_principal_paid_minor'] = Variable<int>(ytdPrincipalPaidMinor);
    }
    map['payload'] = Variable<String>(payload);
    {
      map['source'] = Variable<String>(
        $LiabilitiesTable.$convertersource.toSql(source),
      );
    }
    {
      map['pulled_at'] = Variable<int>(
        $LiabilitiesTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  LiabilitiesCompanion toCompanion(bool nullToAbsent) {
    return LiabilitiesCompanion(
      accountId: Value(accountId),
      kind: Value(kind),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      nextPaymentDueDate: nextPaymentDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(nextPaymentDueDate),
      minimumPaymentMinor: minimumPaymentMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumPaymentMinor),
      lastStatementBalanceMinor:
          lastStatementBalanceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatementBalanceMinor),
      lastStatementIssueDate: lastStatementIssueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStatementIssueDate),
      lastPaymentMinor: lastPaymentMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPaymentMinor),
      lastPaymentDate: lastPaymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPaymentDate),
      isOverdue: isOverdue == null && nullToAbsent
          ? const Value.absent()
          : Value(isOverdue),
      aprs: Value(aprs),
      interestRateBp: interestRateBp == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRateBp),
      originationDate: originationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originationDate),
      originationPrincipalMinor:
          originationPrincipalMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(originationPrincipalMinor),
      loanTerm: loanTerm == null && nullToAbsent
          ? const Value.absent()
          : Value(loanTerm),
      nextMonthlyPaymentMinor: nextMonthlyPaymentMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(nextMonthlyPaymentMinor),
      ytdInterestPaidMinor: ytdInterestPaidMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(ytdInterestPaidMinor),
      ytdPrincipalPaidMinor: ytdPrincipalPaidMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(ytdPrincipalPaidMinor),
      payload: Value(payload),
      source: Value(source),
      pulledAt: Value(pulledAt),
    );
  }

  factory LiabilityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiabilityRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      kind: $LiabilitiesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      currency: serializer.fromJson<String?>(json['currency']),
      nextPaymentDueDate: serializer.fromJson<LocalDate?>(
        json['nextPaymentDueDate'],
      ),
      minimumPaymentMinor: serializer.fromJson<int?>(
        json['minimumPaymentMinor'],
      ),
      lastStatementBalanceMinor: serializer.fromJson<int?>(
        json['lastStatementBalanceMinor'],
      ),
      lastStatementIssueDate: serializer.fromJson<LocalDate?>(
        json['lastStatementIssueDate'],
      ),
      lastPaymentMinor: serializer.fromJson<int?>(json['lastPaymentMinor']),
      lastPaymentDate: serializer.fromJson<LocalDate?>(json['lastPaymentDate']),
      isOverdue: serializer.fromJson<bool?>(json['isOverdue']),
      aprs: serializer.fromJson<String>(json['aprs']),
      interestRateBp: serializer.fromJson<int?>(json['interestRateBp']),
      originationDate: serializer.fromJson<LocalDate?>(json['originationDate']),
      originationPrincipalMinor: serializer.fromJson<int?>(
        json['originationPrincipalMinor'],
      ),
      loanTerm: serializer.fromJson<String?>(json['loanTerm']),
      nextMonthlyPaymentMinor: serializer.fromJson<int?>(
        json['nextMonthlyPaymentMinor'],
      ),
      ytdInterestPaidMinor: serializer.fromJson<int?>(
        json['ytdInterestPaidMinor'],
      ),
      ytdPrincipalPaidMinor: serializer.fromJson<int?>(
        json['ytdPrincipalPaidMinor'],
      ),
      payload: serializer.fromJson<String>(json['payload']),
      source: $LiabilitiesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'kind': serializer.toJson<String>(
        $LiabilitiesTable.$converterkind.toJson(kind),
      ),
      'currency': serializer.toJson<String?>(currency),
      'nextPaymentDueDate': serializer.toJson<LocalDate?>(nextPaymentDueDate),
      'minimumPaymentMinor': serializer.toJson<int?>(minimumPaymentMinor),
      'lastStatementBalanceMinor': serializer.toJson<int?>(
        lastStatementBalanceMinor,
      ),
      'lastStatementIssueDate': serializer.toJson<LocalDate?>(
        lastStatementIssueDate,
      ),
      'lastPaymentMinor': serializer.toJson<int?>(lastPaymentMinor),
      'lastPaymentDate': serializer.toJson<LocalDate?>(lastPaymentDate),
      'isOverdue': serializer.toJson<bool?>(isOverdue),
      'aprs': serializer.toJson<String>(aprs),
      'interestRateBp': serializer.toJson<int?>(interestRateBp),
      'originationDate': serializer.toJson<LocalDate?>(originationDate),
      'originationPrincipalMinor': serializer.toJson<int?>(
        originationPrincipalMinor,
      ),
      'loanTerm': serializer.toJson<String?>(loanTerm),
      'nextMonthlyPaymentMinor': serializer.toJson<int?>(
        nextMonthlyPaymentMinor,
      ),
      'ytdInterestPaidMinor': serializer.toJson<int?>(ytdInterestPaidMinor),
      'ytdPrincipalPaidMinor': serializer.toJson<int?>(ytdPrincipalPaidMinor),
      'payload': serializer.toJson<String>(payload),
      'source': serializer.toJson<String>(
        $LiabilitiesTable.$convertersource.toJson(source),
      ),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  LiabilityRow copyWith({
    String? accountId,
    LiabilityKind? kind,
    Value<String?> currency = const Value.absent(),
    Value<LocalDate?> nextPaymentDueDate = const Value.absent(),
    Value<int?> minimumPaymentMinor = const Value.absent(),
    Value<int?> lastStatementBalanceMinor = const Value.absent(),
    Value<LocalDate?> lastStatementIssueDate = const Value.absent(),
    Value<int?> lastPaymentMinor = const Value.absent(),
    Value<LocalDate?> lastPaymentDate = const Value.absent(),
    Value<bool?> isOverdue = const Value.absent(),
    String? aprs,
    Value<int?> interestRateBp = const Value.absent(),
    Value<LocalDate?> originationDate = const Value.absent(),
    Value<int?> originationPrincipalMinor = const Value.absent(),
    Value<String?> loanTerm = const Value.absent(),
    Value<int?> nextMonthlyPaymentMinor = const Value.absent(),
    Value<int?> ytdInterestPaidMinor = const Value.absent(),
    Value<int?> ytdPrincipalPaidMinor = const Value.absent(),
    String? payload,
    DataSource? source,
    DateTime? pulledAt,
  }) => LiabilityRow(
    accountId: accountId ?? this.accountId,
    kind: kind ?? this.kind,
    currency: currency.present ? currency.value : this.currency,
    nextPaymentDueDate: nextPaymentDueDate.present
        ? nextPaymentDueDate.value
        : this.nextPaymentDueDate,
    minimumPaymentMinor: minimumPaymentMinor.present
        ? minimumPaymentMinor.value
        : this.minimumPaymentMinor,
    lastStatementBalanceMinor: lastStatementBalanceMinor.present
        ? lastStatementBalanceMinor.value
        : this.lastStatementBalanceMinor,
    lastStatementIssueDate: lastStatementIssueDate.present
        ? lastStatementIssueDate.value
        : this.lastStatementIssueDate,
    lastPaymentMinor: lastPaymentMinor.present
        ? lastPaymentMinor.value
        : this.lastPaymentMinor,
    lastPaymentDate: lastPaymentDate.present
        ? lastPaymentDate.value
        : this.lastPaymentDate,
    isOverdue: isOverdue.present ? isOverdue.value : this.isOverdue,
    aprs: aprs ?? this.aprs,
    interestRateBp: interestRateBp.present
        ? interestRateBp.value
        : this.interestRateBp,
    originationDate: originationDate.present
        ? originationDate.value
        : this.originationDate,
    originationPrincipalMinor: originationPrincipalMinor.present
        ? originationPrincipalMinor.value
        : this.originationPrincipalMinor,
    loanTerm: loanTerm.present ? loanTerm.value : this.loanTerm,
    nextMonthlyPaymentMinor: nextMonthlyPaymentMinor.present
        ? nextMonthlyPaymentMinor.value
        : this.nextMonthlyPaymentMinor,
    ytdInterestPaidMinor: ytdInterestPaidMinor.present
        ? ytdInterestPaidMinor.value
        : this.ytdInterestPaidMinor,
    ytdPrincipalPaidMinor: ytdPrincipalPaidMinor.present
        ? ytdPrincipalPaidMinor.value
        : this.ytdPrincipalPaidMinor,
    payload: payload ?? this.payload,
    source: source ?? this.source,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  LiabilityRow copyWithCompanion(LiabilitiesCompanion data) {
    return LiabilityRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      kind: data.kind.present ? data.kind.value : this.kind,
      currency: data.currency.present ? data.currency.value : this.currency,
      nextPaymentDueDate: data.nextPaymentDueDate.present
          ? data.nextPaymentDueDate.value
          : this.nextPaymentDueDate,
      minimumPaymentMinor: data.minimumPaymentMinor.present
          ? data.minimumPaymentMinor.value
          : this.minimumPaymentMinor,
      lastStatementBalanceMinor: data.lastStatementBalanceMinor.present
          ? data.lastStatementBalanceMinor.value
          : this.lastStatementBalanceMinor,
      lastStatementIssueDate: data.lastStatementIssueDate.present
          ? data.lastStatementIssueDate.value
          : this.lastStatementIssueDate,
      lastPaymentMinor: data.lastPaymentMinor.present
          ? data.lastPaymentMinor.value
          : this.lastPaymentMinor,
      lastPaymentDate: data.lastPaymentDate.present
          ? data.lastPaymentDate.value
          : this.lastPaymentDate,
      isOverdue: data.isOverdue.present ? data.isOverdue.value : this.isOverdue,
      aprs: data.aprs.present ? data.aprs.value : this.aprs,
      interestRateBp: data.interestRateBp.present
          ? data.interestRateBp.value
          : this.interestRateBp,
      originationDate: data.originationDate.present
          ? data.originationDate.value
          : this.originationDate,
      originationPrincipalMinor: data.originationPrincipalMinor.present
          ? data.originationPrincipalMinor.value
          : this.originationPrincipalMinor,
      loanTerm: data.loanTerm.present ? data.loanTerm.value : this.loanTerm,
      nextMonthlyPaymentMinor: data.nextMonthlyPaymentMinor.present
          ? data.nextMonthlyPaymentMinor.value
          : this.nextMonthlyPaymentMinor,
      ytdInterestPaidMinor: data.ytdInterestPaidMinor.present
          ? data.ytdInterestPaidMinor.value
          : this.ytdInterestPaidMinor,
      ytdPrincipalPaidMinor: data.ytdPrincipalPaidMinor.present
          ? data.ytdPrincipalPaidMinor.value
          : this.ytdPrincipalPaidMinor,
      payload: data.payload.present ? data.payload.value : this.payload,
      source: data.source.present ? data.source.value : this.source,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiabilityRow(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('currency: $currency, ')
          ..write('nextPaymentDueDate: $nextPaymentDueDate, ')
          ..write('minimumPaymentMinor: $minimumPaymentMinor, ')
          ..write('lastStatementBalanceMinor: $lastStatementBalanceMinor, ')
          ..write('lastStatementIssueDate: $lastStatementIssueDate, ')
          ..write('lastPaymentMinor: $lastPaymentMinor, ')
          ..write('lastPaymentDate: $lastPaymentDate, ')
          ..write('isOverdue: $isOverdue, ')
          ..write('aprs: $aprs, ')
          ..write('interestRateBp: $interestRateBp, ')
          ..write('originationDate: $originationDate, ')
          ..write('originationPrincipalMinor: $originationPrincipalMinor, ')
          ..write('loanTerm: $loanTerm, ')
          ..write('nextMonthlyPaymentMinor: $nextMonthlyPaymentMinor, ')
          ..write('ytdInterestPaidMinor: $ytdInterestPaidMinor, ')
          ..write('ytdPrincipalPaidMinor: $ytdPrincipalPaidMinor, ')
          ..write('payload: $payload, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    accountId,
    kind,
    currency,
    nextPaymentDueDate,
    minimumPaymentMinor,
    lastStatementBalanceMinor,
    lastStatementIssueDate,
    lastPaymentMinor,
    lastPaymentDate,
    isOverdue,
    aprs,
    interestRateBp,
    originationDate,
    originationPrincipalMinor,
    loanTerm,
    nextMonthlyPaymentMinor,
    ytdInterestPaidMinor,
    ytdPrincipalPaidMinor,
    payload,
    source,
    pulledAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiabilityRow &&
          other.accountId == this.accountId &&
          other.kind == this.kind &&
          other.currency == this.currency &&
          other.nextPaymentDueDate == this.nextPaymentDueDate &&
          other.minimumPaymentMinor == this.minimumPaymentMinor &&
          other.lastStatementBalanceMinor == this.lastStatementBalanceMinor &&
          other.lastStatementIssueDate == this.lastStatementIssueDate &&
          other.lastPaymentMinor == this.lastPaymentMinor &&
          other.lastPaymentDate == this.lastPaymentDate &&
          other.isOverdue == this.isOverdue &&
          other.aprs == this.aprs &&
          other.interestRateBp == this.interestRateBp &&
          other.originationDate == this.originationDate &&
          other.originationPrincipalMinor == this.originationPrincipalMinor &&
          other.loanTerm == this.loanTerm &&
          other.nextMonthlyPaymentMinor == this.nextMonthlyPaymentMinor &&
          other.ytdInterestPaidMinor == this.ytdInterestPaidMinor &&
          other.ytdPrincipalPaidMinor == this.ytdPrincipalPaidMinor &&
          other.payload == this.payload &&
          other.source == this.source &&
          other.pulledAt == this.pulledAt);
}

class LiabilitiesCompanion extends UpdateCompanion<LiabilityRow> {
  final Value<String> accountId;
  final Value<LiabilityKind> kind;
  final Value<String?> currency;
  final Value<LocalDate?> nextPaymentDueDate;
  final Value<int?> minimumPaymentMinor;
  final Value<int?> lastStatementBalanceMinor;
  final Value<LocalDate?> lastStatementIssueDate;
  final Value<int?> lastPaymentMinor;
  final Value<LocalDate?> lastPaymentDate;
  final Value<bool?> isOverdue;
  final Value<String> aprs;
  final Value<int?> interestRateBp;
  final Value<LocalDate?> originationDate;
  final Value<int?> originationPrincipalMinor;
  final Value<String?> loanTerm;
  final Value<int?> nextMonthlyPaymentMinor;
  final Value<int?> ytdInterestPaidMinor;
  final Value<int?> ytdPrincipalPaidMinor;
  final Value<String> payload;
  final Value<DataSource> source;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const LiabilitiesCompanion({
    this.accountId = const Value.absent(),
    this.kind = const Value.absent(),
    this.currency = const Value.absent(),
    this.nextPaymentDueDate = const Value.absent(),
    this.minimumPaymentMinor = const Value.absent(),
    this.lastStatementBalanceMinor = const Value.absent(),
    this.lastStatementIssueDate = const Value.absent(),
    this.lastPaymentMinor = const Value.absent(),
    this.lastPaymentDate = const Value.absent(),
    this.isOverdue = const Value.absent(),
    this.aprs = const Value.absent(),
    this.interestRateBp = const Value.absent(),
    this.originationDate = const Value.absent(),
    this.originationPrincipalMinor = const Value.absent(),
    this.loanTerm = const Value.absent(),
    this.nextMonthlyPaymentMinor = const Value.absent(),
    this.ytdInterestPaidMinor = const Value.absent(),
    this.ytdPrincipalPaidMinor = const Value.absent(),
    this.payload = const Value.absent(),
    this.source = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiabilitiesCompanion.insert({
    required String accountId,
    required LiabilityKind kind,
    this.currency = const Value.absent(),
    this.nextPaymentDueDate = const Value.absent(),
    this.minimumPaymentMinor = const Value.absent(),
    this.lastStatementBalanceMinor = const Value.absent(),
    this.lastStatementIssueDate = const Value.absent(),
    this.lastPaymentMinor = const Value.absent(),
    this.lastPaymentDate = const Value.absent(),
    this.isOverdue = const Value.absent(),
    required String aprs,
    this.interestRateBp = const Value.absent(),
    this.originationDate = const Value.absent(),
    this.originationPrincipalMinor = const Value.absent(),
    this.loanTerm = const Value.absent(),
    this.nextMonthlyPaymentMinor = const Value.absent(),
    this.ytdInterestPaidMinor = const Value.absent(),
    this.ytdPrincipalPaidMinor = const Value.absent(),
    required String payload,
    required DataSource source,
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       kind = Value(kind),
       aprs = Value(aprs),
       payload = Value(payload),
       source = Value(source),
       pulledAt = Value(pulledAt);
  static Insertable<LiabilityRow> custom({
    Expression<String>? accountId,
    Expression<String>? kind,
    Expression<String>? currency,
    Expression<String>? nextPaymentDueDate,
    Expression<int>? minimumPaymentMinor,
    Expression<int>? lastStatementBalanceMinor,
    Expression<String>? lastStatementIssueDate,
    Expression<int>? lastPaymentMinor,
    Expression<String>? lastPaymentDate,
    Expression<bool>? isOverdue,
    Expression<String>? aprs,
    Expression<int>? interestRateBp,
    Expression<String>? originationDate,
    Expression<int>? originationPrincipalMinor,
    Expression<String>? loanTerm,
    Expression<int>? nextMonthlyPaymentMinor,
    Expression<int>? ytdInterestPaidMinor,
    Expression<int>? ytdPrincipalPaidMinor,
    Expression<String>? payload,
    Expression<String>? source,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (kind != null) 'kind': kind,
      if (currency != null) 'currency': currency,
      if (nextPaymentDueDate != null)
        'next_payment_due_date': nextPaymentDueDate,
      if (minimumPaymentMinor != null)
        'minimum_payment_minor': minimumPaymentMinor,
      if (lastStatementBalanceMinor != null)
        'last_statement_balance_minor': lastStatementBalanceMinor,
      if (lastStatementIssueDate != null)
        'last_statement_issue_date': lastStatementIssueDate,
      if (lastPaymentMinor != null) 'last_payment_minor': lastPaymentMinor,
      if (lastPaymentDate != null) 'last_payment_date': lastPaymentDate,
      if (isOverdue != null) 'is_overdue': isOverdue,
      if (aprs != null) 'aprs': aprs,
      if (interestRateBp != null) 'interest_rate_bp': interestRateBp,
      if (originationDate != null) 'origination_date': originationDate,
      if (originationPrincipalMinor != null)
        'origination_principal_minor': originationPrincipalMinor,
      if (loanTerm != null) 'loan_term': loanTerm,
      if (nextMonthlyPaymentMinor != null)
        'next_monthly_payment_minor': nextMonthlyPaymentMinor,
      if (ytdInterestPaidMinor != null)
        'ytd_interest_paid_minor': ytdInterestPaidMinor,
      if (ytdPrincipalPaidMinor != null)
        'ytd_principal_paid_minor': ytdPrincipalPaidMinor,
      if (payload != null) 'payload': payload,
      if (source != null) 'source': source,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiabilitiesCompanion copyWith({
    Value<String>? accountId,
    Value<LiabilityKind>? kind,
    Value<String?>? currency,
    Value<LocalDate?>? nextPaymentDueDate,
    Value<int?>? minimumPaymentMinor,
    Value<int?>? lastStatementBalanceMinor,
    Value<LocalDate?>? lastStatementIssueDate,
    Value<int?>? lastPaymentMinor,
    Value<LocalDate?>? lastPaymentDate,
    Value<bool?>? isOverdue,
    Value<String>? aprs,
    Value<int?>? interestRateBp,
    Value<LocalDate?>? originationDate,
    Value<int?>? originationPrincipalMinor,
    Value<String?>? loanTerm,
    Value<int?>? nextMonthlyPaymentMinor,
    Value<int?>? ytdInterestPaidMinor,
    Value<int?>? ytdPrincipalPaidMinor,
    Value<String>? payload,
    Value<DataSource>? source,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return LiabilitiesCompanion(
      accountId: accountId ?? this.accountId,
      kind: kind ?? this.kind,
      currency: currency ?? this.currency,
      nextPaymentDueDate: nextPaymentDueDate ?? this.nextPaymentDueDate,
      minimumPaymentMinor: minimumPaymentMinor ?? this.minimumPaymentMinor,
      lastStatementBalanceMinor:
          lastStatementBalanceMinor ?? this.lastStatementBalanceMinor,
      lastStatementIssueDate:
          lastStatementIssueDate ?? this.lastStatementIssueDate,
      lastPaymentMinor: lastPaymentMinor ?? this.lastPaymentMinor,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      isOverdue: isOverdue ?? this.isOverdue,
      aprs: aprs ?? this.aprs,
      interestRateBp: interestRateBp ?? this.interestRateBp,
      originationDate: originationDate ?? this.originationDate,
      originationPrincipalMinor:
          originationPrincipalMinor ?? this.originationPrincipalMinor,
      loanTerm: loanTerm ?? this.loanTerm,
      nextMonthlyPaymentMinor:
          nextMonthlyPaymentMinor ?? this.nextMonthlyPaymentMinor,
      ytdInterestPaidMinor: ytdInterestPaidMinor ?? this.ytdInterestPaidMinor,
      ytdPrincipalPaidMinor:
          ytdPrincipalPaidMinor ?? this.ytdPrincipalPaidMinor,
      payload: payload ?? this.payload,
      source: source ?? this.source,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $LiabilitiesTable.$converterkind.toSql(kind.value),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (nextPaymentDueDate.present) {
      map['next_payment_due_date'] = Variable<String>(
        $LiabilitiesTable.$converternextPaymentDueDaten.toSql(
          nextPaymentDueDate.value,
        ),
      );
    }
    if (minimumPaymentMinor.present) {
      map['minimum_payment_minor'] = Variable<int>(minimumPaymentMinor.value);
    }
    if (lastStatementBalanceMinor.present) {
      map['last_statement_balance_minor'] = Variable<int>(
        lastStatementBalanceMinor.value,
      );
    }
    if (lastStatementIssueDate.present) {
      map['last_statement_issue_date'] = Variable<String>(
        $LiabilitiesTable.$converterlastStatementIssueDaten.toSql(
          lastStatementIssueDate.value,
        ),
      );
    }
    if (lastPaymentMinor.present) {
      map['last_payment_minor'] = Variable<int>(lastPaymentMinor.value);
    }
    if (lastPaymentDate.present) {
      map['last_payment_date'] = Variable<String>(
        $LiabilitiesTable.$converterlastPaymentDaten.toSql(
          lastPaymentDate.value,
        ),
      );
    }
    if (isOverdue.present) {
      map['is_overdue'] = Variable<bool>(isOverdue.value);
    }
    if (aprs.present) {
      map['aprs'] = Variable<String>(aprs.value);
    }
    if (interestRateBp.present) {
      map['interest_rate_bp'] = Variable<int>(interestRateBp.value);
    }
    if (originationDate.present) {
      map['origination_date'] = Variable<String>(
        $LiabilitiesTable.$converteroriginationDaten.toSql(
          originationDate.value,
        ),
      );
    }
    if (originationPrincipalMinor.present) {
      map['origination_principal_minor'] = Variable<int>(
        originationPrincipalMinor.value,
      );
    }
    if (loanTerm.present) {
      map['loan_term'] = Variable<String>(loanTerm.value);
    }
    if (nextMonthlyPaymentMinor.present) {
      map['next_monthly_payment_minor'] = Variable<int>(
        nextMonthlyPaymentMinor.value,
      );
    }
    if (ytdInterestPaidMinor.present) {
      map['ytd_interest_paid_minor'] = Variable<int>(
        ytdInterestPaidMinor.value,
      );
    }
    if (ytdPrincipalPaidMinor.present) {
      map['ytd_principal_paid_minor'] = Variable<int>(
        ytdPrincipalPaidMinor.value,
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $LiabilitiesTable.$convertersource.toSql(source.value),
      );
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $LiabilitiesTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiabilitiesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('kind: $kind, ')
          ..write('currency: $currency, ')
          ..write('nextPaymentDueDate: $nextPaymentDueDate, ')
          ..write('minimumPaymentMinor: $minimumPaymentMinor, ')
          ..write('lastStatementBalanceMinor: $lastStatementBalanceMinor, ')
          ..write('lastStatementIssueDate: $lastStatementIssueDate, ')
          ..write('lastPaymentMinor: $lastPaymentMinor, ')
          ..write('lastPaymentDate: $lastPaymentDate, ')
          ..write('isOverdue: $isOverdue, ')
          ..write('aprs: $aprs, ')
          ..write('interestRateBp: $interestRateBp, ')
          ..write('originationDate: $originationDate, ')
          ..write('originationPrincipalMinor: $originationPrincipalMinor, ')
          ..write('loanTerm: $loanTerm, ')
          ..write('nextMonthlyPaymentMinor: $nextMonthlyPaymentMinor, ')
          ..write('ytdInterestPaidMinor: $ytdInterestPaidMinor, ')
          ..write('ytdPrincipalPaidMinor: $ytdPrincipalPaidMinor, ')
          ..write('payload: $payload, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, BillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> dueDate =
      GeneratedColumn<String>(
        'due_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($BillsTable.$converterdueDate);
  @override
  late final GeneratedColumnWithTypeConverter<RecurringCadence?, String>
  cadence = GeneratedColumn<String>(
    'cadence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RecurringCadence?>($BillsTable.$convertercadencen);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<String> streamId = GeneratedColumn<String>(
    'stream_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _liabilityAccountIdMeta =
      const VerificationMeta('liabilityAccountId');
  @override
  late final GeneratedColumn<String> liabilityAccountId =
      GeneratedColumn<String>(
        'liability_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reminderOffsetDaysMeta =
      const VerificationMeta('reminderOffsetDays');
  @override
  late final GeneratedColumn<String> reminderOffsetDays =
      GeneratedColumn<String>(
        'reminder_offset_days',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _autopayMeta = const VerificationMeta(
    'autopay',
  );
  @override
  late final GeneratedColumn<bool> autopay = GeneratedColumn<bool>(
    'autopay',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("autopay" IN (0, 1))',
    ),
  );
  static const VerificationMeta _paidOccurrencesMeta = const VerificationMeta(
    'paidOccurrences',
  );
  @override
  late final GeneratedColumn<String> paidOccurrences = GeneratedColumn<String>(
    'paid_occurrences',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BillsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BillsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($BillsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amountMinor,
    currency,
    dueDate,
    cadence,
    accountId,
    streamId,
    liabilityAccountId,
    reminderOffsetDays,
    reminderMinutes,
    active,
    autopay,
    paidOccurrences,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    }
    if (data.containsKey('liability_account_id')) {
      context.handle(
        _liabilityAccountIdMeta,
        liabilityAccountId.isAcceptableOrUnknown(
          data['liability_account_id']!,
          _liabilityAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('reminder_offset_days')) {
      context.handle(
        _reminderOffsetDaysMeta,
        reminderOffsetDays.isAcceptableOrUnknown(
          data['reminder_offset_days']!,
          _reminderOffsetDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderOffsetDaysMeta);
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderMinutesMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('autopay')) {
      context.handle(
        _autopayMeta,
        autopay.isAcceptableOrUnknown(data['autopay']!, _autopayMeta),
      );
    } else if (isInserting) {
      context.missing(_autopayMeta);
    }
    if (data.containsKey('paid_occurrences')) {
      context.handle(
        _paidOccurrencesMeta,
        paidOccurrences.isAcceptableOrUnknown(
          data['paid_occurrences']!,
          _paidOccurrencesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paidOccurrencesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      dueDate: $BillsTable.$converterdueDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_date'],
        )!,
      ),
      cadence: $BillsTable.$convertercadencen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cadence'],
        ),
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_id'],
      ),
      liabilityAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}liability_account_id'],
      ),
      reminderOffsetDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_offset_days'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      autopay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}autopay'],
      )!,
      paidOccurrences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_occurrences'],
      )!,
      createdAt: $BillsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $BillsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $BillsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdueDate =
      const LocalDateColumnConverter();
  static TypeConverter<RecurringCadence, String> $convertercadence =
      const RecurringCadenceColumnConverter();
  static TypeConverter<RecurringCadence?, String?> $convertercadencen =
      NullAwareTypeConverter.wrap($convertercadence);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class BillRow extends DataClass implements Insertable<BillRow> {
  final String id;
  final String? name;
  final int? amountMinor;
  final String? currency;
  final LocalDate dueDate;
  final RecurringCadence? cadence;
  final String? accountId;
  final String? streamId;
  final String? liabilityAccountId;
  final String reminderOffsetDays;
  final int reminderMinutes;
  final bool active;
  final bool autopay;
  final String paidOccurrences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const BillRow({
    required this.id,
    this.name,
    this.amountMinor,
    this.currency,
    required this.dueDate,
    this.cadence,
    this.accountId,
    this.streamId,
    this.liabilityAccountId,
    required this.reminderOffsetDays,
    required this.reminderMinutes,
    required this.active,
    required this.autopay,
    required this.paidOccurrences,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    {
      map['due_date'] = Variable<String>(
        $BillsTable.$converterdueDate.toSql(dueDate),
      );
    }
    if (!nullToAbsent || cadence != null) {
      map['cadence'] = Variable<String>(
        $BillsTable.$convertercadencen.toSql(cadence),
      );
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || streamId != null) {
      map['stream_id'] = Variable<String>(streamId);
    }
    if (!nullToAbsent || liabilityAccountId != null) {
      map['liability_account_id'] = Variable<String>(liabilityAccountId);
    }
    map['reminder_offset_days'] = Variable<String>(reminderOffsetDays);
    map['reminder_minutes'] = Variable<int>(reminderMinutes);
    map['active'] = Variable<bool>(active);
    map['autopay'] = Variable<bool>(autopay);
    map['paid_occurrences'] = Variable<String>(paidOccurrences);
    {
      map['created_at'] = Variable<int>(
        $BillsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $BillsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $BillsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      dueDate: Value(dueDate),
      cadence: cadence == null && nullToAbsent
          ? const Value.absent()
          : Value(cadence),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      streamId: streamId == null && nullToAbsent
          ? const Value.absent()
          : Value(streamId),
      liabilityAccountId: liabilityAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(liabilityAccountId),
      reminderOffsetDays: Value(reminderOffsetDays),
      reminderMinutes: Value(reminderMinutes),
      active: Value(active),
      autopay: Value(autopay),
      paidOccurrences: Value(paidOccurrences),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      currency: serializer.fromJson<String?>(json['currency']),
      dueDate: serializer.fromJson<LocalDate>(json['dueDate']),
      cadence: serializer.fromJson<RecurringCadence?>(json['cadence']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      streamId: serializer.fromJson<String?>(json['streamId']),
      liabilityAccountId: serializer.fromJson<String?>(
        json['liabilityAccountId'],
      ),
      reminderOffsetDays: serializer.fromJson<String>(
        json['reminderOffsetDays'],
      ),
      reminderMinutes: serializer.fromJson<int>(json['reminderMinutes']),
      active: serializer.fromJson<bool>(json['active']),
      autopay: serializer.fromJson<bool>(json['autopay']),
      paidOccurrences: serializer.fromJson<String>(json['paidOccurrences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'currency': serializer.toJson<String?>(currency),
      'dueDate': serializer.toJson<LocalDate>(dueDate),
      'cadence': serializer.toJson<RecurringCadence?>(cadence),
      'accountId': serializer.toJson<String?>(accountId),
      'streamId': serializer.toJson<String?>(streamId),
      'liabilityAccountId': serializer.toJson<String?>(liabilityAccountId),
      'reminderOffsetDays': serializer.toJson<String>(reminderOffsetDays),
      'reminderMinutes': serializer.toJson<int>(reminderMinutes),
      'active': serializer.toJson<bool>(active),
      'autopay': serializer.toJson<bool>(autopay),
      'paidOccurrences': serializer.toJson<String>(paidOccurrences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BillRow copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<int?> amountMinor = const Value.absent(),
    Value<String?> currency = const Value.absent(),
    LocalDate? dueDate,
    Value<RecurringCadence?> cadence = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    Value<String?> streamId = const Value.absent(),
    Value<String?> liabilityAccountId = const Value.absent(),
    String? reminderOffsetDays,
    int? reminderMinutes,
    bool? active,
    bool? autopay,
    String? paidOccurrences,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BillRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    currency: currency.present ? currency.value : this.currency,
    dueDate: dueDate ?? this.dueDate,
    cadence: cadence.present ? cadence.value : this.cadence,
    accountId: accountId.present ? accountId.value : this.accountId,
    streamId: streamId.present ? streamId.value : this.streamId,
    liabilityAccountId: liabilityAccountId.present
        ? liabilityAccountId.value
        : this.liabilityAccountId,
    reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    active: active ?? this.active,
    autopay: autopay ?? this.autopay,
    paidOccurrences: paidOccurrences ?? this.paidOccurrences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BillRow copyWithCompanion(BillsCompanion data) {
    return BillRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      liabilityAccountId: data.liabilityAccountId.present
          ? data.liabilityAccountId.value
          : this.liabilityAccountId,
      reminderOffsetDays: data.reminderOffsetDays.present
          ? data.reminderOffsetDays.value
          : this.reminderOffsetDays,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      active: data.active.present ? data.active.value : this.active,
      autopay: data.autopay.present ? data.autopay.value : this.autopay,
      paidOccurrences: data.paidOccurrences.present
          ? data.paidOccurrences.value
          : this.paidOccurrences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('cadence: $cadence, ')
          ..write('accountId: $accountId, ')
          ..write('streamId: $streamId, ')
          ..write('liabilityAccountId: $liabilityAccountId, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('active: $active, ')
          ..write('autopay: $autopay, ')
          ..write('paidOccurrences: $paidOccurrences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amountMinor,
    currency,
    dueDate,
    cadence,
    accountId,
    streamId,
    liabilityAccountId,
    reminderOffsetDays,
    reminderMinutes,
    active,
    autopay,
    paidOccurrences,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.dueDate == this.dueDate &&
          other.cadence == this.cadence &&
          other.accountId == this.accountId &&
          other.streamId == this.streamId &&
          other.liabilityAccountId == this.liabilityAccountId &&
          other.reminderOffsetDays == this.reminderOffsetDays &&
          other.reminderMinutes == this.reminderMinutes &&
          other.active == this.active &&
          other.autopay == this.autopay &&
          other.paidOccurrences == this.paidOccurrences &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BillsCompanion extends UpdateCompanion<BillRow> {
  final Value<String> id;
  final Value<String?> name;
  final Value<int?> amountMinor;
  final Value<String?> currency;
  final Value<LocalDate> dueDate;
  final Value<RecurringCadence?> cadence;
  final Value<String?> accountId;
  final Value<String?> streamId;
  final Value<String?> liabilityAccountId;
  final Value<String> reminderOffsetDays;
  final Value<int> reminderMinutes;
  final Value<bool> active;
  final Value<bool> autopay;
  final Value<String> paidOccurrences;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.cadence = const Value.absent(),
    this.accountId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.liabilityAccountId = const Value.absent(),
    this.reminderOffsetDays = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.active = const Value.absent(),
    this.autopay = const Value.absent(),
    this.paidOccurrences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    required LocalDate dueDate,
    this.cadence = const Value.absent(),
    this.accountId = const Value.absent(),
    this.streamId = const Value.absent(),
    this.liabilityAccountId = const Value.absent(),
    required String reminderOffsetDays,
    required int reminderMinutes,
    required bool active,
    required bool autopay,
    required String paidOccurrences,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dueDate = Value(dueDate),
       reminderOffsetDays = Value(reminderOffsetDays),
       reminderMinutes = Value(reminderMinutes),
       active = Value(active),
       autopay = Value(autopay),
       paidOccurrences = Value(paidOccurrences),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BillRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? dueDate,
    Expression<String>? cadence,
    Expression<String>? accountId,
    Expression<String>? streamId,
    Expression<String>? liabilityAccountId,
    Expression<String>? reminderOffsetDays,
    Expression<int>? reminderMinutes,
    Expression<bool>? active,
    Expression<bool>? autopay,
    Expression<String>? paidOccurrences,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (dueDate != null) 'due_date': dueDate,
      if (cadence != null) 'cadence': cadence,
      if (accountId != null) 'account_id': accountId,
      if (streamId != null) 'stream_id': streamId,
      if (liabilityAccountId != null)
        'liability_account_id': liabilityAccountId,
      if (reminderOffsetDays != null)
        'reminder_offset_days': reminderOffsetDays,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (active != null) 'active': active,
      if (autopay != null) 'autopay': autopay,
      if (paidOccurrences != null) 'paid_occurrences': paidOccurrences,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<int?>? amountMinor,
    Value<String?>? currency,
    Value<LocalDate>? dueDate,
    Value<RecurringCadence?>? cadence,
    Value<String?>? accountId,
    Value<String?>? streamId,
    Value<String?>? liabilityAccountId,
    Value<String>? reminderOffsetDays,
    Value<int>? reminderMinutes,
    Value<bool>? active,
    Value<bool>? autopay,
    Value<String>? paidOccurrences,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      cadence: cadence ?? this.cadence,
      accountId: accountId ?? this.accountId,
      streamId: streamId ?? this.streamId,
      liabilityAccountId: liabilityAccountId ?? this.liabilityAccountId,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      active: active ?? this.active,
      autopay: autopay ?? this.autopay,
      paidOccurrences: paidOccurrences ?? this.paidOccurrences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(
        $BillsTable.$converterdueDate.toSql(dueDate.value),
      );
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(
        $BillsTable.$convertercadencen.toSql(cadence.value),
      );
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (streamId.present) {
      map['stream_id'] = Variable<String>(streamId.value);
    }
    if (liabilityAccountId.present) {
      map['liability_account_id'] = Variable<String>(liabilityAccountId.value);
    }
    if (reminderOffsetDays.present) {
      map['reminder_offset_days'] = Variable<String>(reminderOffsetDays.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (autopay.present) {
      map['autopay'] = Variable<bool>(autopay.value);
    }
    if (paidOccurrences.present) {
      map['paid_occurrences'] = Variable<String>(paidOccurrences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BillsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $BillsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $BillsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('dueDate: $dueDate, ')
          ..write('cadence: $cadence, ')
          ..write('accountId: $accountId, ')
          ..write('streamId: $streamId, ')
          ..write('liabilityAccountId: $liabilityAccountId, ')
          ..write('reminderOffsetDays: $reminderOffsetDays, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('active: $active, ')
          ..write('autopay: $autopay, ')
          ..write('paidOccurrences: $paidOccurrences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillAlertsTable extends BillAlerts
    with TableInfo<$BillAlertsTable, BillAlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillAlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> dueDate =
      GeneratedColumn<String>(
        'due_date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($BillAlertsTable.$converterdueDate);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> raisedAt =
      GeneratedColumn<int>(
        'raised_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BillAlertsTable.$converterraisedAt);
  @override
  List<GeneratedColumn> get $columns => [billId, dueDate, raisedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillAlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {billId, dueDate};
  @override
  BillAlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillAlertRow(
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      dueDate: $BillAlertsTable.$converterdueDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}due_date'],
        )!,
      ),
      raisedAt: $BillAlertsTable.$converterraisedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}raised_at'],
        )!,
      ),
    );
  }

  @override
  $BillAlertsTable createAlias(String alias) {
    return $BillAlertsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdueDate =
      const LocalDateColumnConverter();
  static TypeConverter<DateTime, int> $converterraisedAt =
      const UtcMillisColumnConverter();
}

class BillAlertRow extends DataClass implements Insertable<BillAlertRow> {
  final String billId;
  final LocalDate dueDate;
  final DateTime raisedAt;
  const BillAlertRow({
    required this.billId,
    required this.dueDate,
    required this.raisedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bill_id'] = Variable<String>(billId);
    {
      map['due_date'] = Variable<String>(
        $BillAlertsTable.$converterdueDate.toSql(dueDate),
      );
    }
    {
      map['raised_at'] = Variable<int>(
        $BillAlertsTable.$converterraisedAt.toSql(raisedAt),
      );
    }
    return map;
  }

  BillAlertsCompanion toCompanion(bool nullToAbsent) {
    return BillAlertsCompanion(
      billId: Value(billId),
      dueDate: Value(dueDate),
      raisedAt: Value(raisedAt),
    );
  }

  factory BillAlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillAlertRow(
      billId: serializer.fromJson<String>(json['billId']),
      dueDate: serializer.fromJson<LocalDate>(json['dueDate']),
      raisedAt: serializer.fromJson<DateTime>(json['raisedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'billId': serializer.toJson<String>(billId),
      'dueDate': serializer.toJson<LocalDate>(dueDate),
      'raisedAt': serializer.toJson<DateTime>(raisedAt),
    };
  }

  BillAlertRow copyWith({
    String? billId,
    LocalDate? dueDate,
    DateTime? raisedAt,
  }) => BillAlertRow(
    billId: billId ?? this.billId,
    dueDate: dueDate ?? this.dueDate,
    raisedAt: raisedAt ?? this.raisedAt,
  );
  BillAlertRow copyWithCompanion(BillAlertsCompanion data) {
    return BillAlertRow(
      billId: data.billId.present ? data.billId.value : this.billId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      raisedAt: data.raisedAt.present ? data.raisedAt.value : this.raisedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillAlertRow(')
          ..write('billId: $billId, ')
          ..write('dueDate: $dueDate, ')
          ..write('raisedAt: $raisedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(billId, dueDate, raisedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillAlertRow &&
          other.billId == this.billId &&
          other.dueDate == this.dueDate &&
          other.raisedAt == this.raisedAt);
}

class BillAlertsCompanion extends UpdateCompanion<BillAlertRow> {
  final Value<String> billId;
  final Value<LocalDate> dueDate;
  final Value<DateTime> raisedAt;
  final Value<int> rowid;
  const BillAlertsCompanion({
    this.billId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.raisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillAlertsCompanion.insert({
    required String billId,
    required LocalDate dueDate,
    required DateTime raisedAt,
    this.rowid = const Value.absent(),
  }) : billId = Value(billId),
       dueDate = Value(dueDate),
       raisedAt = Value(raisedAt);
  static Insertable<BillAlertRow> custom({
    Expression<String>? billId,
    Expression<String>? dueDate,
    Expression<int>? raisedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (billId != null) 'bill_id': billId,
      if (dueDate != null) 'due_date': dueDate,
      if (raisedAt != null) 'raised_at': raisedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillAlertsCompanion copyWith({
    Value<String>? billId,
    Value<LocalDate>? dueDate,
    Value<DateTime>? raisedAt,
    Value<int>? rowid,
  }) {
    return BillAlertsCompanion(
      billId: billId ?? this.billId,
      dueDate: dueDate ?? this.dueDate,
      raisedAt: raisedAt ?? this.raisedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(
        $BillAlertsTable.$converterdueDate.toSql(dueDate.value),
      );
    }
    if (raisedAt.present) {
      map['raised_at'] = Variable<int>(
        $BillAlertsTable.$converterraisedAt.toSql(raisedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillAlertsCompanion(')
          ..write('billId: $billId, ')
          ..write('dueDate: $dueDate, ')
          ..write('raisedAt: $raisedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecuritiesTable extends Securities
    with TableInfo<$SecuritiesTable, SecurityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecuritiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tickerSymbolMeta = const VerificationMeta(
    'tickerSymbol',
  );
  @override
  late final GeneratedColumn<String> tickerSymbol = GeneratedColumn<String>(
    'ticker_symbol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCashEquivalentMeta = const VerificationMeta(
    'isCashEquivalent',
  );
  @override
  late final GeneratedColumn<bool> isCashEquivalent = GeneratedColumn<bool>(
    'is_cash_equivalent',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_cash_equivalent" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal?, String> closePrice =
      GeneratedColumn<String>(
        'close_price',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Decimal?>($SecuritiesTable.$converterclosePricen);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  closePriceAsOf = GeneratedColumn<String>(
    'close_price_as_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($SecuritiesTable.$converterclosePriceAsOfn);
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>($SecuritiesTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SecuritiesTable.$converterpulledAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    tickerSymbol,
    type,
    isCashEquivalent,
    closePrice,
    closePriceAsOf,
    currencyCode,
    source,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'securities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecurityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('ticker_symbol')) {
      context.handle(
        _tickerSymbolMeta,
        tickerSymbol.isAcceptableOrUnknown(
          data['ticker_symbol']!,
          _tickerSymbolMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('is_cash_equivalent')) {
      context.handle(
        _isCashEquivalentMeta,
        isCashEquivalent.isAcceptableOrUnknown(
          data['is_cash_equivalent']!,
          _isCashEquivalentMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecurityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecurityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      tickerSymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticker_symbol'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      isCashEquivalent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_cash_equivalent'],
      ),
      closePrice: $SecuritiesTable.$converterclosePricen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}close_price'],
        ),
      ),
      closePriceAsOf: $SecuritiesTable.$converterclosePriceAsOfn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}close_price_as_of'],
        ),
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      source: $SecuritiesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      pulledAt: $SecuritiesTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $SecuritiesTable createAlias(String alias) {
    return $SecuritiesTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterclosePrice =
      const DecimalColumnConverter();
  static TypeConverter<Decimal?, String?> $converterclosePricen =
      NullAwareTypeConverter.wrap($converterclosePrice);
  static TypeConverter<LocalDate, String> $converterclosePriceAsOf =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterclosePriceAsOfn =
      NullAwareTypeConverter.wrap($converterclosePriceAsOf);
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class SecurityRow extends DataClass implements Insertable<SecurityRow> {
  final String id;
  final String? name;
  final String? tickerSymbol;
  final String? type;
  final bool? isCashEquivalent;
  final Decimal? closePrice;
  final LocalDate? closePriceAsOf;
  final String currencyCode;
  final DataSource source;
  final DateTime pulledAt;
  const SecurityRow({
    required this.id,
    this.name,
    this.tickerSymbol,
    this.type,
    this.isCashEquivalent,
    this.closePrice,
    this.closePriceAsOf,
    required this.currencyCode,
    required this.source,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || tickerSymbol != null) {
      map['ticker_symbol'] = Variable<String>(tickerSymbol);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || isCashEquivalent != null) {
      map['is_cash_equivalent'] = Variable<bool>(isCashEquivalent);
    }
    if (!nullToAbsent || closePrice != null) {
      map['close_price'] = Variable<String>(
        $SecuritiesTable.$converterclosePricen.toSql(closePrice),
      );
    }
    if (!nullToAbsent || closePriceAsOf != null) {
      map['close_price_as_of'] = Variable<String>(
        $SecuritiesTable.$converterclosePriceAsOfn.toSql(closePriceAsOf),
      );
    }
    map['currency_code'] = Variable<String>(currencyCode);
    {
      map['source'] = Variable<String>(
        $SecuritiesTable.$convertersource.toSql(source),
      );
    }
    {
      map['pulled_at'] = Variable<int>(
        $SecuritiesTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  SecuritiesCompanion toCompanion(bool nullToAbsent) {
    return SecuritiesCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      tickerSymbol: tickerSymbol == null && nullToAbsent
          ? const Value.absent()
          : Value(tickerSymbol),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      isCashEquivalent: isCashEquivalent == null && nullToAbsent
          ? const Value.absent()
          : Value(isCashEquivalent),
      closePrice: closePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(closePrice),
      closePriceAsOf: closePriceAsOf == null && nullToAbsent
          ? const Value.absent()
          : Value(closePriceAsOf),
      currencyCode: Value(currencyCode),
      source: Value(source),
      pulledAt: Value(pulledAt),
    );
  }

  factory SecurityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecurityRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      tickerSymbol: serializer.fromJson<String?>(json['tickerSymbol']),
      type: serializer.fromJson<String?>(json['type']),
      isCashEquivalent: serializer.fromJson<bool?>(json['isCashEquivalent']),
      closePrice: serializer.fromJson<Decimal?>(json['closePrice']),
      closePriceAsOf: serializer.fromJson<LocalDate?>(json['closePriceAsOf']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      source: $SecuritiesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'tickerSymbol': serializer.toJson<String?>(tickerSymbol),
      'type': serializer.toJson<String?>(type),
      'isCashEquivalent': serializer.toJson<bool?>(isCashEquivalent),
      'closePrice': serializer.toJson<Decimal?>(closePrice),
      'closePriceAsOf': serializer.toJson<LocalDate?>(closePriceAsOf),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'source': serializer.toJson<String>(
        $SecuritiesTable.$convertersource.toJson(source),
      ),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  SecurityRow copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> tickerSymbol = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<bool?> isCashEquivalent = const Value.absent(),
    Value<Decimal?> closePrice = const Value.absent(),
    Value<LocalDate?> closePriceAsOf = const Value.absent(),
    String? currencyCode,
    DataSource? source,
    DateTime? pulledAt,
  }) => SecurityRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    tickerSymbol: tickerSymbol.present ? tickerSymbol.value : this.tickerSymbol,
    type: type.present ? type.value : this.type,
    isCashEquivalent: isCashEquivalent.present
        ? isCashEquivalent.value
        : this.isCashEquivalent,
    closePrice: closePrice.present ? closePrice.value : this.closePrice,
    closePriceAsOf: closePriceAsOf.present
        ? closePriceAsOf.value
        : this.closePriceAsOf,
    currencyCode: currencyCode ?? this.currencyCode,
    source: source ?? this.source,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  SecurityRow copyWithCompanion(SecuritiesCompanion data) {
    return SecurityRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tickerSymbol: data.tickerSymbol.present
          ? data.tickerSymbol.value
          : this.tickerSymbol,
      type: data.type.present ? data.type.value : this.type,
      isCashEquivalent: data.isCashEquivalent.present
          ? data.isCashEquivalent.value
          : this.isCashEquivalent,
      closePrice: data.closePrice.present
          ? data.closePrice.value
          : this.closePrice,
      closePriceAsOf: data.closePriceAsOf.present
          ? data.closePriceAsOf.value
          : this.closePriceAsOf,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      source: data.source.present ? data.source.value : this.source,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecurityRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tickerSymbol: $tickerSymbol, ')
          ..write('type: $type, ')
          ..write('isCashEquivalent: $isCashEquivalent, ')
          ..write('closePrice: $closePrice, ')
          ..write('closePriceAsOf: $closePriceAsOf, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    tickerSymbol,
    type,
    isCashEquivalent,
    closePrice,
    closePriceAsOf,
    currencyCode,
    source,
    pulledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecurityRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.tickerSymbol == this.tickerSymbol &&
          other.type == this.type &&
          other.isCashEquivalent == this.isCashEquivalent &&
          other.closePrice == this.closePrice &&
          other.closePriceAsOf == this.closePriceAsOf &&
          other.currencyCode == this.currencyCode &&
          other.source == this.source &&
          other.pulledAt == this.pulledAt);
}

class SecuritiesCompanion extends UpdateCompanion<SecurityRow> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> tickerSymbol;
  final Value<String?> type;
  final Value<bool?> isCashEquivalent;
  final Value<Decimal?> closePrice;
  final Value<LocalDate?> closePriceAsOf;
  final Value<String> currencyCode;
  final Value<DataSource> source;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const SecuritiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tickerSymbol = const Value.absent(),
    this.type = const Value.absent(),
    this.isCashEquivalent = const Value.absent(),
    this.closePrice = const Value.absent(),
    this.closePriceAsOf = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.source = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecuritiesCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.tickerSymbol = const Value.absent(),
    this.type = const Value.absent(),
    this.isCashEquivalent = const Value.absent(),
    this.closePrice = const Value.absent(),
    this.closePriceAsOf = const Value.absent(),
    required String currencyCode,
    required DataSource source,
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       currencyCode = Value(currencyCode),
       source = Value(source),
       pulledAt = Value(pulledAt);
  static Insertable<SecurityRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? tickerSymbol,
    Expression<String>? type,
    Expression<bool>? isCashEquivalent,
    Expression<String>? closePrice,
    Expression<String>? closePriceAsOf,
    Expression<String>? currencyCode,
    Expression<String>? source,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tickerSymbol != null) 'ticker_symbol': tickerSymbol,
      if (type != null) 'type': type,
      if (isCashEquivalent != null) 'is_cash_equivalent': isCashEquivalent,
      if (closePrice != null) 'close_price': closePrice,
      if (closePriceAsOf != null) 'close_price_as_of': closePriceAsOf,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (source != null) 'source': source,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecuritiesCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? tickerSymbol,
    Value<String?>? type,
    Value<bool?>? isCashEquivalent,
    Value<Decimal?>? closePrice,
    Value<LocalDate?>? closePriceAsOf,
    Value<String>? currencyCode,
    Value<DataSource>? source,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return SecuritiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tickerSymbol: tickerSymbol ?? this.tickerSymbol,
      type: type ?? this.type,
      isCashEquivalent: isCashEquivalent ?? this.isCashEquivalent,
      closePrice: closePrice ?? this.closePrice,
      closePriceAsOf: closePriceAsOf ?? this.closePriceAsOf,
      currencyCode: currencyCode ?? this.currencyCode,
      source: source ?? this.source,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tickerSymbol.present) {
      map['ticker_symbol'] = Variable<String>(tickerSymbol.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isCashEquivalent.present) {
      map['is_cash_equivalent'] = Variable<bool>(isCashEquivalent.value);
    }
    if (closePrice.present) {
      map['close_price'] = Variable<String>(
        $SecuritiesTable.$converterclosePricen.toSql(closePrice.value),
      );
    }
    if (closePriceAsOf.present) {
      map['close_price_as_of'] = Variable<String>(
        $SecuritiesTable.$converterclosePriceAsOfn.toSql(closePriceAsOf.value),
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $SecuritiesTable.$convertersource.toSql(source.value),
      );
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $SecuritiesTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecuritiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tickerSymbol: $tickerSymbol, ')
          ..write('type: $type, ')
          ..write('isCashEquivalent: $isCashEquivalent, ')
          ..write('closePrice: $closePrice, ')
          ..write('closePriceAsOf: $closePriceAsOf, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HoldingsTable extends Holdings
    with TableInfo<$HoldingsTable, HoldingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoldingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _securityIdMeta = const VerificationMeta(
    'securityId',
  );
  @override
  late final GeneratedColumn<String> securityId = GeneratedColumn<String>(
    'security_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity =
      GeneratedColumn<String>(
        'quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($HoldingsTable.$converterquantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String>
  institutionPrice = GeneratedColumn<String>(
    'institution_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Decimal>($HoldingsTable.$converterinstitutionPrice);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  institutionPriceAsOf = GeneratedColumn<String>(
    'institution_price_as_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($HoldingsTable.$converterinstitutionPriceAsOfn);
  static const VerificationMeta _institutionValueMinorMeta =
      const VerificationMeta('institutionValueMinor');
  @override
  late final GeneratedColumn<int> institutionValueMinor = GeneratedColumn<int>(
    'institution_value_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costBasisMinorMeta = const VerificationMeta(
    'costBasisMinor',
  );
  @override
  late final GeneratedColumn<int> costBasisMinor = GeneratedColumn<int>(
    'cost_basis_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>($HoldingsTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($HoldingsTable.$converterpulledAt);
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    securityId,
    quantity,
    institutionPrice,
    institutionPriceAsOf,
    institutionValueMinor,
    costBasisMinor,
    currency,
    source,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holdings';
  @override
  VerificationContext validateIntegrity(
    Insertable<HoldingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('security_id')) {
      context.handle(
        _securityIdMeta,
        securityId.isAcceptableOrUnknown(data['security_id']!, _securityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_securityIdMeta);
    }
    if (data.containsKey('institution_value_minor')) {
      context.handle(
        _institutionValueMinorMeta,
        institutionValueMinor.isAcceptableOrUnknown(
          data['institution_value_minor']!,
          _institutionValueMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionValueMinorMeta);
    }
    if (data.containsKey('cost_basis_minor')) {
      context.handle(
        _costBasisMinorMeta,
        costBasisMinor.isAcceptableOrUnknown(
          data['cost_basis_minor']!,
          _costBasisMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, securityId};
  @override
  HoldingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HoldingRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      securityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_id'],
      )!,
      quantity: $HoldingsTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity'],
        )!,
      ),
      institutionPrice: $HoldingsTable.$converterinstitutionPrice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}institution_price'],
        )!,
      ),
      institutionPriceAsOf: $HoldingsTable.$converterinstitutionPriceAsOfn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}institution_price_as_of'],
            ),
          ),
      institutionValueMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}institution_value_minor'],
      )!,
      costBasisMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_basis_minor'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      source: $HoldingsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      pulledAt: $HoldingsTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $HoldingsTable createAlias(String alias) {
    return $HoldingsTable(attachedDatabase, alias);
  }

  static TypeConverter<Decimal, String> $converterquantity =
      const DecimalColumnConverter();
  static TypeConverter<Decimal, String> $converterinstitutionPrice =
      const DecimalColumnConverter();
  static TypeConverter<LocalDate, String> $converterinstitutionPriceAsOf =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $converterinstitutionPriceAsOfn =
      NullAwareTypeConverter.wrap($converterinstitutionPriceAsOf);
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class HoldingRow extends DataClass implements Insertable<HoldingRow> {
  final String accountId;
  final String securityId;
  final Decimal quantity;
  final Decimal institutionPrice;
  final LocalDate? institutionPriceAsOf;
  final int institutionValueMinor;
  final int? costBasisMinor;
  final String currency;
  final DataSource source;
  final DateTime pulledAt;
  const HoldingRow({
    required this.accountId,
    required this.securityId,
    required this.quantity,
    required this.institutionPrice,
    this.institutionPriceAsOf,
    required this.institutionValueMinor,
    this.costBasisMinor,
    required this.currency,
    required this.source,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['security_id'] = Variable<String>(securityId);
    {
      map['quantity'] = Variable<String>(
        $HoldingsTable.$converterquantity.toSql(quantity),
      );
    }
    {
      map['institution_price'] = Variable<String>(
        $HoldingsTable.$converterinstitutionPrice.toSql(institutionPrice),
      );
    }
    if (!nullToAbsent || institutionPriceAsOf != null) {
      map['institution_price_as_of'] = Variable<String>(
        $HoldingsTable.$converterinstitutionPriceAsOfn.toSql(
          institutionPriceAsOf,
        ),
      );
    }
    map['institution_value_minor'] = Variable<int>(institutionValueMinor);
    if (!nullToAbsent || costBasisMinor != null) {
      map['cost_basis_minor'] = Variable<int>(costBasisMinor);
    }
    map['currency'] = Variable<String>(currency);
    {
      map['source'] = Variable<String>(
        $HoldingsTable.$convertersource.toSql(source),
      );
    }
    {
      map['pulled_at'] = Variable<int>(
        $HoldingsTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  HoldingsCompanion toCompanion(bool nullToAbsent) {
    return HoldingsCompanion(
      accountId: Value(accountId),
      securityId: Value(securityId),
      quantity: Value(quantity),
      institutionPrice: Value(institutionPrice),
      institutionPriceAsOf: institutionPriceAsOf == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionPriceAsOf),
      institutionValueMinor: Value(institutionValueMinor),
      costBasisMinor: costBasisMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(costBasisMinor),
      currency: Value(currency),
      source: Value(source),
      pulledAt: Value(pulledAt),
    );
  }

  factory HoldingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HoldingRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      securityId: serializer.fromJson<String>(json['securityId']),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      institutionPrice: serializer.fromJson<Decimal>(json['institutionPrice']),
      institutionPriceAsOf: serializer.fromJson<LocalDate?>(
        json['institutionPriceAsOf'],
      ),
      institutionValueMinor: serializer.fromJson<int>(
        json['institutionValueMinor'],
      ),
      costBasisMinor: serializer.fromJson<int?>(json['costBasisMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      source: $HoldingsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'securityId': serializer.toJson<String>(securityId),
      'quantity': serializer.toJson<Decimal>(quantity),
      'institutionPrice': serializer.toJson<Decimal>(institutionPrice),
      'institutionPriceAsOf': serializer.toJson<LocalDate?>(
        institutionPriceAsOf,
      ),
      'institutionValueMinor': serializer.toJson<int>(institutionValueMinor),
      'costBasisMinor': serializer.toJson<int?>(costBasisMinor),
      'currency': serializer.toJson<String>(currency),
      'source': serializer.toJson<String>(
        $HoldingsTable.$convertersource.toJson(source),
      ),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  HoldingRow copyWith({
    String? accountId,
    String? securityId,
    Decimal? quantity,
    Decimal? institutionPrice,
    Value<LocalDate?> institutionPriceAsOf = const Value.absent(),
    int? institutionValueMinor,
    Value<int?> costBasisMinor = const Value.absent(),
    String? currency,
    DataSource? source,
    DateTime? pulledAt,
  }) => HoldingRow(
    accountId: accountId ?? this.accountId,
    securityId: securityId ?? this.securityId,
    quantity: quantity ?? this.quantity,
    institutionPrice: institutionPrice ?? this.institutionPrice,
    institutionPriceAsOf: institutionPriceAsOf.present
        ? institutionPriceAsOf.value
        : this.institutionPriceAsOf,
    institutionValueMinor: institutionValueMinor ?? this.institutionValueMinor,
    costBasisMinor: costBasisMinor.present
        ? costBasisMinor.value
        : this.costBasisMinor,
    currency: currency ?? this.currency,
    source: source ?? this.source,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  HoldingRow copyWithCompanion(HoldingsCompanion data) {
    return HoldingRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      securityId: data.securityId.present
          ? data.securityId.value
          : this.securityId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      institutionPrice: data.institutionPrice.present
          ? data.institutionPrice.value
          : this.institutionPrice,
      institutionPriceAsOf: data.institutionPriceAsOf.present
          ? data.institutionPriceAsOf.value
          : this.institutionPriceAsOf,
      institutionValueMinor: data.institutionValueMinor.present
          ? data.institutionValueMinor.value
          : this.institutionValueMinor,
      costBasisMinor: data.costBasisMinor.present
          ? data.costBasisMinor.value
          : this.costBasisMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      source: data.source.present ? data.source.value : this.source,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HoldingRow(')
          ..write('accountId: $accountId, ')
          ..write('securityId: $securityId, ')
          ..write('quantity: $quantity, ')
          ..write('institutionPrice: $institutionPrice, ')
          ..write('institutionPriceAsOf: $institutionPriceAsOf, ')
          ..write('institutionValueMinor: $institutionValueMinor, ')
          ..write('costBasisMinor: $costBasisMinor, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    securityId,
    quantity,
    institutionPrice,
    institutionPriceAsOf,
    institutionValueMinor,
    costBasisMinor,
    currency,
    source,
    pulledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HoldingRow &&
          other.accountId == this.accountId &&
          other.securityId == this.securityId &&
          other.quantity == this.quantity &&
          other.institutionPrice == this.institutionPrice &&
          other.institutionPriceAsOf == this.institutionPriceAsOf &&
          other.institutionValueMinor == this.institutionValueMinor &&
          other.costBasisMinor == this.costBasisMinor &&
          other.currency == this.currency &&
          other.source == this.source &&
          other.pulledAt == this.pulledAt);
}

class HoldingsCompanion extends UpdateCompanion<HoldingRow> {
  final Value<String> accountId;
  final Value<String> securityId;
  final Value<Decimal> quantity;
  final Value<Decimal> institutionPrice;
  final Value<LocalDate?> institutionPriceAsOf;
  final Value<int> institutionValueMinor;
  final Value<int?> costBasisMinor;
  final Value<String> currency;
  final Value<DataSource> source;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const HoldingsCompanion({
    this.accountId = const Value.absent(),
    this.securityId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.institutionPrice = const Value.absent(),
    this.institutionPriceAsOf = const Value.absent(),
    this.institutionValueMinor = const Value.absent(),
    this.costBasisMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.source = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HoldingsCompanion.insert({
    required String accountId,
    required String securityId,
    required Decimal quantity,
    required Decimal institutionPrice,
    this.institutionPriceAsOf = const Value.absent(),
    required int institutionValueMinor,
    this.costBasisMinor = const Value.absent(),
    required String currency,
    required DataSource source,
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       securityId = Value(securityId),
       quantity = Value(quantity),
       institutionPrice = Value(institutionPrice),
       institutionValueMinor = Value(institutionValueMinor),
       currency = Value(currency),
       source = Value(source),
       pulledAt = Value(pulledAt);
  static Insertable<HoldingRow> custom({
    Expression<String>? accountId,
    Expression<String>? securityId,
    Expression<String>? quantity,
    Expression<String>? institutionPrice,
    Expression<String>? institutionPriceAsOf,
    Expression<int>? institutionValueMinor,
    Expression<int>? costBasisMinor,
    Expression<String>? currency,
    Expression<String>? source,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (securityId != null) 'security_id': securityId,
      if (quantity != null) 'quantity': quantity,
      if (institutionPrice != null) 'institution_price': institutionPrice,
      if (institutionPriceAsOf != null)
        'institution_price_as_of': institutionPriceAsOf,
      if (institutionValueMinor != null)
        'institution_value_minor': institutionValueMinor,
      if (costBasisMinor != null) 'cost_basis_minor': costBasisMinor,
      if (currency != null) 'currency': currency,
      if (source != null) 'source': source,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HoldingsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? securityId,
    Value<Decimal>? quantity,
    Value<Decimal>? institutionPrice,
    Value<LocalDate?>? institutionPriceAsOf,
    Value<int>? institutionValueMinor,
    Value<int?>? costBasisMinor,
    Value<String>? currency,
    Value<DataSource>? source,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return HoldingsCompanion(
      accountId: accountId ?? this.accountId,
      securityId: securityId ?? this.securityId,
      quantity: quantity ?? this.quantity,
      institutionPrice: institutionPrice ?? this.institutionPrice,
      institutionPriceAsOf: institutionPriceAsOf ?? this.institutionPriceAsOf,
      institutionValueMinor:
          institutionValueMinor ?? this.institutionValueMinor,
      costBasisMinor: costBasisMinor ?? this.costBasisMinor,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (securityId.present) {
      map['security_id'] = Variable<String>(securityId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(
        $HoldingsTable.$converterquantity.toSql(quantity.value),
      );
    }
    if (institutionPrice.present) {
      map['institution_price'] = Variable<String>(
        $HoldingsTable.$converterinstitutionPrice.toSql(institutionPrice.value),
      );
    }
    if (institutionPriceAsOf.present) {
      map['institution_price_as_of'] = Variable<String>(
        $HoldingsTable.$converterinstitutionPriceAsOfn.toSql(
          institutionPriceAsOf.value,
        ),
      );
    }
    if (institutionValueMinor.present) {
      map['institution_value_minor'] = Variable<int>(
        institutionValueMinor.value,
      );
    }
    if (costBasisMinor.present) {
      map['cost_basis_minor'] = Variable<int>(costBasisMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $HoldingsTable.$convertersource.toSql(source.value),
      );
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $HoldingsTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoldingsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('securityId: $securityId, ')
          ..write('quantity: $quantity, ')
          ..write('institutionPrice: $institutionPrice, ')
          ..write('institutionPriceAsOf: $institutionPriceAsOf, ')
          ..write('institutionValueMinor: $institutionValueMinor, ')
          ..write('costBasisMinor: $costBasisMinor, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentTransactionsTable extends InvestmentTransactions
    with TableInfo<$InvestmentTransactionsTable, InvestmentTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _securityIdMeta = const VerificationMeta(
    'securityId',
  );
  @override
  late final GeneratedColumn<String> securityId = GeneratedColumn<String>(
    'security_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($InvestmentTransactionsTable.$converterdate);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtypeMeta = const VerificationMeta(
    'subtype',
  );
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
    'subtype',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> quantity =
      GeneratedColumn<String>(
        'quantity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($InvestmentTransactionsTable.$converterquantity);
  @override
  late final GeneratedColumnWithTypeConverter<Decimal, String> price =
      GeneratedColumn<String>(
        'price',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Decimal>($InvestmentTransactionsTable.$converterprice);
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feesMinorMeta = const VerificationMeta(
    'feesMinor',
  );
  @override
  late final GeneratedColumn<int> feesMinor = GeneratedColumn<int>(
    'fees_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $InvestmentTransactionsTable.$converterdeletedAtn,
      );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>(
        $InvestmentTransactionsTable.$convertersource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> pulledAt =
      GeneratedColumn<int>(
        'pulled_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $InvestmentTransactionsTable.$converterpulledAt,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    securityId,
    date,
    name,
    type,
    subtype,
    quantity,
    price,
    amountMinor,
    feesMinor,
    currency,
    deletedAt,
    syncVersion,
    source,
    pulledAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('security_id')) {
      context.handle(
        _securityIdMeta,
        securityId.isAcceptableOrUnknown(data['security_id']!, _securityIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(
        _subtypeMeta,
        subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('fees_minor')) {
      context.handle(
        _feesMinorMeta,
        feesMinor.isAcceptableOrUnknown(data['fees_minor']!, _feesMinorMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvestmentTransactionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      securityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_id'],
      ),
      date: $InvestmentTransactionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subtype: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtype'],
      ),
      quantity: $InvestmentTransactionsTable.$converterquantity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quantity'],
        )!,
      ),
      price: $InvestmentTransactionsTable.$converterprice.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}price'],
        )!,
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      feesMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fees_minor'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      deletedAt: $InvestmentTransactionsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
      source: $InvestmentTransactionsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      pulledAt: $InvestmentTransactionsTable.$converterpulledAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pulled_at'],
        )!,
      ),
    );
  }

  @override
  $InvestmentTransactionsTable createAlias(String alias) {
    return $InvestmentTransactionsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdate =
      const LocalDateColumnConverter();
  static TypeConverter<Decimal, String> $converterquantity =
      const DecimalColumnConverter();
  static TypeConverter<Decimal, String> $converterprice =
      const DecimalColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $converterpulledAt =
      const UtcMillisColumnConverter();
}

class InvestmentTransactionRow extends DataClass
    implements Insertable<InvestmentTransactionRow> {
  final String id;
  final String accountId;
  final String? securityId;
  final LocalDate date;
  final String name;
  final String type;
  final String? subtype;
  final Decimal quantity;
  final Decimal price;
  final int amountMinor;
  final int? feesMinor;
  final String currency;
  final DateTime? deletedAt;
  final int syncVersion;
  final DataSource source;
  final DateTime pulledAt;
  const InvestmentTransactionRow({
    required this.id,
    required this.accountId,
    this.securityId,
    required this.date,
    required this.name,
    required this.type,
    this.subtype,
    required this.quantity,
    required this.price,
    required this.amountMinor,
    this.feesMinor,
    required this.currency,
    this.deletedAt,
    required this.syncVersion,
    required this.source,
    required this.pulledAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || securityId != null) {
      map['security_id'] = Variable<String>(securityId);
    }
    {
      map['date'] = Variable<String>(
        $InvestmentTransactionsTable.$converterdate.toSql(date),
      );
    }
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
    }
    {
      map['quantity'] = Variable<String>(
        $InvestmentTransactionsTable.$converterquantity.toSql(quantity),
      );
    }
    {
      map['price'] = Variable<String>(
        $InvestmentTransactionsTable.$converterprice.toSql(price),
      );
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    if (!nullToAbsent || feesMinor != null) {
      map['fees_minor'] = Variable<int>(feesMinor);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $InvestmentTransactionsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    map['sync_version'] = Variable<int>(syncVersion);
    {
      map['source'] = Variable<String>(
        $InvestmentTransactionsTable.$convertersource.toSql(source),
      );
    }
    {
      map['pulled_at'] = Variable<int>(
        $InvestmentTransactionsTable.$converterpulledAt.toSql(pulledAt),
      );
    }
    return map;
  }

  InvestmentTransactionsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      securityId: securityId == null && nullToAbsent
          ? const Value.absent()
          : Value(securityId),
      date: Value(date),
      name: Value(name),
      type: Value(type),
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      quantity: Value(quantity),
      price: Value(price),
      amountMinor: Value(amountMinor),
      feesMinor: feesMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(feesMinor),
      currency: Value(currency),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncVersion: Value(syncVersion),
      source: Value(source),
      pulledAt: Value(pulledAt),
    );
  }

  factory InvestmentTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      securityId: serializer.fromJson<String?>(json['securityId']),
      date: serializer.fromJson<LocalDate>(json['date']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String?>(json['subtype']),
      quantity: serializer.fromJson<Decimal>(json['quantity']),
      price: serializer.fromJson<Decimal>(json['price']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      feesMinor: serializer.fromJson<int?>(json['feesMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      source: $InvestmentTransactionsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      pulledAt: serializer.fromJson<DateTime>(json['pulledAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'securityId': serializer.toJson<String?>(securityId),
      'date': serializer.toJson<LocalDate>(date),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String?>(subtype),
      'quantity': serializer.toJson<Decimal>(quantity),
      'price': serializer.toJson<Decimal>(price),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'feesMinor': serializer.toJson<int?>(feesMinor),
      'currency': serializer.toJson<String>(currency),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'source': serializer.toJson<String>(
        $InvestmentTransactionsTable.$convertersource.toJson(source),
      ),
      'pulledAt': serializer.toJson<DateTime>(pulledAt),
    };
  }

  InvestmentTransactionRow copyWith({
    String? id,
    String? accountId,
    Value<String?> securityId = const Value.absent(),
    LocalDate? date,
    String? name,
    String? type,
    Value<String?> subtype = const Value.absent(),
    Decimal? quantity,
    Decimal? price,
    int? amountMinor,
    Value<int?> feesMinor = const Value.absent(),
    String? currency,
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncVersion,
    DataSource? source,
    DateTime? pulledAt,
  }) => InvestmentTransactionRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    securityId: securityId.present ? securityId.value : this.securityId,
    date: date ?? this.date,
    name: name ?? this.name,
    type: type ?? this.type,
    subtype: subtype.present ? subtype.value : this.subtype,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    amountMinor: amountMinor ?? this.amountMinor,
    feesMinor: feesMinor.present ? feesMinor.value : this.feesMinor,
    currency: currency ?? this.currency,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncVersion: syncVersion ?? this.syncVersion,
    source: source ?? this.source,
    pulledAt: pulledAt ?? this.pulledAt,
  );
  InvestmentTransactionRow copyWithCompanion(
    InvestmentTransactionsCompanion data,
  ) {
    return InvestmentTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      securityId: data.securityId.present
          ? data.securityId.value
          : this.securityId,
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      feesMinor: data.feesMinor.present ? data.feesMinor.value : this.feesMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
      source: data.source.present ? data.source.value : this.source,
      pulledAt: data.pulledAt.present ? data.pulledAt.value : this.pulledAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentTransactionRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('securityId: $securityId, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('feesMinor: $feesMinor, ')
          ..write('currency: $currency, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    securityId,
    date,
    name,
    type,
    subtype,
    quantity,
    price,
    amountMinor,
    feesMinor,
    currency,
    deletedAt,
    syncVersion,
    source,
    pulledAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentTransactionRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.securityId == this.securityId &&
          other.date == this.date &&
          other.name == this.name &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.amountMinor == this.amountMinor &&
          other.feesMinor == this.feesMinor &&
          other.currency == this.currency &&
          other.deletedAt == this.deletedAt &&
          other.syncVersion == this.syncVersion &&
          other.source == this.source &&
          other.pulledAt == this.pulledAt);
}

class InvestmentTransactionsCompanion
    extends UpdateCompanion<InvestmentTransactionRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String?> securityId;
  final Value<LocalDate> date;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> subtype;
  final Value<Decimal> quantity;
  final Value<Decimal> price;
  final Value<int> amountMinor;
  final Value<int?> feesMinor;
  final Value<String> currency;
  final Value<DateTime?> deletedAt;
  final Value<int> syncVersion;
  final Value<DataSource> source;
  final Value<DateTime> pulledAt;
  final Value<int> rowid;
  const InvestmentTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.securityId = const Value.absent(),
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.feesMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.source = const Value.absent(),
    this.pulledAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentTransactionsCompanion.insert({
    required String id,
    required String accountId,
    this.securityId = const Value.absent(),
    required LocalDate date,
    required String name,
    required String type,
    this.subtype = const Value.absent(),
    required Decimal quantity,
    required Decimal price,
    required int amountMinor,
    this.feesMinor = const Value.absent(),
    required String currency,
    this.deletedAt = const Value.absent(),
    required int syncVersion,
    required DataSource source,
    required DateTime pulledAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       date = Value(date),
       name = Value(name),
       type = Value(type),
       quantity = Value(quantity),
       price = Value(price),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       syncVersion = Value(syncVersion),
       source = Value(source),
       pulledAt = Value(pulledAt);
  static Insertable<InvestmentTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? securityId,
    Expression<String>? date,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? quantity,
    Expression<String>? price,
    Expression<int>? amountMinor,
    Expression<int>? feesMinor,
    Expression<String>? currency,
    Expression<int>? deletedAt,
    Expression<int>? syncVersion,
    Expression<String>? source,
    Expression<int>? pulledAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (securityId != null) 'security_id': securityId,
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (feesMinor != null) 'fees_minor': feesMinor,
      if (currency != null) 'currency': currency,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (source != null) 'source': source,
      if (pulledAt != null) 'pulled_at': pulledAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String?>? securityId,
    Value<LocalDate>? date,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? subtype,
    Value<Decimal>? quantity,
    Value<Decimal>? price,
    Value<int>? amountMinor,
    Value<int?>? feesMinor,
    Value<String>? currency,
    Value<DateTime?>? deletedAt,
    Value<int>? syncVersion,
    Value<DataSource>? source,
    Value<DateTime>? pulledAt,
    Value<int>? rowid,
  }) {
    return InvestmentTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      securityId: securityId ?? this.securityId,
      date: date ?? this.date,
      name: name ?? this.name,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amountMinor: amountMinor ?? this.amountMinor,
      feesMinor: feesMinor ?? this.feesMinor,
      currency: currency ?? this.currency,
      deletedAt: deletedAt ?? this.deletedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      source: source ?? this.source,
      pulledAt: pulledAt ?? this.pulledAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (securityId.present) {
      map['security_id'] = Variable<String>(securityId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $InvestmentTransactionsTable.$converterdate.toSql(date.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(
        $InvestmentTransactionsTable.$converterquantity.toSql(quantity.value),
      );
    }
    if (price.present) {
      map['price'] = Variable<String>(
        $InvestmentTransactionsTable.$converterprice.toSql(price.value),
      );
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (feesMinor.present) {
      map['fees_minor'] = Variable<int>(feesMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $InvestmentTransactionsTable.$converterdeletedAtn.toSql(
          deletedAt.value,
        ),
      );
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $InvestmentTransactionsTable.$convertersource.toSql(source.value),
      );
    }
    if (pulledAt.present) {
      map['pulled_at'] = Variable<int>(
        $InvestmentTransactionsTable.$converterpulledAt.toSql(pulledAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('securityId: $securityId, ')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('feesMinor: $feesMinor, ')
          ..write('currency: $currency, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('source: $source, ')
          ..write('pulledAt: $pulledAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceSnapshotsTable extends BalanceSnapshots
    with TableInfo<$BalanceSnapshotsTable, BalanceSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($BalanceSnapshotsTable.$converterdate);
  static const VerificationMeta _currentMinorMeta = const VerificationMeta(
    'currentMinor',
  );
  @override
  late final GeneratedColumn<int> currentMinor = GeneratedColumn<int>(
    'current_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableMinorMeta = const VerificationMeta(
    'availableMinor',
  );
  @override
  late final GeneratedColumn<int> availableMinor = GeneratedColumn<int>(
    'available_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _limitMinorMeta = const VerificationMeta(
    'limitMinor',
  );
  @override
  late final GeneratedColumn<int> limitMinor = GeneratedColumn<int>(
    'limit_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DataSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DataSource>($BalanceSnapshotsTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> writtenAt =
      GeneratedColumn<int>(
        'written_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BalanceSnapshotsTable.$converterwrittenAt);
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    date,
    currentMinor,
    availableMinor,
    limitMinor,
    currency,
    source,
    writtenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('current_minor')) {
      context.handle(
        _currentMinorMeta,
        currentMinor.isAcceptableOrUnknown(
          data['current_minor']!,
          _currentMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentMinorMeta);
    }
    if (data.containsKey('available_minor')) {
      context.handle(
        _availableMinorMeta,
        availableMinor.isAcceptableOrUnknown(
          data['available_minor']!,
          _availableMinorMeta,
        ),
      );
    }
    if (data.containsKey('limit_minor')) {
      context.handle(
        _limitMinorMeta,
        limitMinor.isAcceptableOrUnknown(data['limit_minor']!, _limitMinorMeta),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, date};
  @override
  BalanceSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceSnapshotRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      date: $BalanceSnapshotsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      currentMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_minor'],
      )!,
      availableMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}available_minor'],
      ),
      limitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_minor'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      source: $BalanceSnapshotsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      writtenAt: $BalanceSnapshotsTable.$converterwrittenAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}written_at'],
        )!,
      ),
    );
  }

  @override
  $BalanceSnapshotsTable createAlias(String alias) {
    return $BalanceSnapshotsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdate =
      const LocalDateColumnConverter();
  static JsonTypeConverter2<DataSource, String, String> $convertersource =
      const EnumNameConverter<DataSource>(DataSource.values);
  static TypeConverter<DateTime, int> $converterwrittenAt =
      const UtcMillisColumnConverter();
}

class BalanceSnapshotRow extends DataClass
    implements Insertable<BalanceSnapshotRow> {
  final String accountId;
  final LocalDate date;
  final int currentMinor;
  final int? availableMinor;
  final int? limitMinor;
  final String currency;
  final DataSource source;
  final DateTime writtenAt;
  const BalanceSnapshotRow({
    required this.accountId,
    required this.date,
    required this.currentMinor,
    this.availableMinor,
    this.limitMinor,
    required this.currency,
    required this.source,
    required this.writtenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    {
      map['date'] = Variable<String>(
        $BalanceSnapshotsTable.$converterdate.toSql(date),
      );
    }
    map['current_minor'] = Variable<int>(currentMinor);
    if (!nullToAbsent || availableMinor != null) {
      map['available_minor'] = Variable<int>(availableMinor);
    }
    if (!nullToAbsent || limitMinor != null) {
      map['limit_minor'] = Variable<int>(limitMinor);
    }
    map['currency'] = Variable<String>(currency);
    {
      map['source'] = Variable<String>(
        $BalanceSnapshotsTable.$convertersource.toSql(source),
      );
    }
    {
      map['written_at'] = Variable<int>(
        $BalanceSnapshotsTable.$converterwrittenAt.toSql(writtenAt),
      );
    }
    return map;
  }

  BalanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return BalanceSnapshotsCompanion(
      accountId: Value(accountId),
      date: Value(date),
      currentMinor: Value(currentMinor),
      availableMinor: availableMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(availableMinor),
      limitMinor: limitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(limitMinor),
      currency: Value(currency),
      source: Value(source),
      writtenAt: Value(writtenAt),
    );
  }

  factory BalanceSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceSnapshotRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      date: serializer.fromJson<LocalDate>(json['date']),
      currentMinor: serializer.fromJson<int>(json['currentMinor']),
      availableMinor: serializer.fromJson<int?>(json['availableMinor']),
      limitMinor: serializer.fromJson<int?>(json['limitMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      source: $BalanceSnapshotsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      writtenAt: serializer.fromJson<DateTime>(json['writtenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'date': serializer.toJson<LocalDate>(date),
      'currentMinor': serializer.toJson<int>(currentMinor),
      'availableMinor': serializer.toJson<int?>(availableMinor),
      'limitMinor': serializer.toJson<int?>(limitMinor),
      'currency': serializer.toJson<String>(currency),
      'source': serializer.toJson<String>(
        $BalanceSnapshotsTable.$convertersource.toJson(source),
      ),
      'writtenAt': serializer.toJson<DateTime>(writtenAt),
    };
  }

  BalanceSnapshotRow copyWith({
    String? accountId,
    LocalDate? date,
    int? currentMinor,
    Value<int?> availableMinor = const Value.absent(),
    Value<int?> limitMinor = const Value.absent(),
    String? currency,
    DataSource? source,
    DateTime? writtenAt,
  }) => BalanceSnapshotRow(
    accountId: accountId ?? this.accountId,
    date: date ?? this.date,
    currentMinor: currentMinor ?? this.currentMinor,
    availableMinor: availableMinor.present
        ? availableMinor.value
        : this.availableMinor,
    limitMinor: limitMinor.present ? limitMinor.value : this.limitMinor,
    currency: currency ?? this.currency,
    source: source ?? this.source,
    writtenAt: writtenAt ?? this.writtenAt,
  );
  BalanceSnapshotRow copyWithCompanion(BalanceSnapshotsCompanion data) {
    return BalanceSnapshotRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      date: data.date.present ? data.date.value : this.date,
      currentMinor: data.currentMinor.present
          ? data.currentMinor.value
          : this.currentMinor,
      availableMinor: data.availableMinor.present
          ? data.availableMinor.value
          : this.availableMinor,
      limitMinor: data.limitMinor.present
          ? data.limitMinor.value
          : this.limitMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      source: data.source.present ? data.source.value : this.source,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshotRow(')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('currentMinor: $currentMinor, ')
          ..write('availableMinor: $availableMinor, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('writtenAt: $writtenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    date,
    currentMinor,
    availableMinor,
    limitMinor,
    currency,
    source,
    writtenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceSnapshotRow &&
          other.accountId == this.accountId &&
          other.date == this.date &&
          other.currentMinor == this.currentMinor &&
          other.availableMinor == this.availableMinor &&
          other.limitMinor == this.limitMinor &&
          other.currency == this.currency &&
          other.source == this.source &&
          other.writtenAt == this.writtenAt);
}

class BalanceSnapshotsCompanion extends UpdateCompanion<BalanceSnapshotRow> {
  final Value<String> accountId;
  final Value<LocalDate> date;
  final Value<int> currentMinor;
  final Value<int?> availableMinor;
  final Value<int?> limitMinor;
  final Value<String> currency;
  final Value<DataSource> source;
  final Value<DateTime> writtenAt;
  final Value<int> rowid;
  const BalanceSnapshotsCompanion({
    this.accountId = const Value.absent(),
    this.date = const Value.absent(),
    this.currentMinor = const Value.absent(),
    this.availableMinor = const Value.absent(),
    this.limitMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.source = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceSnapshotsCompanion.insert({
    required String accountId,
    required LocalDate date,
    required int currentMinor,
    this.availableMinor = const Value.absent(),
    this.limitMinor = const Value.absent(),
    required String currency,
    required DataSource source,
    required DateTime writtenAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       date = Value(date),
       currentMinor = Value(currentMinor),
       currency = Value(currency),
       source = Value(source),
       writtenAt = Value(writtenAt);
  static Insertable<BalanceSnapshotRow> custom({
    Expression<String>? accountId,
    Expression<String>? date,
    Expression<int>? currentMinor,
    Expression<int>? availableMinor,
    Expression<int>? limitMinor,
    Expression<String>? currency,
    Expression<String>? source,
    Expression<int>? writtenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (date != null) 'date': date,
      if (currentMinor != null) 'current_minor': currentMinor,
      if (availableMinor != null) 'available_minor': availableMinor,
      if (limitMinor != null) 'limit_minor': limitMinor,
      if (currency != null) 'currency': currency,
      if (source != null) 'source': source,
      if (writtenAt != null) 'written_at': writtenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceSnapshotsCompanion copyWith({
    Value<String>? accountId,
    Value<LocalDate>? date,
    Value<int>? currentMinor,
    Value<int?>? availableMinor,
    Value<int?>? limitMinor,
    Value<String>? currency,
    Value<DataSource>? source,
    Value<DateTime>? writtenAt,
    Value<int>? rowid,
  }) {
    return BalanceSnapshotsCompanion(
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      currentMinor: currentMinor ?? this.currentMinor,
      availableMinor: availableMinor ?? this.availableMinor,
      limitMinor: limitMinor ?? this.limitMinor,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      writtenAt: writtenAt ?? this.writtenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $BalanceSnapshotsTable.$converterdate.toSql(date.value),
      );
    }
    if (currentMinor.present) {
      map['current_minor'] = Variable<int>(currentMinor.value);
    }
    if (availableMinor.present) {
      map['available_minor'] = Variable<int>(availableMinor.value);
    }
    if (limitMinor.present) {
      map['limit_minor'] = Variable<int>(limitMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $BalanceSnapshotsTable.$convertersource.toSql(source.value),
      );
    }
    if (writtenAt.present) {
      map['written_at'] = Variable<int>(
        $BalanceSnapshotsTable.$converterwrittenAt.toSql(writtenAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshotsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('date: $date, ')
          ..write('currentMinor: $currentMinor, ')
          ..write('availableMinor: $availableMinor, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMinorMeta = const VerificationMeta(
    'targetMinor',
  );
  @override
  late final GeneratedColumn<int> targetMinor = GeneratedColumn<int>(
    'target_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<GoalKind>($GoalsTable.$converterkind);
  static const VerificationMeta _linkedAccountIdsMeta = const VerificationMeta(
    'linkedAccountIds',
  );
  @override
  late final GeneratedColumn<String> linkedAccountIds = GeneratedColumn<String>(
    'linked_account_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String> targetDate =
      GeneratedColumn<String>(
        'target_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<LocalDate?>($GoalsTable.$convertertargetDaten);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> createdOn =
      GeneratedColumn<String>(
        'created_on',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($GoalsTable.$convertercreatedOn);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> archivedAt =
      GeneratedColumn<int>(
        'archived_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterarchivedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GoalsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GoalsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetMinor,
    currency,
    kind,
    linkedAccountIds,
    targetDate,
    createdOn,
    note,
    archivedAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_minor')) {
      context.handle(
        _targetMinorMeta,
        targetMinor.isAcceptableOrUnknown(
          data['target_minor']!,
          _targetMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('linked_account_ids')) {
      context.handle(
        _linkedAccountIdsMeta,
        linkedAccountIds.isAcceptableOrUnknown(
          data['linked_account_ids']!,
          _linkedAccountIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_linkedAccountIdsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      kind: $GoalsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      linkedAccountIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_ids'],
      )!,
      targetDate: $GoalsTable.$convertertargetDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_date'],
        ),
      ),
      createdOn: $GoalsTable.$convertercreatedOn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_on'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      archivedAt: $GoalsTable.$converterarchivedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}archived_at'],
        ),
      ),
      createdAt: $GoalsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $GoalsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $GoalsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalKind, String, String> $converterkind =
      const EnumNameConverter<GoalKind>(GoalKind.values);
  static TypeConverter<LocalDate, String> $convertertargetDate =
      const LocalDateColumnConverter();
  static TypeConverter<LocalDate?, String?> $convertertargetDaten =
      NullAwareTypeConverter.wrap($convertertargetDate);
  static TypeConverter<LocalDate, String> $convertercreatedOn =
      const LocalDateColumnConverter();
  static TypeConverter<DateTime, int> $converterarchivedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterarchivedAtn =
      NullAwareTypeConverter.wrap($converterarchivedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String name;
  final int targetMinor;
  final String currency;
  final GoalKind kind;
  final String linkedAccountIds;
  final LocalDate? targetDate;
  final LocalDate createdOn;
  final String? note;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const GoalRow({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.currency,
    required this.kind,
    required this.linkedAccountIds,
    this.targetDate,
    required this.createdOn,
    this.note,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_minor'] = Variable<int>(targetMinor);
    map['currency'] = Variable<String>(currency);
    {
      map['kind'] = Variable<String>($GoalsTable.$converterkind.toSql(kind));
    }
    map['linked_account_ids'] = Variable<String>(linkedAccountIds);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDaten.toSql(targetDate),
      );
    }
    {
      map['created_on'] = Variable<String>(
        $GoalsTable.$convertercreatedOn.toSql(createdOn),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(
        $GoalsTable.$converterarchivedAtn.toSql(archivedAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $GoalsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $GoalsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetMinor: Value(targetMinor),
      currency: Value(currency),
      kind: Value(kind),
      linkedAccountIds: Value(linkedAccountIds),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdOn: Value(createdOn),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetMinor: serializer.fromJson<int>(json['targetMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      kind: $GoalsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      linkedAccountIds: serializer.fromJson<String>(json['linkedAccountIds']),
      targetDate: serializer.fromJson<LocalDate?>(json['targetDate']),
      createdOn: serializer.fromJson<LocalDate>(json['createdOn']),
      note: serializer.fromJson<String?>(json['note']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetMinor': serializer.toJson<int>(targetMinor),
      'currency': serializer.toJson<String>(currency),
      'kind': serializer.toJson<String>(
        $GoalsTable.$converterkind.toJson(kind),
      ),
      'linkedAccountIds': serializer.toJson<String>(linkedAccountIds),
      'targetDate': serializer.toJson<LocalDate?>(targetDate),
      'createdOn': serializer.toJson<LocalDate>(createdOn),
      'note': serializer.toJson<String?>(note),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  GoalRow copyWith({
    String? id,
    String? name,
    int? targetMinor,
    String? currency,
    GoalKind? kind,
    String? linkedAccountIds,
    Value<LocalDate?> targetDate = const Value.absent(),
    LocalDate? createdOn,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => GoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    currency: currency ?? this.currency,
    kind: kind ?? this.kind,
    linkedAccountIds: linkedAccountIds ?? this.linkedAccountIds,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    createdOn: createdOn ?? this.createdOn,
    note: note.present ? note.value : this.note,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetMinor: data.targetMinor.present
          ? data.targetMinor.value
          : this.targetMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      kind: data.kind.present ? data.kind.value : this.kind,
      linkedAccountIds: data.linkedAccountIds.present
          ? data.linkedAccountIds.value
          : this.linkedAccountIds,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      note: data.note.present ? data.note.value : this.note,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('linkedAccountIds: $linkedAccountIds, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdOn: $createdOn, ')
          ..write('note: $note, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetMinor,
    currency,
    kind,
    linkedAccountIds,
    targetDate,
    createdOn,
    note,
    archivedAt,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetMinor == this.targetMinor &&
          other.currency == this.currency &&
          other.kind == this.kind &&
          other.linkedAccountIds == this.linkedAccountIds &&
          other.targetDate == this.targetDate &&
          other.createdOn == this.createdOn &&
          other.note == this.note &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> targetMinor;
  final Value<String> currency;
  final Value<GoalKind> kind;
  final Value<String> linkedAccountIds;
  final Value<LocalDate?> targetDate;
  final Value<LocalDate> createdOn;
  final Value<String?> note;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.kind = const Value.absent(),
    this.linkedAccountIds = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.note = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    required int targetMinor,
    required String currency,
    required GoalKind kind,
    required String linkedAccountIds,
    this.targetDate = const Value.absent(),
    required LocalDate createdOn,
    this.note = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetMinor = Value(targetMinor),
       currency = Value(currency),
       kind = Value(kind),
       linkedAccountIds = Value(linkedAccountIds),
       createdOn = Value(createdOn),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? targetMinor,
    Expression<String>? currency,
    Expression<String>? kind,
    Expression<String>? linkedAccountIds,
    Expression<String>? targetDate,
    Expression<String>? createdOn,
    Expression<String>? note,
    Expression<int>? archivedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetMinor != null) 'target_minor': targetMinor,
      if (currency != null) 'currency': currency,
      if (kind != null) 'kind': kind,
      if (linkedAccountIds != null) 'linked_account_ids': linkedAccountIds,
      if (targetDate != null) 'target_date': targetDate,
      if (createdOn != null) 'created_on': createdOn,
      if (note != null) 'note': note,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? targetMinor,
    Value<String>? currency,
    Value<GoalKind>? kind,
    Value<String>? linkedAccountIds,
    Value<LocalDate?>? targetDate,
    Value<LocalDate>? createdOn,
    Value<String?>? note,
    Value<DateTime?>? archivedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMinor: targetMinor ?? this.targetMinor,
      currency: currency ?? this.currency,
      kind: kind ?? this.kind,
      linkedAccountIds: linkedAccountIds ?? this.linkedAccountIds,
      targetDate: targetDate ?? this.targetDate,
      createdOn: createdOn ?? this.createdOn,
      note: note ?? this.note,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetMinor.present) {
      map['target_minor'] = Variable<int>(targetMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $GoalsTable.$converterkind.toSql(kind.value),
      );
    }
    if (linkedAccountIds.present) {
      map['linked_account_ids'] = Variable<String>(linkedAccountIds.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(
        $GoalsTable.$convertertargetDaten.toSql(targetDate.value),
      );
    }
    if (createdOn.present) {
      map['created_on'] = Variable<String>(
        $GoalsTable.$convertercreatedOn.toSql(createdOn.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(
        $GoalsTable.$converterarchivedAtn.toSql(archivedAt.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $GoalsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $GoalsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $GoalsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetMinor: $targetMinor, ')
          ..write('currency: $currency, ')
          ..write('kind: $kind, ')
          ..write('linkedAccountIds: $linkedAccountIds, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdOn: $createdOn, ')
          ..write('note: $note, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalContributionsTable extends GoalContributions
    with TableInfo<$GoalContributionsTable, GoalContributionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($GoalContributionsTable.$converterdate);
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GoalContributionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GoalContributionsTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GoalContributionsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    date,
    amountMinor,
    currency,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_contributions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalContributionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalContributionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalContributionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      date: $GoalContributionsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: $GoalContributionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $GoalContributionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      deletedAt: $GoalContributionsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $GoalContributionsTable createAlias(String alias) {
    return $GoalContributionsTable(attachedDatabase, alias);
  }

  static TypeConverter<LocalDate, String> $converterdate =
      const LocalDateColumnConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcMillisColumnConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class GoalContributionRow extends DataClass
    implements Insertable<GoalContributionRow> {
  final String id;
  final String goalId;
  final LocalDate date;
  final int amountMinor;
  final String currency;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const GoalContributionRow({
    required this.id,
    required this.goalId,
    required this.date,
    required this.amountMinor,
    required this.currency,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    {
      map['date'] = Variable<String>(
        $GoalContributionsTable.$converterdate.toSql(date),
      );
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['created_at'] = Variable<int>(
        $GoalContributionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $GoalContributionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $GoalContributionsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  GoalContributionsCompanion toCompanion(bool nullToAbsent) {
    return GoalContributionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      date: Value(date),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory GoalContributionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalContributionRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      date: serializer.fromJson<LocalDate>(json['date']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'date': serializer.toJson<LocalDate>(date),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  GoalContributionRow copyWith({
    String? id,
    String? goalId,
    LocalDate? date,
    int? amountMinor,
    String? currency,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => GoalContributionRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  GoalContributionRow copyWithCompanion(GoalContributionsCompanion data) {
    return GoalContributionRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    date,
    amountMinor,
    currency,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalContributionRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class GoalContributionsCompanion extends UpdateCompanion<GoalContributionRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<LocalDate> date;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const GoalContributionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalContributionsCompanion.insert({
    required String id,
    required String goalId,
    required LocalDate date,
    required int amountMinor,
    required String currency,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       date = Value(date),
       amountMinor = Value(amountMinor),
       currency = Value(currency),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GoalContributionRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? date,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalContributionsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<LocalDate>? date,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return GoalContributionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $GoalContributionsTable.$converterdate.toSql(date.value),
      );
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $GoalContributionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $GoalContributionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $GoalContributionsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalContributionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConflictsTable extends Conflicts
    with TableInfo<$ConflictsTable, ConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localValueMeta = const VerificationMeta(
    'localValue',
  );
  @override
  late final GeneratedColumn<String> localValue = GeneratedColumn<String>(
    'local_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localHlcMeta = const VerificationMeta(
    'localHlc',
  );
  @override
  late final GeneratedColumn<String> localHlc = GeneratedColumn<String>(
    'local_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteValueMeta = const VerificationMeta(
    'remoteValue',
  );
  @override
  late final GeneratedColumn<String> remoteValue = GeneratedColumn<String>(
    'remote_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteHlcMeta = const VerificationMeta(
    'remoteHlc',
  );
  @override
  late final GeneratedColumn<String> remoteHlc = GeneratedColumn<String>(
    'remote_hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityLabelMeta = const VerificationMeta(
    'entityLabel',
  );
  @override
  late final GeneratedColumn<String> entityLabel = GeneratedColumn<String>(
    'entity_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> seenAt =
      GeneratedColumn<int>(
        'seen_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ConflictsTable.$converterseenAt);
  @override
  List<GeneratedColumn> get $columns => [
    entityType,
    entityId,
    field,
    localValue,
    localHlc,
    remoteValue,
    remoteHlc,
    entityLabel,
    seenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('local_value')) {
      context.handle(
        _localValueMeta,
        localValue.isAcceptableOrUnknown(data['local_value']!, _localValueMeta),
      );
    } else if (isInserting) {
      context.missing(_localValueMeta);
    }
    if (data.containsKey('local_hlc')) {
      context.handle(
        _localHlcMeta,
        localHlc.isAcceptableOrUnknown(data['local_hlc']!, _localHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_localHlcMeta);
    }
    if (data.containsKey('remote_value')) {
      context.handle(
        _remoteValueMeta,
        remoteValue.isAcceptableOrUnknown(
          data['remote_value']!,
          _remoteValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteValueMeta);
    }
    if (data.containsKey('remote_hlc')) {
      context.handle(
        _remoteHlcMeta,
        remoteHlc.isAcceptableOrUnknown(data['remote_hlc']!, _remoteHlcMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteHlcMeta);
    }
    if (data.containsKey('entity_label')) {
      context.handle(
        _entityLabelMeta,
        entityLabel.isAcceptableOrUnknown(
          data['entity_label']!,
          _entityLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, entityId, field};
  @override
  ConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictRow(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      localValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_value'],
      )!,
      localHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_hlc'],
      )!,
      remoteValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_value'],
      )!,
      remoteHlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_hlc'],
      )!,
      entityLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_label'],
      ),
      seenAt: $ConflictsTable.$converterseenAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}seen_at'],
        )!,
      ),
    );
  }

  @override
  $ConflictsTable createAlias(String alias) {
    return $ConflictsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterseenAt =
      const UtcMillisColumnConverter();
}

class ConflictRow extends DataClass implements Insertable<ConflictRow> {
  final String entityType;
  final String entityId;
  final String field;
  final String localValue;
  final String localHlc;
  final String remoteValue;
  final String remoteHlc;
  final String? entityLabel;
  final DateTime seenAt;
  const ConflictRow({
    required this.entityType,
    required this.entityId,
    required this.field,
    required this.localValue,
    required this.localHlc,
    required this.remoteValue,
    required this.remoteHlc,
    this.entityLabel,
    required this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['field'] = Variable<String>(field);
    map['local_value'] = Variable<String>(localValue);
    map['local_hlc'] = Variable<String>(localHlc);
    map['remote_value'] = Variable<String>(remoteValue);
    map['remote_hlc'] = Variable<String>(remoteHlc);
    if (!nullToAbsent || entityLabel != null) {
      map['entity_label'] = Variable<String>(entityLabel);
    }
    {
      map['seen_at'] = Variable<int>(
        $ConflictsTable.$converterseenAt.toSql(seenAt),
      );
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      entityType: Value(entityType),
      entityId: Value(entityId),
      field: Value(field),
      localValue: Value(localValue),
      localHlc: Value(localHlc),
      remoteValue: Value(remoteValue),
      remoteHlc: Value(remoteHlc),
      entityLabel: entityLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(entityLabel),
      seenAt: Value(seenAt),
    );
  }

  factory ConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictRow(
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      field: serializer.fromJson<String>(json['field']),
      localValue: serializer.fromJson<String>(json['localValue']),
      localHlc: serializer.fromJson<String>(json['localHlc']),
      remoteValue: serializer.fromJson<String>(json['remoteValue']),
      remoteHlc: serializer.fromJson<String>(json['remoteHlc']),
      entityLabel: serializer.fromJson<String?>(json['entityLabel']),
      seenAt: serializer.fromJson<DateTime>(json['seenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'field': serializer.toJson<String>(field),
      'localValue': serializer.toJson<String>(localValue),
      'localHlc': serializer.toJson<String>(localHlc),
      'remoteValue': serializer.toJson<String>(remoteValue),
      'remoteHlc': serializer.toJson<String>(remoteHlc),
      'entityLabel': serializer.toJson<String?>(entityLabel),
      'seenAt': serializer.toJson<DateTime>(seenAt),
    };
  }

  ConflictRow copyWith({
    String? entityType,
    String? entityId,
    String? field,
    String? localValue,
    String? localHlc,
    String? remoteValue,
    String? remoteHlc,
    Value<String?> entityLabel = const Value.absent(),
    DateTime? seenAt,
  }) => ConflictRow(
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    field: field ?? this.field,
    localValue: localValue ?? this.localValue,
    localHlc: localHlc ?? this.localHlc,
    remoteValue: remoteValue ?? this.remoteValue,
    remoteHlc: remoteHlc ?? this.remoteHlc,
    entityLabel: entityLabel.present ? entityLabel.value : this.entityLabel,
    seenAt: seenAt ?? this.seenAt,
  );
  ConflictRow copyWithCompanion(ConflictsCompanion data) {
    return ConflictRow(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      field: data.field.present ? data.field.value : this.field,
      localValue: data.localValue.present
          ? data.localValue.value
          : this.localValue,
      localHlc: data.localHlc.present ? data.localHlc.value : this.localHlc,
      remoteValue: data.remoteValue.present
          ? data.remoteValue.value
          : this.remoteValue,
      remoteHlc: data.remoteHlc.present ? data.remoteHlc.value : this.remoteHlc,
      entityLabel: data.entityLabel.present
          ? data.entityLabel.value
          : this.entityLabel,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictRow(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('localValue: $localValue, ')
          ..write('localHlc: $localHlc, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('remoteHlc: $remoteHlc, ')
          ..write('entityLabel: $entityLabel, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entityType,
    entityId,
    field,
    localValue,
    localHlc,
    remoteValue,
    remoteHlc,
    entityLabel,
    seenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictRow &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.field == this.field &&
          other.localValue == this.localValue &&
          other.localHlc == this.localHlc &&
          other.remoteValue == this.remoteValue &&
          other.remoteHlc == this.remoteHlc &&
          other.entityLabel == this.entityLabel &&
          other.seenAt == this.seenAt);
}

class ConflictsCompanion extends UpdateCompanion<ConflictRow> {
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> field;
  final Value<String> localValue;
  final Value<String> localHlc;
  final Value<String> remoteValue;
  final Value<String> remoteHlc;
  final Value<String?> entityLabel;
  final Value<DateTime> seenAt;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.field = const Value.absent(),
    this.localValue = const Value.absent(),
    this.localHlc = const Value.absent(),
    this.remoteValue = const Value.absent(),
    this.remoteHlc = const Value.absent(),
    this.entityLabel = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String entityType,
    required String entityId,
    required String field,
    required String localValue,
    required String localHlc,
    required String remoteValue,
    required String remoteHlc,
    this.entityLabel = const Value.absent(),
    required DateTime seenAt,
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       field = Value(field),
       localValue = Value(localValue),
       localHlc = Value(localHlc),
       remoteValue = Value(remoteValue),
       remoteHlc = Value(remoteHlc),
       seenAt = Value(seenAt);
  static Insertable<ConflictRow> custom({
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? field,
    Expression<String>? localValue,
    Expression<String>? localHlc,
    Expression<String>? remoteValue,
    Expression<String>? remoteHlc,
    Expression<String>? entityLabel,
    Expression<int>? seenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (field != null) 'field': field,
      if (localValue != null) 'local_value': localValue,
      if (localHlc != null) 'local_hlc': localHlc,
      if (remoteValue != null) 'remote_value': remoteValue,
      if (remoteHlc != null) 'remote_hlc': remoteHlc,
      if (entityLabel != null) 'entity_label': entityLabel,
      if (seenAt != null) 'seen_at': seenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? field,
    Value<String>? localValue,
    Value<String>? localHlc,
    Value<String>? remoteValue,
    Value<String>? remoteHlc,
    Value<String?>? entityLabel,
    Value<DateTime>? seenAt,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      field: field ?? this.field,
      localValue: localValue ?? this.localValue,
      localHlc: localHlc ?? this.localHlc,
      remoteValue: remoteValue ?? this.remoteValue,
      remoteHlc: remoteHlc ?? this.remoteHlc,
      entityLabel: entityLabel ?? this.entityLabel,
      seenAt: seenAt ?? this.seenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (localValue.present) {
      map['local_value'] = Variable<String>(localValue.value);
    }
    if (localHlc.present) {
      map['local_hlc'] = Variable<String>(localHlc.value);
    }
    if (remoteValue.present) {
      map['remote_value'] = Variable<String>(remoteValue.value);
    }
    if (remoteHlc.present) {
      map['remote_hlc'] = Variable<String>(remoteHlc.value);
    }
    if (entityLabel.present) {
      map['entity_label'] = Variable<String>(entityLabel.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<int>(
        $ConflictsTable.$converterseenAt.toSql(seenAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('field: $field, ')
          ..write('localValue: $localValue, ')
          ..write('localHlc: $localHlc, ')
          ..write('remoteValue: $remoteValue, ')
          ..write('remoteHlc: $remoteHlc, ')
          ..write('entityLabel: $entityLabel, ')
          ..write('seenAt: $seenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionTagsTable transactionTags = $TransactionTagsTable(
    this,
  );
  late final $TransactionSplitsTable transactionSplits =
      $TransactionSplitsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $ChangeLogTable changeLog = $ChangeLogTable(this);
  late final $RecordClocksTable recordClocks = $RecordClocksTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $HeldRecordsTable heldRecords = $HeldRecordsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $RulesTable rules = $RulesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $BudgetAlertsTable budgetAlerts = $BudgetAlertsTable(this);
  late final $DismissedPairsTable dismissedPairs = $DismissedPairsTable(this);
  late final $SavedFiltersTable savedFilters = $SavedFiltersTable(this);
  late final $RecurringStreamsTable recurringStreams = $RecurringStreamsTable(
    this,
  );
  late final $StreamOverridesTable streamOverrides = $StreamOverridesTable(
    this,
  );
  late final $LiabilitiesTable liabilities = $LiabilitiesTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $BillAlertsTable billAlerts = $BillAlertsTable(this);
  late final $SecuritiesTable securities = $SecuritiesTable(this);
  late final $HoldingsTable holdings = $HoldingsTable(this);
  late final $InvestmentTransactionsTable investmentTransactions =
      $InvestmentTransactionsTable(this);
  late final $BalanceSnapshotsTable balanceSnapshots = $BalanceSnapshotsTable(
    this,
  );
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalContributionsTable goalContributions =
      $GoalContributionsTable(this);
  late final $ConflictsTable conflicts = $ConflictsTable(this);
  late final Index transactionsAccountDate = Index(
    'transactions_account_date',
    'CREATE INDEX transactions_account_date ON transactions (account_id, date)',
  );
  late final Index transactionsUserCategory = Index(
    'transactions_user_category',
    'CREATE INDEX transactions_user_category ON transactions (user_category_id)',
  );
  late final Index transactionsPendingTransaction = Index(
    'transactions_pending_transaction',
    'CREATE INDEX transactions_pending_transaction ON transactions (pending_transaction_id)',
  );
  late final Index transactionTagsTag = Index(
    'transaction_tags_tag',
    'CREATE INDEX transaction_tags_tag ON transaction_tags (tag)',
  );
  late final Index categoriesParent = Index(
    'categories_parent',
    'CREATE INDEX categories_parent ON categories (parent_id)',
  );
  late final Index changeLogOutbox = Index(
    'change_log_outbox',
    'CREATE INDEX change_log_outbox ON change_log (synced, rejected_reason, hlc)',
  );
  late final Index recordClocksHlc = Index(
    'record_clocks_hlc',
    'CREATE INDEX record_clocks_hlc ON record_clocks (hlc)',
  );
  late final Index rulesPosition = Index(
    'rules_position',
    'CREATE INDEX rules_position ON rules (position)',
  );
  late final Index budgetsCategory = Index(
    'budgets_category',
    'CREATE INDEX budgets_category ON budgets (category_id)',
  );
  late final Index savedFiltersPosition = Index(
    'saved_filters_position',
    'CREATE INDEX saved_filters_position ON saved_filters (position)',
  );
  late final Index recurringStreamsAccount = Index(
    'recurring_streams_account',
    'CREATE INDEX recurring_streams_account ON recurring_streams (account_id)',
  );
  late final Index billsDueDate = Index(
    'bills_due_date',
    'CREATE INDEX bills_due_date ON bills (due_date)',
  );
  late final Index investmentTransactionsAccountDate = Index(
    'investment_transactions_account_date',
    'CREATE INDEX investment_transactions_account_date ON investment_transactions (account_id, date)',
  );
  late final Index balanceSnapshotsDate = Index(
    'balance_snapshots_date',
    'CREATE INDEX balance_snapshots_date ON balance_snapshots (date)',
  );
  late final Index goalContributionsGoal = Index(
    'goal_contributions_goal',
    'CREATE INDEX goal_contributions_goal ON goal_contributions (goal_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    transactions,
    transactionTags,
    transactionSplits,
    categories,
    appSettings,
    appMeta,
    changeLog,
    recordClocks,
    syncMeta,
    heldRecords,
    items,
    rules,
    budgets,
    budgetAlerts,
    dismissedPairs,
    savedFilters,
    recurringStreams,
    streamOverrides,
    liabilities,
    bills,
    billAlerts,
    securities,
    holdings,
    investmentTransactions,
    balanceSnapshots,
    goals,
    goalContributions,
    conflicts,
    transactionsAccountDate,
    transactionsUserCategory,
    transactionsPendingTransaction,
    transactionTagsTag,
    categoriesParent,
    changeLogOutbox,
    recordClocksHlc,
    rulesPosition,
    budgetsCategory,
    savedFiltersPosition,
    recurringStreamsAccount,
    billsDueDate,
    investmentTransactionsAccountDate,
    balanceSnapshotsDate,
    goalContributionsGoal,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'transactions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('transaction_splits', kind: UpdateKind.delete)],
    ),
  ]);
}
