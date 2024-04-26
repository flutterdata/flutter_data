// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// AdapterGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$UserAdapter on Adapter<User> {
  static final Map<String, RelationshipMeta> _kUserRelationshipMetas = {
    'tasks': RelationshipMeta<Task>(
      name: 'tasks',
      inverseName: 'user',
      type: 'tasks',
      kind: 'HasMany',
      instance: (_) => (_ as User).tasks,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kUserRelationshipMetas;

  @override
  User deserializeLocal(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => _$UserFromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serializeLocal(model, {bool withRelationships = true}) {
    final map = _$UserToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _usersFinders = <String, dynamic>{};

class $UserAdapter = Adapter<User> with _$UserAdapter, JSONServerAdapter<User>;

final usersAdapterProvider = Provider<Adapter<User>>(
    (ref) => $UserAdapter(ref, InternalHolder(_usersFinders)));

extension UserAdapterX on Adapter<User> {
  JSONServerAdapter<User> get jSONServerAdapter =>
      this as JSONServerAdapter<User>;
}

extension UserRelationshipGraphNodeX on RelationshipGraphNode<User> {
  RelationshipGraphNode<Task> get tasks {
    final meta = _$UserAdapter._kUserRelationshipMetas['tasks']
        as RelationshipMeta<Task>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      tasks: json['tasks'] == null
          ? null
          : HasMany<Task>.fromJson(json['tasks'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tasks': instance.tasks,
    };
