// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $UserLocalAdapter on LocalAdapter<User> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([User? model]) => {
        'tasks': {
          'name': 'tasks',
          'inverse': 'user',
          'type': 'tasks',
          'kind': 'HasMany',
          'instance': model?.tasks
        }
      };

  @override
  User deserialize(map) {
    map = transformDeserialize(map);
    return _$UserFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$UserToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _usersFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $UserHiveLocalAdapter = HiveLocalAdapter<User> with $UserLocalAdapter;

class $UserRemoteAdapter = RemoteAdapter<User> with JSONServerAdapter<User>;

final internalUsersRemoteAdapterProvider = Provider<RemoteAdapter<User>>(
    (ref) => $UserRemoteAdapter(
        $UserHiveLocalAdapter(ref.read), InternalHolder(_usersFinders)));

final usersRepositoryProvider =
    Provider<Repository<User>>((ref) => Repository<User>(ref.read));

extension UserDataRepositoryX on Repository<User> {
  JSONServerAdapter<User> get jSONServerAdapter =>
      remoteAdapter as JSONServerAdapter<User>;
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
