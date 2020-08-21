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
    RiverpodAlias.provider<Repository<Dog>>((ref) => Repository<Dog>(ref));

extension DogX on Dog {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Pass:
  ///  - A `BuildContext` if using Flutter with Riverpod or Provider
  ///  - Nothing if using Flutter with GetIt
  ///  - A Riverpod `ProviderContainer` if using pure Dart
  ///  - Its own [Repository<Dog>]
  Dog init(container) {
    final repository = container is Repository<Dog>
        ? container
        : internalLocatorFn(dogRepositoryProvider, container);
    return repository.internalAdapter.initializeModel(this, save: true) as Dog;
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
    RiverpodAlias.provider<Repository<Cat>>((ref) => Repository<Cat>(ref));

extension CatX on Cat {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Pass:
  ///  - A `BuildContext` if using Flutter with Riverpod or Provider
  ///  - Nothing if using Flutter with GetIt
  ///  - A Riverpod `ProviderContainer` if using pure Dart
  ///  - Its own [Repository<Cat>]
  Cat init(container) {
    final repository = container is Repository<Cat>
        ? container
        : internalLocatorFn(catRepositoryProvider, container);
    return repository.internalAdapter.initializeModel(this, save: true) as Cat;
  }
}
