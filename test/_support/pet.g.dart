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

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $DogLocalAdapter on LocalAdapter<Dog> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Dog model]) => {};

  @override
  Dog deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Dog.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $DogHiveLocalAdapter = HiveLocalAdapter<Dog> with $DogLocalAdapter;

class $DogRemoteAdapter = RemoteAdapter<Dog> with NothingMixin;

//

final dogLocalAdapterProvider = RiverpodAlias.provider<LocalAdapter<Dog>>(
    (ref) => $DogHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final dogRemoteAdapterProvider = RiverpodAlias.provider<RemoteAdapter<Dog>>(
    (ref) => $DogRemoteAdapter(ref.read(dogLocalAdapterProvider)));

final dogRepositoryProvider =
    RiverpodAlias.provider<Repository<Dog>>((_) => Repository<Dog>());

extension DogX on Dog {
  Dog init(owner) {
    return internalLocatorFn(dogRepositoryProvider, owner)
        .internalAdapter
        .initializeModel(this, save: true) as Dog;
  }
}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $CatLocalAdapter on LocalAdapter<Cat> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Cat model]) => {};

  @override
  Cat deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Cat.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $CatHiveLocalAdapter = HiveLocalAdapter<Cat> with $CatLocalAdapter;

class $CatRemoteAdapter = RemoteAdapter<Cat> with NothingMixin;

//

final catLocalAdapterProvider = RiverpodAlias.provider<LocalAdapter<Cat>>(
    (ref) => $CatHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final catRemoteAdapterProvider = RiverpodAlias.provider<RemoteAdapter<Cat>>(
    (ref) => $CatRemoteAdapter(ref.read(catLocalAdapterProvider)));

final catRepositoryProvider =
    RiverpodAlias.provider<Repository<Cat>>((_) => Repository<Cat>());

extension CatX on Cat {
  Cat init(owner) {
    return internalLocatorFn(catRepositoryProvider, owner)
        .internalAdapter
        .initializeModel(this, save: true) as Cat;
  }
}
