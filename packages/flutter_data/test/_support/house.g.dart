// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) => House(
      id: json['id'] as String?,
      address: json['address'] as String,
      owner: json['owner'] == null
          ? null
          : BelongsTo<Family>.fromJson(json['owner'] as Map<String, dynamic>),
    );

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
    Provider<LocalAdapter<House>>((ref) => $HouseHiveLocalAdapter(ref.read));

final housesRemoteAdapterProvider = Provider<RemoteAdapter<House>>((ref) =>
    $HouseRemoteAdapter(
        ref.watch(housesLocalAdapterProvider), houseProvider, housesProvider));

final housesRepositoryProvider =
    Provider<Repository<House>>((ref) => Repository<House>(ref.read));

final _houseProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<House?>, DataState<House?>, WatchArgs<House>>(
        (ref, args) {
  return ref.watch(housesRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<House?>, DataState<House?>>
    houseProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<House>? alsoWatch}) {
  return _houseProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _housesProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<House>>,
    DataState<List<House>>,
    WatchArgs<House>>((ref, args) {
  return ref.watch(housesRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<House>>,
        DataState<List<House>>>
    housesProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _housesProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

extension HouseDataX on House {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  House init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(housesRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension HouseDataRepositoryX on Repository<House> {}
