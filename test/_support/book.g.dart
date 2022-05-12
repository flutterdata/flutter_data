// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $BookAuthorLocalAdapter on LocalAdapter<BookAuthor> {
  static final rdata = RelationshipData<BookAuthor>({
    'books': RelationshipDataItem<BookAuthor>(
      name: 'books',
      inverseName: 'originalAuthor',
      type: 'books',
      kind: 'HasMany',
      instance: (_) => _.books,
    )
  });

  @override
  RelationshipData<BookAuthor> get relationshipData => rdata;

  @override
  BookAuthor deserialize(map) {
    map = transformDeserialize(map);
    return BookAuthor.fromJson(map);
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
class $BookAuthorHiveLocalAdapter = HiveLocalAdapter<BookAuthor>
    with $BookAuthorLocalAdapter;

class $BookAuthorRemoteAdapter = RemoteAdapter<BookAuthor>
    with BookAuthorAdapter;

final internalBookAuthorsRemoteAdapterProvider =
    Provider<RemoteAdapter<BookAuthor>>((ref) => $BookAuthorRemoteAdapter(
        $BookAuthorHiveLocalAdapter(ref.read),
        InternalHolder(_bookAuthorsFinders)));

final bookAuthorsRepositoryProvider =
    Provider<Repository<BookAuthor>>((ref) => Repository<BookAuthor>(ref.read));

extension BookAuthorDataRepositoryX on Repository<BookAuthor> {
  BookAuthorAdapter get bookAuthorAdapter => remoteAdapter as BookAuthorAdapter;
}

extension BookAuthorRelationshipDataX on RelationshipData<BookAuthor> {
  RelationshipDataItem<BookAuthor> get books => items['books']!;
}

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $BookLocalAdapter on LocalAdapter<Book> {
  static final rdata = RelationshipData<Book>({
    'original_author_id': RelationshipDataItem<Book>(
      name: 'originalAuthor',
      inverseName: 'books',
      type: 'bookAuthors',
      kind: 'BelongsTo',
      instance: (_) => _.originalAuthor,
    ),
    'house': RelationshipDataItem<Book>(
      name: 'house',
      inverseName: 'currentLibrary',
      type: 'houses',
      kind: 'BelongsTo',
      instance: (_) => _.house,
    ),
    'ardent_supporters': RelationshipDataItem<Book>(
      name: 'ardentSupporters',
      type: 'people',
      kind: 'HasMany',
      instance: (_) => _.ardentSupporters,
    )
  });

  @override
  RelationshipData<Book> get relationshipData => rdata;

  @override
  Book deserialize(map) {
    map = transformDeserialize(map);
    return Book.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _booksFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $BookHiveLocalAdapter = HiveLocalAdapter<Book> with $BookLocalAdapter;

class $BookRemoteAdapter = RemoteAdapter<Book> with NothingMixin;

final internalBooksRemoteAdapterProvider = Provider<RemoteAdapter<Book>>(
    (ref) => $BookRemoteAdapter(
        $BookHiveLocalAdapter(ref.read), InternalHolder(_booksFinders)));

final booksRepositoryProvider =
    Provider<Repository<Book>>((ref) => Repository<Book>(ref.read));

extension BookDataRepositoryX on Repository<Book> {}

extension BookRelationshipDataX on RelationshipData<Book> {
  RelationshipDataItem<Book> get originalAuthor => items['original_author_id']!;
  RelationshipDataItem<Book> get house => items['house']!;
  RelationshipDataItem<Book> get ardentSupporters =>
      items['ardent_supporters']!;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BookAuthor _$$_BookAuthorFromJson(Map<String, dynamic> json) =>
    _$_BookAuthor(
      id: json['id'] as int,
      name: json['name'] as String?,
      books: HasMany<Book>.fromJson(json['books'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_BookAuthorToJson(_$_BookAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'books': instance.books,
    };

_$_Book _$$_BookFromJson(Map<String, dynamic> json) => _$_Book(
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

Map<String, dynamic> _$$_BookToJson(_$_Book instance) {
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
