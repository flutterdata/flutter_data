// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

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

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin $DogLocalAdapter on LocalAdapter<Dog> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Dog model]) => {};

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Dog.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

// ignore: must_be_immutable
class $DogHiveLocalAdapter = HiveLocalAdapter<Dog> with $DogLocalAdapter;

class $DogRemoteAdapter = RemoteAdapter<Dog> with NothingMixin;

//

final dogsLocalAdapterProvider = Provider<LocalAdapter<Dog>>(
    (ref) => $DogHiveLocalAdapter(ref.read(graphProvider)));

final dogsRemoteAdapterProvider = Provider<RemoteAdapter<Dog>>(
    (ref) => $DogRemoteAdapter(ref.read(dogsLocalAdapterProvider)));

final dogsRepositoryProvider =
    Provider<Repository<Dog>>((_) => Repository<Dog>());

extension DogX on Dog {
  Dog init(owner) {
    return initFromRepository(
        owner.ref.read(dogsRepositoryProvider) as Repository<Dog>);
  }
}

extension DogRepositoryX on Repository<Dog> {}

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin $CatLocalAdapter on LocalAdapter<Cat> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Cat model]) => {};

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Cat.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    for (final e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

// ignore: must_be_immutable
class $CatHiveLocalAdapter = HiveLocalAdapter<Cat> with $CatLocalAdapter;

class $CatRemoteAdapter = RemoteAdapter<Cat> with NothingMixin;

//

final catsLocalAdapterProvider = Provider<LocalAdapter<Cat>>(
    (ref) => $CatHiveLocalAdapter(ref.read(graphProvider)));

final catsRemoteAdapterProvider = Provider<RemoteAdapter<Cat>>(
    (ref) => $CatRemoteAdapter(ref.read(catsLocalAdapterProvider)));

final catsRepositoryProvider =
    Provider<Repository<Cat>>((_) => Repository<Cat>());

extension CatX on Cat {
  Cat init(owner) {
    return initFromRepository(
        owner.ref.read(catsRepositoryProvider) as Repository<Cat>);
  }
}

extension CatRepositoryX on Repository<Cat> {}
