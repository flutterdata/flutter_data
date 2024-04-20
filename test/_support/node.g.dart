// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$NodeAdapter on Adapter<Node> {
  static final Map<String, RelationshipMeta> _kNodeRelationshipMetas = {
    'parent': RelationshipMeta<Node>(
      name: 'parent',
      inverseName: 'children',
      type: 'nodes',
      kind: 'BelongsTo',
      instance: (_) => (_ as Node).parent,
    ),
    'children': RelationshipMeta<Node>(
      name: 'children',
      inverseName: 'parent',
      type: 'nodes',
      kind: 'HasMany',
      instance: (_) => (_ as Node).children,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kNodeRelationshipMetas;

  @override
  Node deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => Node.fromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = model.toJson();
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _nodesFinders = <String, dynamic>{};

class $NodeAdapter = Adapter<Node>
    with _$NodeAdapter, NodeLocalAdapter, NodeAdapter;

final nodesAdapterProvider = Provider<Adapter<Node>>(
    (ref) => $NodeAdapter(ref, InternalHolder(_nodesFinders)));

extension NodeAdapterX on Adapter<Node> {
  NodeAdapter get nodeAdapter => this as NodeAdapter;
}

extension NodeRelationshipGraphNodeX on RelationshipGraphNode<Node> {
  RelationshipGraphNode<Node> get parent {
    final meta = _$NodeAdapter._kNodeRelationshipMetas['parent']
        as RelationshipMeta<Node>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Node> get children {
    final meta = _$NodeAdapter._kNodeRelationshipMetas['children']
        as RelationshipMeta<Node>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NodeImpl _$$NodeImplFromJson(Map<String, dynamic> json) => _$NodeImpl(
      id: json['id'] as int?,
      name: json['name'] as String?,
      parent: json['parent'] == null
          ? null
          : BelongsTo<Node>.fromJson(json['parent'] as Map<String, dynamic>),
      children: json['children'] == null
          ? null
          : HasMany<Node>.fromJson(json['children'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NodeImplToJson(_$NodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent': instance.parent,
      'children': instance.children,
    };
