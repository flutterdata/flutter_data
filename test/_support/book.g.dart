// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$BookAuthorLocalAdapter on LocalAdapter<BookAuthor> {
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
  BookAuthor deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => BookAuthor.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _bookAuthorsFinders = <String, dynamic>{
  'caps': (_) => _.caps,
};

// ignore: must_be_immutable
class $BookAuthorLocalAdapter = LocalAdapter<BookAuthor>
    with _$BookAuthorLocalAdapter;

class $BookAuthorRemoteAdapter = RemoteAdapter<BookAuthor>
    with BookAuthorAdapter;

final internalBookAuthorsRemoteAdapterProvider =
    Provider<RemoteAdapter<BookAuthor>>((ref) => $BookAuthorRemoteAdapter(
        $BookAuthorLocalAdapter(ref), InternalHolder(_bookAuthorsFinders)));

final bookAuthorsRepositoryProvider =
    Provider<Repository<BookAuthor>>((ref) => Repository<BookAuthor>(ref));

extension BookAuthorDataRepositoryX on Repository<BookAuthor> {
  BookAuthorAdapter get bookAuthorAdapter => remoteAdapter as BookAuthorAdapter;
}

extension BookAuthorRelationshipGraphNodeX
    on RelationshipGraphNode<BookAuthor> {
  RelationshipGraphNode<Book> get books {
    final meta = _$BookAuthorLocalAdapter._kBookAuthorRelationshipMetas['books']
        as RelationshipMeta<Book>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$BookLocalAdapter on LocalAdapter<Book> {
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
  Book deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Book.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _booksFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $BookLocalAdapter = LocalAdapter<Book> with _$BookLocalAdapter;

class $BookRemoteAdapter = RemoteAdapter<Book> with NothingMixin;

final internalBooksRemoteAdapterProvider = Provider<RemoteAdapter<Book>>(
    (ref) => $BookRemoteAdapter(
        $BookLocalAdapter(ref), InternalHolder(_booksFinders)));

final booksRepositoryProvider =
    Provider<Repository<Book>>((ref) => Repository<Book>(ref));

extension BookDataRepositoryX on Repository<Book> {}

extension BookRelationshipGraphNodeX on RelationshipGraphNode<Book> {
  RelationshipGraphNode<BookAuthor> get originalAuthor {
    final meta =
        _$BookLocalAdapter._kBookRelationshipMetas['original_author_id']
            as RelationshipMeta<BookAuthor>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<House> get house {
    final meta = _$BookLocalAdapter._kBookRelationshipMetas['house']
        as RelationshipMeta<House>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Person> get ardentSupporters {
    final meta = _$BookLocalAdapter._kBookRelationshipMetas['ardent_supporters']
        as RelationshipMeta<Person>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$LibraryLocalAdapter on LocalAdapter<Library> {
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
  Library deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Library.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _librariesFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $LibraryLocalAdapter = LocalAdapter<Library> with _$LibraryLocalAdapter;

class $LibraryRemoteAdapter = RemoteAdapter<Library> with NothingMixin;

final internalLibrariesRemoteAdapterProvider = Provider<RemoteAdapter<Library>>(
    (ref) => $LibraryRemoteAdapter(
        $LibraryLocalAdapter(ref), InternalHolder(_librariesFinders)));

final librariesRepositoryProvider =
    Provider<Repository<Library>>((ref) => Repository<Library>(ref));

extension LibraryDataRepositoryX on Repository<Library> {}

extension LibraryRelationshipGraphNodeX on RelationshipGraphNode<Library> {
  RelationshipGraphNode<Book> get books {
    final meta = _$LibraryLocalAdapter._kLibraryRelationshipMetas['books']
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
      id: json['id'] as int,
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
      id: json['id'] as int,
      title: json['title'] as String?,
      numberOfSales: json['number_of_sales'] as int? ?? 0,
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
      id: json['id'] as int,
      name: json['name'] as String,
      books: HasMany<Book>.fromJson(json['books'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LibraryImplToJson(_$LibraryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'books': instance.books,
    };
