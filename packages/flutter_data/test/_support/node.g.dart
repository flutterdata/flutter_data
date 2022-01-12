// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Node _$$_NodeFromJson(Map<String, dynamic> json) => _$_Node(
      id: json['id'] as int?,
      name: json['name'] as String?,
      parent: json['parent'] == null
          ? null
          : BelongsTo<Node>.fromJson(json['parent'] as Map<String, dynamic>),
      children: json['children'] == null
          ? null
          : HasMany<Node>.fromJson(json['children'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_NodeToJson(_$_Node instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent': instance.parent,
      'children': instance.children,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $NodeLocalAdapter on LocalAdapter<Node> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Node? model]) => {
        'parent': {
          'name': 'parent',
          'inverse': 'children',
          'type': 'nodes',
          'kind': 'BelongsTo',
          'instance': model?.parent
        },
        'children': {
          'name': 'children',
          'inverse': 'parent',
          'type': 'nodes',
          'kind': 'HasMany',
          'instance': model?.children
        }
      };

  @override
  Node deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Node.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $NodeHiveLocalAdapter = HiveLocalAdapter<Node> with $NodeLocalAdapter;

class $NodeRemoteAdapter = RemoteAdapter<Node> with NothingMixin;

//

final nodesLocalAdapterProvider =
    Provider<LocalAdapter<Node>>((ref) => $NodeHiveLocalAdapter(ref.read));

final nodesRemoteAdapterProvider = Provider<RemoteAdapter<Node>>((ref) =>
    $NodeRemoteAdapter(
        ref.watch(nodesLocalAdapterProvider), nodeProvider, nodesProvider));

final nodesRepositoryProvider =
    Provider<Repository<Node>>((ref) => Repository<Node>(ref.read));

final _nodeProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Node?>, DataState<Node?>, WatchArgs<Node>>(
        (ref, args) {
  return ref.watch(nodesRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Node?>, DataState<Node?>>
    nodeProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Node>? alsoWatch}) {
  return _nodeProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _nodesProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Node>>,
    DataState<List<Node>>,
    WatchArgs<Node>>((ref, args) {
  return ref.watch(nodesRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Node>>,
        DataState<List<Node>>>
    nodesProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _nodesProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

extension NodeDataX on Node {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Node init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(nodesRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension NodeDataRepositoryX on Repository<Node> {}
