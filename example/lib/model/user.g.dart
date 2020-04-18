// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$UserRepository extends Repository<User> {
  _$UserRepository(LocalAdapter<User> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};
}

class $UserRepository extends _$UserRepository
    with StandardJSONAdapter<User>, JSONPlaceholderAdapter<User> {
  $UserRepository(LocalAdapter<User> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $UserLocalAdapter extends LocalAdapter<User> {
  $UserLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    return User.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

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
