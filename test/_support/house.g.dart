// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) {
  return House(
    id: json['id'] as String,
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
  Map<String, Map<String, Object>> relationshipsFor([House model]) => {
        'owner': {
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

final houseLocalAdapterProvider =
    Provider<LocalAdapter<House>>((ref) => $HouseHiveLocalAdapter(ref));

final houseRemoteAdapterProvider = Provider<RemoteAdapter<House>>(
    (ref) => $HouseRemoteAdapter(ref.read(houseLocalAdapterProvider)));

final houseRepositoryProvider =
    Provider<Repository<House>>((ref) => Repository<House>(ref));

final _watchHouse = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<House>, WatchArgs<House>>((ref, args) {
  return ref.watch(houseRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierStateProvider<DataState<House>> watchHouse(dynamic id,
    {bool remote = true,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    AlsoWatch<House> alsoWatch}) {
  return _watchHouse(WatchArgs(
          id: id,
          remote: remote,
          params: params,
          headers: headers,
          alsoWatch: alsoWatch))
      .state;
}

final _watchHouses = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<List<House>>, WatchArgs<House>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(houseRepositoryProvider).watchAll(
      remote: args.remote, params: args.params, headers: args.headers);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<House>>> watchHouses(
    {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
  return _watchHouses(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension HouseX on House {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Pass:
  ///  - A `BuildContext` if using Flutter with Riverpod or Provider
  ///  - Nothing if using Flutter with GetIt
  ///  - A Riverpod `ProviderContainer` if using pure Dart
  ///  - Its own [Repository<House>]
  House init(container) {
    final repository = container is Repository<House>
        ? container
        : internalLocatorFn(houseRepositoryProvider, container);
    return repository.internalAdapter.initializeModel(this, save: true)
        as House;
  }
}
