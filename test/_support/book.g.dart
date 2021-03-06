// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Author _$_$_AuthorFromJson(Map<String, dynamic> json) {
  return _$_Author(
    id: json['id'] as int,
    name: json['name'] as String?,
    books: json['books'] == null
        ? null
        : HasMany.fromJson(json['books'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_AuthorToJson(_$_Author instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'books': instance.books,
    };

_$_Book _$_$_BookFromJson(Map<String, dynamic> json) {
  return _$_Book(
    id: json['id'] as int,
    title: json['title'] as String?,
    author: json['author'] == null
        ? null
        : BelongsTo.fromJson(json['author'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_BookToJson(_$_Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $AuthorLocalAdapter on LocalAdapter<Author> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Author? model]) => {
        'books': {
          'name': 'books',
          'inverse': 'author',
          'type': 'books',
          'kind': 'HasMany',
          'instance': model?.books
        }
      };

  @override
  Author deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Author.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $AuthorHiveLocalAdapter = HiveLocalAdapter<Author>
    with $AuthorLocalAdapter;

class $AuthorRemoteAdapter = RemoteAdapter<Author> with AuthorAdapter;

//

final authorsLocalAdapterProvider =
    Provider<LocalAdapter<Author>>((ref) => $AuthorHiveLocalAdapter(ref));

final authorsRemoteAdapterProvider = Provider<RemoteAdapter<Author>>(
    (ref) => $AuthorRemoteAdapter(ref.read(authorsLocalAdapterProvider)));

final authorsRepositoryProvider =
    Provider<Repository<Author>>((ref) => Repository<Author>(ref));

final _watchAuthor = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Author?>, DataState<Author?>, WatchArgs<Author>>(
        (ref, args) {
  return ref.read(authorsRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Author?>, DataState<Author?>>
    watchAuthor(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Author>? alsoWatch}) {
  return _watchAuthor(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchAuthors = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Author>>,
    DataState<List<Author>>,
    WatchArgs<Author>>((ref, args) {
  ref.maintainState = false;
  return ref.read(authorsRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Author>>,
        DataState<List<Author>>>
    watchAuthors(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers}) {
  return _watchAuthors(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension AuthorX on Author {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Author init(Reader read) {
    final repository = internalLocatorFn(authorsRepositoryProvider, read);
    return repository.remoteAdapter.initializeModel(this, save: true);
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $BookLocalAdapter on LocalAdapter<Book> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Book? model]) => {
        'author': {
          'name': 'author',
          'inverse': 'books',
          'type': 'authors',
          'kind': 'BelongsTo',
          'instance': model?.author
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
        Map<String, String>? headers}) {
  return _watchBooks(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension BookX on Book {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Book init(Reader read) {
    final repository = internalLocatorFn(booksRepositoryProvider, read);
    return repository.remoteAdapter.initializeModel(this, save: true);
  }
}
