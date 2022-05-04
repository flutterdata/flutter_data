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

final _nodesFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $NodeHiveLocalAdapter = HiveLocalAdapter<Node> with $NodeLocalAdapter;

class $NodeRemoteAdapter = RemoteAdapter<Node> with NothingMixin;

final internalNodesRemoteAdapterProvider = Provider<RemoteAdapter<Node>>(
    (ref) => $NodeRemoteAdapter(
        $NodeHiveLocalAdapter(ref.read), InternalHolder(_nodesFinders)));

final nodesRepositoryProvider =
    Provider<Repository<Node>>((ref) => Repository<Node>(ref.read));

extension NodeDataRepositoryX on Repository<Node> {}
