// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $NodeLocalAdapter on LocalAdapter<Node> {
  static final rdata = RelationshipData<Node>({
    'parent': RelationshipDataItem<Node>(
      name: 'parent',
      inverseName: 'children',
      type: 'nodes',
      kind: 'BelongsTo',
      instance: (_) => _.parent,
    ),
    'children': RelationshipDataItem<Node>(
      name: 'children',
      inverseName: 'parent',
      type: 'nodes',
      kind: 'HasMany',
      instance: (_) => _.children,
    )
  });

  @override
  RelationshipData<Node> get relationshipData => rdata;

  @override
  Node deserialize(map) {
    map = transformDeserialize(map);
    return Node.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _nodesFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $NodeHiveLocalAdapter = HiveLocalAdapter<Node> with $NodeLocalAdapter;

class $NodeRemoteAdapter = RemoteAdapter<Node> with NodeAdapter;

final internalNodesRemoteAdapterProvider = Provider<RemoteAdapter<Node>>(
    (ref) => $NodeRemoteAdapter(
        $NodeHiveLocalAdapter(ref.read), InternalHolder(_nodesFinders)));

final nodesRepositoryProvider =
    Provider<Repository<Node>>((ref) => Repository<Node>(ref.read));

extension NodeDataRepositoryX on Repository<Node> {
  NodeAdapter get nodeAdapter => remoteAdapter as NodeAdapter;
}

extension NodeRelationshipDataX on RelationshipData<Node> {
  RelationshipDataItem<Node> get parent => items['parent']!;
  RelationshipDataItem<Node> get children => items['children']!;
}

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
