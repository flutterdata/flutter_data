// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dog _$DogFromJson(Map<String, dynamic> json) => Dog(
      id: json['id'] as String?,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DogToJson(Dog instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

Cat _$CatFromJson(Map<String, dynamic> json) => Cat(
      id: json['id'] as String?,
      meow: json['meow'] as bool,
    );

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
  Map<String, Map<String, Object?>> relationshipsFor([Dog? model]) => {};

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

final _dogsFinders = <String, dynamic>{};

//

final dogsRemoteAdapterProvider = Provider<RemoteAdapter<Dog>>((ref) =>
    $DogRemoteAdapter($DogHiveLocalAdapter(ref.read),
        InternalHolder(dogProvider, dogsProvider, _dogsFinders)));

final dogsRepositoryProvider =
    Provider<Repository<Dog>>((ref) => Repository<Dog>(ref.read));

final _dogProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Dog?>, DataState<Dog?>, WatchArgs<Dog>>(
        (ref, args) {
  final adapter = ref.watch(dogsRemoteAdapterProvider);
  final _watcherFinder = _dogsFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherOne<Dog>
      ? _watcherFinder
      : adapter.watchOneNotifier;
  ref.maintainState = true;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Dog?>, DataState<Dog?>>
    dogProvider(
  Object? id, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<Dog>? alsoWatch,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _dogProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher,
      label: label));
}

final _dogsProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Dog>?>,
    DataState<List<Dog>?>,
    WatchArgs<Dog>>((ref, args) {
  final adapter = ref.watch(dogsRemoteAdapterProvider);
  final _watcherFinder = _dogsFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherAll<Dog>
      ? _watcherFinder
      : adapter.watchAllNotifier;
  ref.maintainState = true;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Dog>?>,
    DataState<List<Dog>?>> dogsProvider({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _dogsProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher,
      label: label));
}

extension DogDataX on Dog {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Dog init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(dogsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension DogDataRepositoryX on Repository<Dog> {}

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $CatLocalAdapter on LocalAdapter<Cat> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Cat? model]) => {};

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

final _catsFinders = <String, dynamic>{};

//

final catsRemoteAdapterProvider = Provider<RemoteAdapter<Cat>>((ref) =>
    $CatRemoteAdapter($CatHiveLocalAdapter(ref.read),
        InternalHolder(catProvider, catsProvider, _catsFinders)));

final catsRepositoryProvider =
    Provider<Repository<Cat>>((ref) => Repository<Cat>(ref.read));

final _catProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Cat?>, DataState<Cat?>, WatchArgs<Cat>>(
        (ref, args) {
  final adapter = ref.watch(catsRemoteAdapterProvider);
  final _watcherFinder = _catsFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherOne<Cat>
      ? _watcherFinder
      : adapter.watchOneNotifier;
  ref.maintainState = true;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Cat?>, DataState<Cat?>>
    catProvider(
  Object? id, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<Cat>? alsoWatch,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _catProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher,
      label: label));
}

final _catsProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Cat>?>,
    DataState<List<Cat>?>,
    WatchArgs<Cat>>((ref, args) {
  final adapter = ref.watch(catsRemoteAdapterProvider);
  final _watcherFinder = _catsFinders[args.watcher]?.call(adapter);
  final notifier = _watcherFinder is DataWatcherAll<Cat>
      ? _watcherFinder
      : adapter.watchAllNotifier;
  ref.maintainState = true;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder,
      label: args.label);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Cat>?>,
    DataState<List<Cat>?>> catsProvider({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  String? watcher,
  DataRequestLabel? label,
}) {
  return _catsProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher,
      label: label));
}

extension CatDataX on Cat {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Cat init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(catsRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension CatDataRepositoryX on Repository<Cat> {}
