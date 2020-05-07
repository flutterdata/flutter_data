// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$UserModelAdapter on Repository<User> {
  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{}[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    return _$UserFromJson(map as Map<String, dynamic>);
  }

  @override
  serialize(model) {
    final map = _$UserToJson(model);

    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
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
