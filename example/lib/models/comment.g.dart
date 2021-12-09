// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as int,
      body: json['body'] as String?,
      approved: json['approved'] as bool? ?? false,
      post: json['post'] == null
          ? null
          : BelongsTo<Post>.fromJson(json['post'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'approved': instance.approved,
      'post': instance.post,
    };

Sheep _$SheepFromJson(Map<String, dynamic> json) => Sheep(
      id: json['id'] as int,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SheepToJson(Sheep instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $CommentLocalAdapter on LocalAdapter<Comment> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Comment? model]) => {
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

final commentsLocalAdapterProvider = Provider<LocalAdapter<Comment>>(
    (ref) => $CommentHiveLocalAdapter(ref.read));

final commentsRemoteAdapterProvider = Provider<RemoteAdapter<Comment>>((ref) =>
    $CommentRemoteAdapter(ref.watch(commentsLocalAdapterProvider),
        commentProvider, commentsProvider));

final commentsRepositoryProvider =
    Provider<Repository<Comment>>((ref) => Repository<Comment>(ref.read));

final _commentProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<Comment?>,
    DataState<Comment?>,
    WatchArgs<Comment>>((ref, args) {
  return ref.watch(commentsRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Comment?>,
        DataState<Comment?>>
    commentProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Comment>? alsoWatch}) {
  return _commentProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _commentsProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Comment>>,
    DataState<List<Comment>>,
    WatchArgs<Comment>>((ref, args) {
  return ref.watch(commentsRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Comment>>,
        DataState<List<Comment>>>
    commentsProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _commentsProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

extension CommentDataX on Comment {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Comment init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(commentsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension CommentDataRepositoryX on Repository<Comment> {
  JSONServerAdapter<Comment> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<Comment>;
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $SheepLocalAdapter on LocalAdapter<Sheep> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Sheep? model]) => {};

  @override
  Sheep deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$SheepFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$SheepToJson(model);
}

// ignore: must_be_immutable
class $SheepHiveLocalAdapter = HiveLocalAdapter<Sheep> with $SheepLocalAdapter;

class $SheepRemoteAdapter = RemoteAdapter<Sheep> with JSONServerAdapter<Sheep>;

//

final sheepLocalAdapterProvider =
    Provider<LocalAdapter<Sheep>>((ref) => $SheepHiveLocalAdapter(ref.read));

final sheepRemoteAdapterProvider = Provider<RemoteAdapter<Sheep>>((ref) =>
    $SheepRemoteAdapter(
        ref.watch(sheepLocalAdapterProvider), sheepOneProvider, sheepProvider));

final sheepRepositoryProvider =
    Provider<Repository<Sheep>>((ref) => Repository<Sheep>(ref.read));

final _sheepOneProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Sheep?>, DataState<Sheep?>, WatchArgs<Sheep>>(
        (ref, args) {
  return ref.watch(sheepRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Sheep?>, DataState<Sheep?>>
    sheepOneProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Sheep>? alsoWatch}) {
  return _sheepOneProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _sheepProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Sheep>>,
    DataState<List<Sheep>>,
    WatchArgs<Sheep>>((ref, args) {
  return ref.watch(sheepRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Sheep>>,
        DataState<List<Sheep>>>
    sheepProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _sheepProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

extension SheepDataX on Sheep {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Sheep init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(sheepRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension SheepDataRepositoryX on Repository<Sheep> {
  JSONServerAdapter<Sheep> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<Sheep>;
}
