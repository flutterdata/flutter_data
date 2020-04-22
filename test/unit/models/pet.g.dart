// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$DogRepository extends Repository<Dog> {
  _$DogRepository(LocalAdapter<Dog> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};
}

class $DogRepository extends _$DogRepository {
  $DogRepository(LocalAdapter<Dog> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $DogLocalAdapter extends LocalAdapter<Dog> {
  $DogLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    return Dog.fromJson(map);
  }

  @override
  serialize(model) {
    final map = _$DogToJson(model);

    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$CatRepository extends Repository<Cat> {
  _$CatRepository(LocalAdapter<Cat> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};
}

class $CatRepository extends _$CatRepository {
  $CatRepository(LocalAdapter<Cat> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CatLocalAdapter extends LocalAdapter<Cat> {
  $CatLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    return Cat.fromJson(map);
  }

  @override
  serialize(model) {
    final map = _$CatToJson(model);

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
