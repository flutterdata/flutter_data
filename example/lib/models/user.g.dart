// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$UserLocalAdapter on LocalAdapter<User> {
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
  User deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => _$UserFromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$UserToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _usersFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $UserLocalAdapter = LocalAdapter<User> with _$UserLocalAdapter;

class $UserRemoteAdapter = RemoteAdapter<User> with JSONServerAdapter<User>;

final internalUsersRemoteAdapterProvider = Provider<RemoteAdapter<User>>(
    (ref) => $UserRemoteAdapter(
        $UserLocalAdapter(ref), InternalHolder(_usersFinders)));

final usersRepositoryProvider =
    Provider<Repository<User>>((ref) => Repository<User>(ref));

extension UserDataRepositoryX on Repository<User> {
  JSONServerAdapter<User> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<User>;
}

extension UserRelationshipGraphNodeX on RelationshipGraphNode<User> {
  RelationshipGraphNode<Task> get tasks {
    final meta = _$UserLocalAdapter._kUserRelationshipMetas['tasks']
        as RelationshipMeta<Task>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int?,
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
