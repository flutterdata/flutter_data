// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) {
  return Comment(
    id: json['id'] as int,
    body: json['body'] as String,
    approved: json['approved'] as bool,
    post: json['post'] == null
        ? null
        : BelongsTo.fromJson(json['post'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'approved': instance.approved,
      'post': instance.post,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $CommentLocalAdapter on LocalAdapter<Comment> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Comment model]) => {
        'post': {
          'name': 'post',
          'inverse': 'comments',
          'type': 'posts',
          'kind': 'BelongsTo',
          'instance': model?.post
        }
      };

  @override
  Comment deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$CommentFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$CommentToJson(model);
}

// ignore: must_be_immutable
class $CommentHiveLocalAdapter = HiveLocalAdapter<Comment>
    with $CommentLocalAdapter;

class $CommentRemoteAdapter = RemoteAdapter<Comment>
    with JSONServerAdapter<Comment>;

//

final commentLocalAdapterProvider =
    Provider<LocalAdapter<Comment>>((ref) => $CommentHiveLocalAdapter(ref));

final commentRemoteAdapterProvider = Provider<RemoteAdapter<Comment>>(
    (ref) => $CommentRemoteAdapter(ref.read(commentLocalAdapterProvider)));

final commentRepositoryProvider =
    Provider<Repository<Comment>>((ref) => Repository<Comment>(ref));

final _watchComment = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Comment>, WatchArgs<Comment>>((ref, args) {
  return ref.watch(commentRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Comment>> watchComment(
    dynamic id,
    {bool remote = true,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    AlsoWatch<Comment> alsoWatch}) {
  return _watchComment(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchComments = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<List<Comment>>, WatchArgs<Comment>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(commentRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Comment>>>
    watchComments(
        {bool remote,
        Map<String, dynamic> params,
        Map<String, String> headers}) {
  return _watchComments(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension CommentX on Comment {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Pass:
  ///  - A `BuildContext` if using Flutter with Riverpod or Provider
  ///  - Nothing if using Flutter with GetIt
  ///  - A Riverpod `ProviderContainer` if using pure Dart
  ///  - Its own [Repository<Comment>]
  Comment init([container]) {
    final repository = container is Repository<Comment>
        ? container
        : internalLocatorFn(commentRepositoryProvider, container);
    return repository.internalAdapter.initializeModel(this, save: true)
        as Comment;
  }
}
