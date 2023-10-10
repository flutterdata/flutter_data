// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_model.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetStoredModelCollection on Isar {
  IsarCollection<int, StoredModel> get storedModels => this.collection();
}

const StoredModelSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'StoredModel',
    idName: 'key',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'isIdInt',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'type',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'data',
        type: IsarType.byteList,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'id_type',
        properties: [
          "id",
          "type",
        ],
        unique: false,
        hash: true,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, StoredModel>(
    serialize: serializeStoredModel,
    deserialize: deserializeStoredModel,
    deserializeProperty: deserializeStoredModelProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeStoredModel(IsarWriter writer, StoredModel object) {
  {
    final value = object.id;
    if (value == null) {
      IsarCore.writeNull(writer, 1);
    } else {
      IsarCore.writeString(writer, 1, value);
    }
  }
  IsarCore.writeBool(writer, 2, object.isIdInt);
  IsarCore.writeString(writer, 3, object.type);
  {
    final list = object.data;
    if (list == null) {
      IsarCore.writeNull(writer, 4);
    } else {
      final listWriter = IsarCore.beginList(writer, 4, list.length);
      for (var i = 0; i < list.length; i++) {
        IsarCore.writeByte(listWriter, i, list[i]);
      }
      IsarCore.endList(writer, listWriter);
    }
  }
  return object.key;
}

@isarProtected
StoredModel deserializeStoredModel(IsarReader reader) {
  final int _key;
  _key = IsarCore.readId(reader);
  final String? _id;
  _id = IsarCore.readString(reader, 1);
  final bool _isIdInt;
  _isIdInt = IsarCore.readBool(reader, 2);
  final String _type;
  _type = IsarCore.readString(reader, 3) ?? '';
  final List<int>? _data;
  {
    final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
    {
      final reader = IsarCore.readerPtr;
      if (reader.isNull) {
        _data = null;
      } else {
        final list = List<int>.filled(length, 0, growable: true);
        for (var i = 0; i < length; i++) {
          list[i] = IsarCore.readByte(reader, i);
        }
        IsarCore.freeReader(reader);
        _data = list;
      }
    }
  }
  final object = StoredModel(
    key: _key,
    id: _id,
    isIdInt: _isIdInt,
    type: _type,
    data: _data,
  );
  return object;
}

@isarProtected
dynamic deserializeStoredModelProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1);
    case 2:
      return IsarCore.readBool(reader, 2);
    case 3:
      return IsarCore.readString(reader, 3) ?? '';
    case 4:
      {
        final length = IsarCore.readList(reader, 4, IsarCore.readerPtrPtr);
        {
          final reader = IsarCore.readerPtr;
          if (reader.isNull) {
            return null;
          } else {
            final list = List<int>.filled(length, 0, growable: true);
            for (var i = 0; i < length; i++) {
              list[i] = IsarCore.readByte(reader, i);
            }
            IsarCore.freeReader(reader);
            return list;
          }
        }
      }
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _StoredModelUpdate {
  bool call({
    required int key,
    String? id,
    bool? isIdInt,
    String? type,
  });
}

class _StoredModelUpdateImpl implements _StoredModelUpdate {
  const _StoredModelUpdateImpl(this.collection);

  final IsarCollection<int, StoredModel> collection;

  @override
  bool call({
    required int key,
    Object? id = ignore,
    Object? isIdInt = ignore,
    Object? type = ignore,
  }) {
    return collection.updateProperties([
          key
        ], {
          if (id != ignore) 1: id as String?,
          if (isIdInt != ignore) 2: isIdInt as bool?,
          if (type != ignore) 3: type as String?,
        }) >
        0;
  }
}

sealed class _StoredModelUpdateAll {
  int call({
    required List<int> key,
    String? id,
    bool? isIdInt,
    String? type,
  });
}

class _StoredModelUpdateAllImpl implements _StoredModelUpdateAll {
  const _StoredModelUpdateAllImpl(this.collection);

  final IsarCollection<int, StoredModel> collection;

  @override
  int call({
    required List<int> key,
    Object? id = ignore,
    Object? isIdInt = ignore,
    Object? type = ignore,
  }) {
    return collection.updateProperties(key, {
      if (id != ignore) 1: id as String?,
      if (isIdInt != ignore) 2: isIdInt as bool?,
      if (type != ignore) 3: type as String?,
    });
  }
}

extension StoredModelUpdate on IsarCollection<int, StoredModel> {
  _StoredModelUpdate get update => _StoredModelUpdateImpl(this);

  _StoredModelUpdateAll get updateAll => _StoredModelUpdateAllImpl(this);
}

sealed class _StoredModelQueryUpdate {
  int call({
    String? id,
    bool? isIdInt,
    String? type,
  });
}

class _StoredModelQueryUpdateImpl implements _StoredModelQueryUpdate {
  const _StoredModelQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<StoredModel> query;
  final int? limit;

  @override
  int call({
    Object? id = ignore,
    Object? isIdInt = ignore,
    Object? type = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (id != ignore) 1: id as String?,
      if (isIdInt != ignore) 2: isIdInt as bool?,
      if (type != ignore) 3: type as String?,
    });
  }
}

extension StoredModelQueryUpdate on IsarQuery<StoredModel> {
  _StoredModelQueryUpdate get updateFirst =>
      _StoredModelQueryUpdateImpl(this, limit: 1);

  _StoredModelQueryUpdate get updateAll => _StoredModelQueryUpdateImpl(this);
}

class _StoredModelQueryBuilderUpdateImpl implements _StoredModelQueryUpdate {
  const _StoredModelQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<StoredModel, StoredModel, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? id = ignore,
    Object? isIdInt = ignore,
    Object? type = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (id != ignore) 1: id as String?,
        if (isIdInt != ignore) 2: isIdInt as bool?,
        if (type != ignore) 3: type as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension StoredModelQueryBuilderUpdate
    on QueryBuilder<StoredModel, StoredModel, QOperations> {
  _StoredModelQueryUpdate get updateFirst =>
      _StoredModelQueryBuilderUpdateImpl(this, limit: 1);

  _StoredModelQueryUpdate get updateAll =>
      _StoredModelQueryBuilderUpdateImpl(this);
}

extension StoredModelQueryFilter
    on QueryBuilder<StoredModel, StoredModel, QFilterCondition> {
  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> keyEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> keyGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      keyGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> keyLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      keyLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> keyBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      idLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> isIdIntEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      typeGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      typeLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 3,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 3,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 3,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> dataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 4));
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataElementBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 4,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition> dataIsEmpty() {
    return not().group(
      (q) => q.dataIsNull().or().dataIsNotEmpty(),
    );
  }

  QueryBuilder<StoredModel, StoredModel, QAfterFilterCondition>
      dataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterOrEqualCondition(property: 4, value: null),
      );
    });
  }
}

extension StoredModelQueryObject
    on QueryBuilder<StoredModel, StoredModel, QFilterCondition> {}

extension StoredModelQuerySortBy
    on QueryBuilder<StoredModel, StoredModel, QSortBy> {
  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByIsIdInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByIsIdIntDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> sortByTypeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        3,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension StoredModelQuerySortThenBy
    on QueryBuilder<StoredModel, StoredModel, QSortThenBy> {
  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByIsIdInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByIsIdIntDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterSortBy> thenByTypeDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension StoredModelQueryWhereDistinct
    on QueryBuilder<StoredModel, StoredModel, QDistinct> {
  QueryBuilder<StoredModel, StoredModel, QAfterDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterDistinct> distinctByIsIdInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StoredModel, StoredModel, QAfterDistinct> distinctByData() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }
}

extension StoredModelQueryProperty1
    on QueryBuilder<StoredModel, StoredModel, QProperty> {
  QueryBuilder<StoredModel, int, QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StoredModel, String?, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredModel, bool, QAfterProperty> isIdIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredModel, String, QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredModel, List<int>?, QAfterProperty> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension StoredModelQueryProperty2<R>
    on QueryBuilder<StoredModel, R, QAfterProperty> {
  QueryBuilder<StoredModel, (R, int), QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StoredModel, (R, String?), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredModel, (R, bool), QAfterProperty> isIdIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredModel, (R, String), QAfterProperty> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredModel, (R, List<int>?), QAfterProperty> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}

extension StoredModelQueryProperty3<R1, R2>
    on QueryBuilder<StoredModel, (R1, R2), QAfterProperty> {
  QueryBuilder<StoredModel, (R1, R2, int), QOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<StoredModel, (R1, R2, String?), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<StoredModel, (R1, R2, bool), QOperations> isIdIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<StoredModel, (R1, R2, String), QOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<StoredModel, (R1, R2, List<int>?), QOperations> dataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }
}
