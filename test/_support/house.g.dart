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

final houseLocalAdapterProvider = RiverpodAlias.provider<LocalAdapter<House>>(
    (ref) => $HouseHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final houseRemoteAdapterProvider = RiverpodAlias.provider<RemoteAdapter<House>>(
    (ref) => $HouseRemoteAdapter(ref.read(houseLocalAdapterProvider)));

final houseRepositoryProvider =
    RiverpodAlias.provider<Repository<House>>((_) => Repository<House>());

extension HouseX on House {
  House init(owner) {
    return internalLocatorFn(houseRepositoryProvider, owner)
        .internalAdapter
        .initializeModel(this, save: true) as House;
  }
}
