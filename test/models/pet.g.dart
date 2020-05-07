// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$DogModelAdapter on Repository<Dog> {
  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{}[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    return Dog.fromJson(map as Map<String, dynamic>);
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

class $DogRepository = Repository<Dog>
    with _$DogModelAdapter, RemoteAdapter<Dog>, WatchAdapter<Dog>;

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$CatModelAdapter on Repository<Cat> {
  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{}[type];
  }

  @override
  deserialize(map, {key, initialize = true}) {
    return Cat.fromJson(map as Map<String, dynamic>);
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

class $CatRepository = Repository<Cat>
    with _$CatModelAdapter, RemoteAdapter<Cat>, WatchAdapter<Cat>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dog _$DogFromJson(Map<String, dynamic> json) {
  return Dog(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$DogToJson(Dog instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Cat _$CatFromJson(Map<String, dynamic> json) {
  return Cat(
    id: json['id'] as String,
    meow: json['meow'] as bool,
  );
}

Map<String, dynamic> _$CatToJson(Cat instance) => <String, dynamic>{
      'id': instance.id,
      'meow': instance.meow,
    };
