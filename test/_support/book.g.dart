// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_BookAuthor _$$_BookAuthorFromJson(Map<String, dynamic> json) =>
    _$_BookAuthor(
      id: json['id'] as int,
      name: json['name'] as String?,
      books: json['books'] == null
          ? null
          : HasMany<Book>.fromJson(json['books'] as Map<String, dynamic>),
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
      originalAuthor: json['original_author'] == null
          ? null
          : BelongsTo<BookAuthor>.fromJson(
              json['original_author'] as Map<String, dynamic>),
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
  writeNotNull('original_author', instance.originalAuthor);
  return val;
}

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $BookAuthorLocalAdapter on LocalAdapter<BookAuthor> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([BookAuthor? model]) => {
        'books': {
          'name': 'books',
          'inverse': 'originalAuthor',
          'type': 'books',
          'kind': 'HasMany',
          'instance': model?.books
        }
      };

  @override
  BookAuthor deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return BookAuthor.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $BookAuthorHiveLocalAdapter = HiveLocalAdapter<BookAuthor>
    with $BookAuthorLocalAdapter;

class $BookAuthorRemoteAdapter = RemoteAdapter<BookAuthor>
    with BookAuthorAdapter;

//

final bookAuthorsLocalAdapterProvider = Provider<LocalAdapter<BookAuthor>>(
    (ref) => $BookAuthorHiveLocalAdapter(ref));

final bookAuthorsRemoteAdapterProvider = Provider<RemoteAdapter<BookAuthor>>(
    (ref) =>
        $BookAuthorRemoteAdapter(ref.read(bookAuthorsLocalAdapterProvider)));

final bookAuthorsRepositoryProvider =
    Provider<Repository<BookAuthor>>((ref) => Repository<BookAuthor>(ref));

final _watchBookAuthor = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<BookAuthor?>,
    DataState<BookAuthor?>,
    WatchArgs<BookAuthor>>((ref, args) {
  return ref.read(bookAuthorsRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<BookAuthor?>,
        DataState<BookAuthor?>>
    watchBookAuthor(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<BookAuthor>? alsoWatch}) {
  return _watchBookAuthor(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchBookAuthors = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<BookAuthor>>,
    DataState<List<BookAuthor>>,
    WatchArgs<BookAuthor>>((ref, args) {
  ref.maintainState = false;
  return ref.read(bookAuthorsRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<BookAuthor>>,
        DataState<List<BookAuthor>>>
    watchBookAuthors(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(BookAuthor)? filterLocal,
        bool? syncLocal}) {
  return _watchBookAuthors(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension BookAuthorX on BookAuthor {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  BookAuthor init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(bookAuthorsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $BookLocalAdapter on LocalAdapter<Book> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Book? model]) => {
        'original_author': {
          'name': 'originalAuthor',
          'inverse': 'books',
          'type': 'bookAuthors',
          'kind': 'BelongsTo',
          'instance': model?.originalAuthor
        }
      };

  @override
  Book deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Book.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $BookHiveLocalAdapter = HiveLocalAdapter<Book> with $BookLocalAdapter;

class $BookRemoteAdapter = RemoteAdapter<Book> with NothingMixin;

//

final booksLocalAdapterProvider =
    Provider<LocalAdapter<Book>>((ref) => $BookHiveLocalAdapter(ref));

final booksRemoteAdapterProvider = Provider<RemoteAdapter<Book>>(
    (ref) => $BookRemoteAdapter(ref.read(booksLocalAdapterProvider)));

final booksRepositoryProvider =
    Provider<Repository<Book>>((ref) => Repository<Book>(ref));

final _watchBook = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Book?>, DataState<Book?>, WatchArgs<Book>>(
        (ref, args) {
  return ref.read(booksRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Book?>, DataState<Book?>>
    watchBook(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Book>? alsoWatch}) {
  return _watchBook(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchBooks = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Book>>,
    DataState<List<Book>>,
    WatchArgs<Book>>((ref, args) {
  ref.maintainState = false;
  return ref.read(booksRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Book>>,
        DataState<List<Book>>>
    watchBooks(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(Book)? filterLocal,
        bool? syncLocal}) {
  return _watchBooks(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension BookX on Book {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Book init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(booksRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
