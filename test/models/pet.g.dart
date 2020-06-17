// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$DogModelAdapter on Repository<Dog> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Dog model]) => {};

  @override
  Map<String, Repository> get relatedRepositories => {};

  @override
  localDeserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Dog.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $DogRepository = Repository<Dog>
    with _$DogModelAdapter, RemoteAdapter<Dog>, WatchAdapter<Dog>;

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$CatModelAdapter on Repository<Cat> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Cat model]) => {};

  @override
  Map<String, Repository> get relatedRepositories => {};

  @override
  localDeserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Cat.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
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
