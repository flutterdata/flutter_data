// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) {
  return Post(
    id: json['id'] as int,
    title: json['title'] as String?,
    body: json['body'] as String?,
    comments: json['comments'] == null
        ? null
        : HasMany.fromJson(json['comments'] as Map<String, dynamic>),
    user: json['user'] == null
        ? null
        : BelongsTo.fromJson(json['user'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'comments': instance.comments,
      'user': instance.user,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $PostLocalAdapter on LocalAdapter<Post> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Post? model]) => {
        'comments': {
          'name': 'comments',
          'inverse': 'post',
          'type': 'comments',
          'kind': 'HasMany',
          'instance': model?.comments
        },
        'user': {
          'name': 'user',
          'type': 'users',
          'kind': 'BelongsTo',
          'instance': model?.user
        }
      };

  @override
  Post deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$PostFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$PostToJson(model);
}

// ignore: must_be_immutable
class $PostHiveLocalAdapter = HiveLocalAdapter<Post> with $PostLocalAdapter;

class $PostRemoteAdapter = RemoteAdapter<Post> with JSONServerAdapter<Post>;

//

final postsLocalAdapterProvider =
    Provider<LocalAdapter<Post>>((ref) => $PostHiveLocalAdapter(ref));

final postsRemoteAdapterProvider = Provider<RemoteAdapter<Post>>(
    (ref) => $PostRemoteAdapter(ref.read(postsLocalAdapterProvider)));

final postsRepositoryProvider =
    Provider<Repository<Post>>((ref) => Repository<Post>(ref));

final _watchPost = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Post?>, DataState<Post?>, WatchArgs<Post>>(
        (ref, args) {
  return ref.read(postsRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Post?>, DataState<Post?>>
    watchPost(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Post>? alsoWatch}) {
  return _watchPost(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchPosts = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Post>>,
    DataState<List<Post>>,
    WatchArgs<Post>>((ref, args) {
  ref.maintainState = false;
  return ref.read(postsRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Post>>,
        DataState<List<Post>>>
    watchPosts(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(Post)? filterLocal,
        bool? syncLocal}) {
  return _watchPosts(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension PostX on Post {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Post init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(postsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
