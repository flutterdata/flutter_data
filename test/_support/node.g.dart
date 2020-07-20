// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_Node _$_$_NodeFromJson(Map<String, dynamic> json) {
  return _$_Node(
    id: json['id'] as int,
    name: json['name'] as String,
    parent: json['parent'] == null
        ? null
        : BelongsTo.fromJson(json['parent'] as Map<String, dynamic>),
    children: json['children'] == null
        ? null
        : HasMany.fromJson(json['children'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$_$_NodeToJson(_$_Node instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent': instance.parent,
      'children': instance.children,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin $NodeLocalAdapter on LocalAdapter<Node> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Node model]) => {
        'parent': {
          'inverse': 'children',
          'type': 'nodes',
          'kind': 'BelongsTo',
          'instance': model?.parent
        },
        'children': {
          'inverse': 'parent',
          'type': 'nodes',
          'kind': 'HasMany',
          'instance': model?.children
        }
      };

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Node.fromJson(map);
  }

  @override
  serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $NodeHiveLocalAdapter = HiveLocalAdapter<Node> with $NodeLocalAdapter;

class $NodeRemoteAdapter = RemoteAdapter<Node> with NothingMixin;

//

final nodesLocalAdapterProvider = Provider<LocalAdapter<Node>>((ref) =>
    $NodeHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final nodesRemoteAdapterProvider = Provider<RemoteAdapter<Node>>(
    (ref) => $NodeRemoteAdapter(ref.read(nodesLocalAdapterProvider)));

final nodesRepositoryProvider =
    Provider<Repository<Node>>((_) => Repository<Node>());

extension NodeX on Node {
  Node init([owner]) {
    if (owner == null && debugGlobalServiceLocatorInstance != null) {
      return debugInit(
          debugGlobalServiceLocatorInstance.get<Repository<Node>>());
    }
    return debugInit(owner.ref.read(nodesRepositoryProvider));
  }
}

extension NodeRepositoryX on Repository<Node> {}
