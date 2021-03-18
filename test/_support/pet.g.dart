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

final dogLocalAdapterProvider =
    Provider<LocalAdapter<Dog>>((ref) => $DogHiveLocalAdapter(ref));

final dogRemoteAdapterProvider = Provider<RemoteAdapter<Dog>>(
    (ref) => $DogRemoteAdapter(ref.read(dogLocalAdapterProvider)));

final dogRepositoryProvider =
    Provider<Repository<Dog>>((ref) => Repository<Dog>(ref));

final _watchDog = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Dog>, WatchArgs<Dog>>((ref, args) {
  return ref.watch(dogRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Dog>> watchDog(dynamic id,
    {bool remote = true,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    AlsoWatch<Dog> alsoWatch}) {
  return _watchDog(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchDogs = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<List<Dog>>, WatchArgs<Dog>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(dogRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Dog>>> watchDogs(
    {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
  return _watchDogs(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension DogX on Dog {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Dog init(Reader read) {
    final repository = internalLocatorFn(dogRepositoryProvider, read);
    return repository.remoteAdapter.initializeModel(this, save: true);
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

final catLocalAdapterProvider =
    Provider<LocalAdapter<Cat>>((ref) => $CatHiveLocalAdapter(ref));

final catRemoteAdapterProvider = Provider<RemoteAdapter<Cat>>(
    (ref) => $CatRemoteAdapter(ref.read(catLocalAdapterProvider)));

final catRepositoryProvider =
    Provider<Repository<Cat>>((ref) => Repository<Cat>(ref));

final _watchCat = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Cat>, WatchArgs<Cat>>((ref, args) {
  return ref.watch(catRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Cat>> watchCat(dynamic id,
    {bool remote = true,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    AlsoWatch<Cat> alsoWatch}) {
  return _watchCat(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchCats = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<List<Cat>>, WatchArgs<Cat>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(catRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Cat>>> watchCats(
    {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
  return _watchCats(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension CatX on Cat {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Cat init(Reader read) {
    final repository = internalLocatorFn(catRepositoryProvider, read);
    return repository.remoteAdapter.initializeModel(this, save: true);
  }
}
