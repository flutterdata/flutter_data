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

final bookAuthorsRemoteAdapterProvider = Provider<RemoteAdapter<BookAuthor>>(
    (ref) => $BookAuthorRemoteAdapter($BookAuthorHiveLocalAdapter(ref.read),
        bookAuthorProvider, bookAuthorsProvider));

final bookAuthorsRepositoryProvider =
    Provider<Repository<BookAuthor>>((ref) => Repository<BookAuthor>(ref.read));

final _bookAuthorProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<BookAuthor?>,
    DataState<BookAuthor?>,
    WatchArgs<BookAuthor>>((ref, args) {
  final adapter = ref.watch(bookAuthorsRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersOne[args.watcher] ?? adapter.watchOneNotifier;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<BookAuthor?>,
        DataState<BookAuthor?>>
    bookAuthorProvider(Object? id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<BookAuthor>? alsoWatch,
        String? finder,
        String? watcher}) {
  return _bookAuthorProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher));
}

final _bookAuthorsProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<BookAuthor>>,
    DataState<List<BookAuthor>>,
    WatchArgs<BookAuthor>>((ref, args) {
  final adapter = ref.watch(bookAuthorsRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersAll[args.watcher] ?? adapter.watchAllNotifier;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<BookAuthor>>,
        DataState<List<BookAuthor>>>
    bookAuthorsProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal,
        String? finder,
        String? watcher}) {
  return _bookAuthorsProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher));
}

extension BookAuthorDataX on BookAuthor {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  BookAuthor init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(bookAuthorsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension BookAuthorDataRepositoryX on Repository<BookAuthor> {
  BookAuthorAdapter get bookAuthorAdapter => remoteAdapter as BookAuthorAdapter;
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

final booksRemoteAdapterProvider = Provider<RemoteAdapter<Book>>((ref) =>
    $BookRemoteAdapter(
        $BookHiveLocalAdapter(ref.read), bookProvider, booksProvider));

final booksRepositoryProvider =
    Provider<Repository<Book>>((ref) => Repository<Book>(ref.read));

final _bookProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Book?>, DataState<Book?>, WatchArgs<Book>>(
        (ref, args) {
  final adapter = ref.watch(booksRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersOne[args.watcher] ?? adapter.watchOneNotifier;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Book?>, DataState<Book?>>
    bookProvider(Object? id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Book>? alsoWatch,
        String? finder,
        String? watcher}) {
  return _bookProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher));
}

final _booksProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Book>>,
    DataState<List<Book>>,
    WatchArgs<Book>>((ref, args) {
  final adapter = ref.watch(booksRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersAll[args.watcher] ?? adapter.watchAllNotifier;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Book>>,
        DataState<List<Book>>>
    booksProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal,
        String? finder,
        String? watcher}) {
  return _booksProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher));
}

extension BookDataX on Book {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Book init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(booksRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension BookDataRepositoryX on Repository<Book> {}
