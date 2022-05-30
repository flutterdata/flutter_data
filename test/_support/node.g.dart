// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $NodeLocalAdapter on LocalAdapter<Node> {
  static final Map<String, FieldMeta> _kNodeFieldMetas = {
    'name': AttributeMeta<Node>(
      name: 'name',
      type: 'String',
      nullable: true,
      internalType: 'String',
    ),
    'children': RelationshipMeta<Node>(
      name: 'children',
      inverseName: 'parent',
      type: 'nodes',
      kind: 'HasMany',
      instance: (_) => (_ as Node).children,
    ),
    'parent': RelationshipMeta<Node>(
      name: 'parent',
      inverseName: 'children',
      type: 'nodes',
      kind: 'BelongsTo',
      instance: (_) => (_ as Node).parent,
    )
  };

  @override
  Map<String, FieldMeta> get fieldMetas => _kNodeFieldMetas;

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
class $NodeIsarLocalAdapter = IsarLocalAdapter<Node> with $NodeLocalAdapter;

class $NodeRemoteAdapter = RemoteAdapter<Node> with NodeAdapter;

final internalNodesRemoteAdapterProvider = Provider<RemoteAdapter<Node>>(
    (ref) => $NodeRemoteAdapter(
        $NodeIsarLocalAdapter(ref.read), InternalHolder(_nodesFinders)));

final nodesRepositoryProvider =
    Provider<Repository<Node>>((ref) => Repository<Node>(ref.read));

extension NodeDataRepositoryX on Repository<Node> {
  NodeAdapter get nodeAdapter => remoteAdapter as NodeAdapter;
}

extension NodeRelationshipGraphNodeX on RelationshipGraphNode<Node> {
  RelationshipGraphNode<Node> get children {
    final meta = $NodeLocalAdapter._kNodeFieldMetas['children']
        as RelationshipMeta<Node>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Node> get parent {
    final meta =
        $NodeLocalAdapter._kNodeFieldMetas['parent'] as RelationshipMeta<Node>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
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
