// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) {
  return House(
    id: json['id'] as String?,
    address: json['address'] as String,
    owner: json['owner'] == null
        ? null
        : BelongsTo.fromJson(json['owner'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$HouseToJson(House instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'owner': instance.owner,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $HouseLocalAdapter on LocalAdapter<House> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([House? model]) => {
        'owner': {
          'name': 'owner',
          'inverse': 'residence',
          'type': 'families',
          'kind': 'BelongsTo',
          'instance': model?.owner
        }
      };

  @override
  House deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$HouseFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$HouseToJson(model);
}

// ignore: must_be_immutable
class $HouseHiveLocalAdapter = HiveLocalAdapter<House> with $HouseLocalAdapter;

class $HouseRemoteAdapter = RemoteAdapter<House> with NothingMixin;

//

final housesLocalAdapterProvider =
    Provider<LocalAdapter<House>>((ref) => $HouseHiveLocalAdapter(ref));

final housesRemoteAdapterProvider = Provider<RemoteAdapter<House>>(
    (ref) => $HouseRemoteAdapter(ref.read(housesLocalAdapterProvider)));

final housesRepositoryProvider =
    Provider<Repository<House>>((ref) => Repository<House>(ref));

final _watchHouse = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<House?>, DataState<House?>, WatchArgs<House>>(
        (ref, args) {
  return ref.read(housesRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<House?>, DataState<House?>>
    watchHouse(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<House>? alsoWatch}) {
  return _watchHouse(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchHouses = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<House>>,
    DataState<List<House>>,
    WatchArgs<House>>((ref, args) {
  ref.maintainState = false;
  return ref.read(housesRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<House>>,
        DataState<List<House>>>
    watchHouses(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(House)? filterLocal,
        bool? syncLocal}) {
  return _watchHouses(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension HouseX on House {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  House init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(housesRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
