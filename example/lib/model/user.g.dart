// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$UserModelAdapter on Repository<User> {
  @override
  Map<String, Relationship> relationshipsFor(User model) => {};

  @override
  Map<String, Repository> get relationshipRepositories => {};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$UserFromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = _$UserToJson(model);
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension UserFDX on User {
  Map<String, dynamic> get _meta => flutterDataMetadata;
}

class $UserRepository = Repository<User>
    with
        _$UserModelAdapter,
        RemoteAdapter<User>,
        WatchAdapter<User>,
        StandardJSONAdapter<User>,
        JSONPlaceholderAdapter<User>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
    };
