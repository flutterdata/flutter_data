// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// AdapterGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$BookAuthorAdapter on Adapter<BookAuthor> {
  static final Map<String, RelationshipMeta> _kBookAuthorRelationshipMetas = {
    'books': RelationshipMeta<Book>(
      name: 'books',
      inverseName: 'originalAuthor',
      type: 'books',
      kind: 'HasMany',
      instance: (_) => (_ as BookAuthor).books,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kBookAuthorRelationshipMetas;

  @override
  BookAuthor deserializeLocal(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => BookAuthor.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serializeLocal(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _bookAuthorsFinders = <String, dynamic>{
  'caps': (_) => _.caps,
};

class $BookAuthorAdapter = Adapter<BookAuthor>
    with _$BookAuthorAdapter, BookAuthorAdapter;

final bookAuthorsAdapterProvider = Provider<Adapter<BookAuthor>>(
    (ref) => $BookAuthorAdapter(ref, InternalHolder(_bookAuthorsFinders)));

extension BookAuthorAdapterX on Adapter<BookAuthor> {
  BookAuthorAdapter get bookAuthorAdapter => this as BookAuthorAdapter;
}

extension BookAuthorRelationshipGraphNodeX
    on RelationshipGraphNode<BookAuthor> {
  RelationshipGraphNode<Book> get books {
    final meta = _$BookAuthorAdapter._kBookAuthorRelationshipMetas['books']
        as RelationshipMeta<Book>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$BookAdapter on Adapter<Book> {
  static final Map<String, RelationshipMeta> _kBookRelationshipMetas = {
    'original_author_id': RelationshipMeta<BookAuthor>(
      name: 'originalAuthor',
      inverseName: 'books',
      type: 'bookAuthors',
      kind: 'BelongsTo',
      instance: (_) => (_ as Book).originalAuthor,
    ),
    'house': RelationshipMeta<House>(
      name: 'house',
      inverseName: 'currentLibrary',
      type: 'houses',
      kind: 'BelongsTo',
      instance: (_) => (_ as Book).house,
    ),
    'ardent_supporters': RelationshipMeta<Person>(
      name: 'ardentSupporters',
      type: 'people',
      kind: 'HasMany',
      instance: (_) => (_ as Book).ardentSupporters,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kBookRelationshipMetas;

  @override
  Book deserializeLocal(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Book.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serializeLocal(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _booksFinders = <String, dynamic>{};

class $BookAdapter = Adapter<Book> with _$BookAdapter, NothingMixin;

final booksAdapterProvider = Provider<Adapter<Book>>(
    (ref) => $BookAdapter(ref, InternalHolder(_booksFinders)));

extension BookAdapterX on Adapter<Book> {}

extension BookRelationshipGraphNodeX on RelationshipGraphNode<Book> {
  RelationshipGraphNode<BookAuthor> get originalAuthor {
    final meta = _$BookAdapter._kBookRelationshipMetas['original_author_id']
        as RelationshipMeta<BookAuthor>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<House> get house {
    final meta = _$BookAdapter._kBookRelationshipMetas['house']
        as RelationshipMeta<House>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Person> get ardentSupporters {
    final meta = _$BookAdapter._kBookRelationshipMetas['ardent_supporters']
        as RelationshipMeta<Person>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$LibraryAdapter on Adapter<Library> {
  static final Map<String, RelationshipMeta> _kLibraryRelationshipMetas = {
    'books': RelationshipMeta<Book>(
      name: 'books',
      type: 'books',
      kind: 'HasMany',
      instance: (_) => (_ as Library).books,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kLibraryRelationshipMetas;

  @override
  Library deserializeLocal(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Library.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serializeLocal(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _librariesFinders = <String, dynamic>{};

class $LibraryAdapter = Adapter<Library> with _$LibraryAdapter, NothingMixin;

final librariesAdapterProvider = Provider<Adapter<Library>>(
    (ref) => $LibraryAdapter(ref, InternalHolder(_librariesFinders)));

extension LibraryAdapterX on Adapter<Library> {}

extension LibraryRelationshipGraphNodeX on RelationshipGraphNode<Library> {
  RelationshipGraphNode<Book> get books {
    final meta = _$LibraryAdapter._kLibraryRelationshipMetas['books']
        as RelationshipMeta<Book>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookAuthorImpl _$$BookAuthorImplFromJson(Map<String, dynamic> json) =>
    _$BookAuthorImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      books: HasMany<Book>.fromJson(json['books'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$BookAuthorImplToJson(_$BookAuthorImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'books': instance.books,
    };

_$BookImpl _$$BookImplFromJson(Map<String, dynamic> json) => _$BookImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      numberOfSales: (json['number_of_sales'] as num?)?.toInt() ?? 0,
      originalAuthor: json['original_author_id'] == null
          ? null
          : BelongsTo<BookAuthor>.fromJson(
              json['original_author_id'] as Map<String, dynamic>),
      house: json['house'] == null
          ? null
          : BelongsTo<House>.fromJson(json['house'] as Map<String, dynamic>),
      ardentSupporters: HasMany<Person>.fromJson(
          json['ardent_supporters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$BookImplToJson(_$BookImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('title', instance.title);
  val['number_of_sales'] = instance.numberOfSales;
  writeNotNull('original_author_id', instance.originalAuthor);
  writeNotNull('house', instance.house);
  val['ardent_supporters'] = instance.ardentSupporters;
  return val;
}

_$LibraryImpl _$$LibraryImplFromJson(Map<String, dynamic> json) =>
    _$LibraryImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      books: HasMany<Book>.fromJson(json['books'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LibraryImplToJson(_$LibraryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'books': instance.books,
    };
