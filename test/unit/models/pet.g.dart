// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$DogRepository extends Repository<Dog> {
  _$DogRepository(LocalAdapter<Dog> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

class $DogRepository extends _$DogRepository {
  $DogRepository(LocalAdapter<Dog> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $DogLocalAdapter extends LocalAdapter<Dog> {
  $DogLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    manager.dataId<Dog>(map.id, key: key);
    return Dog.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }
}

// ignore_for_file: unused_local_variable
class _$CatRepository extends Repository<Cat> {
  _$CatRepository(LocalAdapter<Cat> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

class $CatRepository extends _$CatRepository {
  $CatRepository(LocalAdapter<Cat> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $CatLocalAdapter extends LocalAdapter<Cat> {
  $CatLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    manager.dataId<Cat>(map.id, key: key);
    return Cat.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }
}

// ignore_for_file: unused_local_variable
class _$ZebraRepository extends Repository<Zebra> {
  _$ZebraRepository(LocalAdapter<Zebra> adapter) : super(adapter);

  @override
  get relationshipMetadata => {'HasMany': {}, 'BelongsTo': {}};

  @override
  setOwnerInRelationships(owner, model) {}

  @override
  void setInverseInModel(inverse, model) {}
}

class $ZebraRepository extends _$ZebraRepository {
  $ZebraRepository(LocalAdapter<Zebra> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $ZebraLocalAdapter extends LocalAdapter<Zebra> {
  $ZebraLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    manager.dataId<Zebra>(map.id, key: key);
    return Zebra.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    return map;
  }
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

Zebra _$ZebraFromJson(Map<String, dynamic> json) {
  return Zebra(
    id: json['id'] as String,
    name: json['name'] as String,
  );
}

Map<String, dynamic> _$ZebraToJson(Zebra instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
