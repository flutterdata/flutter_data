// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'id_mapping.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetInternalIdCollection on Isar {
  IsarCollection<int, IdMapping> get idMappings => this.collection();
}

const InternalIdSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'InternalId',
    idName: 'isarId',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'key',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'id',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'isInt',
        type: IsarType.bool,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'id',
        properties: [
          "id",
        ],
        unique: false,
        hash: false,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, IdMapping>(
    serialize: serializeInternalId,
    deserialize: deserializeInternalId,
    deserializeProperty: deserializeInternalIdProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeInternalId(IsarWriter writer, IdMapping object) {
  IsarCore.writeString(writer, 1, object.key);
  IsarCore.writeString(writer, 2, object.id);
  IsarCore.writeBool(writer, 3, object.isInt);
  return object.isarId;
}

@isarProtected
IdMapping deserializeInternalId(IsarReader reader) {
  final String _key;
  _key = IsarCore.readString(reader, 1) ?? '';
  final String _id;
  _id = IsarCore.readString(reader, 2) ?? '';
  final bool _isInt;
  _isInt = IsarCore.readBool(reader, 3);
  final object = IdMapping(
    key: _key,
    id: _id,
    isInt: _isInt,
  );
  return object;
}

@isarProtected
dynamic deserializeInternalIdProp(IsarReader reader, int property) {
  switch (property) {
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readBool(reader, 3);
    case 0:
      return IsarCore.readId(reader);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _InternalIdUpdate {
  bool call({
    required int isarId,
    String? key,
    String? id,
    bool? isInt,
  });
}

class _InternalIdUpdateImpl implements _InternalIdUpdate {
  const _InternalIdUpdateImpl(this.collection);

  final IsarCollection<int, IdMapping> collection;

  @override
  bool call({
    required int isarId,
    Object? key = ignore,
    Object? id = ignore,
    Object? isInt = ignore,
  }) {
    return collection.updateProperties([
          isarId
        ], {
          if (key != ignore) 1: key as String?,
          if (id != ignore) 2: id as String?,
          if (isInt != ignore) 3: isInt as bool?,
        }) >
        0;
  }
}

sealed class _InternalIdUpdateAll {
  int call({
    required List<int> isarId,
    String? key,
    String? id,
    bool? isInt,
  });
}

class _InternalIdUpdateAllImpl implements _InternalIdUpdateAll {
  const _InternalIdUpdateAllImpl(this.collection);

  final IsarCollection<int, IdMapping> collection;

  @override
  int call({
    required List<int> isarId,
    Object? key = ignore,
    Object? id = ignore,
    Object? isInt = ignore,
  }) {
    return collection.updateProperties(isarId, {
      if (key != ignore) 1: key as String?,
      if (id != ignore) 2: id as String?,
      if (isInt != ignore) 3: isInt as bool?,
    });
  }
}

extension InternalIdUpdate on IsarCollection<int, IdMapping> {
  _InternalIdUpdate get update => _InternalIdUpdateImpl(this);

  _InternalIdUpdateAll get updateAll => _InternalIdUpdateAllImpl(this);
}

sealed class _InternalIdQueryUpdate {
  int call({
    String? key,
    String? id,
    bool? isInt,
  });
}

class _InternalIdQueryUpdateImpl implements _InternalIdQueryUpdate {
  const _InternalIdQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<IdMapping> query;
  final int? limit;

  @override
  int call({
    Object? key = ignore,
    Object? id = ignore,
    Object? isInt = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (key != ignore) 1: key as String?,
      if (id != ignore) 2: id as String?,
      if (isInt != ignore) 3: isInt as bool?,
    });
  }
}

extension InternalIdQueryUpdate on IsarQuery<IdMapping> {
  _InternalIdQueryUpdate get updateFirst =>
      _InternalIdQueryUpdateImpl(this, limit: 1);

  _InternalIdQueryUpdate get updateAll => _InternalIdQueryUpdateImpl(this);
}

class _InternalIdQueryBuilderUpdateImpl implements _InternalIdQueryUpdate {
  const _InternalIdQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<IdMapping, IdMapping, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? key = ignore,
    Object? id = ignore,
    Object? isInt = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (key != ignore) 1: key as String?,
        if (id != ignore) 2: id as String?,
        if (isInt != ignore) 3: isInt as bool?,
      });
    } finally {
      q.close();
    }
  }
}

extension InternalIdQueryBuilderUpdate
    on QueryBuilder<IdMapping, IdMapping, QOperations> {
  _InternalIdQueryUpdate get updateFirst =>
      _InternalIdQueryBuilderUpdateImpl(this, limit: 1);

  _InternalIdQueryUpdate get updateAll =>
      _InternalIdQueryBuilderUpdateImpl(this);
}

extension InternalIdQueryFilter
    on QueryBuilder<IdMapping, IdMapping, QFilterCondition> {
  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyEqualTo(
    String value, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyGreaterThan(
    String value, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition>
      keyGreaterThanOrEqualTo(
    String value, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyLessThan(
    String value, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition>
      keyLessThanOrEqualTo(
    String value, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyStartsWith(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyEndsWith(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyContains(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyMatches(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition>
      idGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> isIntEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> isarIdEqualTo(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> isarIdGreaterThan(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition>
      isarIdGreaterThanOrEqualTo(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> isarIdLessThan(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition>
      isarIdLessThanOrEqualTo(
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

  QueryBuilder<IdMapping, IdMapping, QAfterFilterCondition> isarIdBetween(
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
}

extension InternalIdQueryObject
    on QueryBuilder<IdMapping, IdMapping, QFilterCondition> {}

extension InternalIdQuerySortBy on QueryBuilder<IdMapping, IdMapping, QSortBy> {
  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByIsInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByIsIntDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> sortByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension InternalIdQuerySortThenBy
    on QueryBuilder<IdMapping, IdMapping, QSortThenBy> {
  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByIdDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByIsInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByIsIntDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }
}

extension InternalIdQueryWhereDistinct
    on QueryBuilder<IdMapping, IdMapping, QDistinct> {
  QueryBuilder<IdMapping, IdMapping, QAfterDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdMapping, IdMapping, QAfterDistinct> distinctByIsInt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }
}

extension InternalIdQueryProperty1
    on QueryBuilder<IdMapping, IdMapping, QProperty> {
  QueryBuilder<IdMapping, String, QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<IdMapping, String, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<IdMapping, bool, QAfterProperty> isIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<IdMapping, int, QAfterProperty> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension InternalIdQueryProperty2<R>
    on QueryBuilder<IdMapping, R, QAfterProperty> {
  QueryBuilder<IdMapping, (R, String), QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<IdMapping, (R, String), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<IdMapping, (R, bool), QAfterProperty> isIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<IdMapping, (R, int), QAfterProperty> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}

extension InternalIdQueryProperty3<R1, R2>
    on QueryBuilder<IdMapping, (R1, R2), QAfterProperty> {
  QueryBuilder<IdMapping, (R1, R2, String), QOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<IdMapping, (R1, R2, String), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<IdMapping, (R1, R2, bool), QOperations> isIntProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<IdMapping, (R1, R2, int), QOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }
}
