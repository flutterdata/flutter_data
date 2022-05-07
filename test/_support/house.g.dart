// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

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
          'type': 'familia',
          'kind': 'BelongsTo',
          'instance': model?.owner
        },
        'currentLibrary': {
          'name': 'currentLibrary',
          'inverse': 'house',
          'type': 'books',
          'kind': 'HasMany',
          'instance': model?.currentLibrary,
          'serialize': 'false'
        },
        'house': {
          'name': 'house',
          'inverse': 'house',
          'type': 'houses',
          'kind': 'BelongsTo',
          'instance': model?.house,
          'serialize': 'false'
        }
      };

  @override
  House deserialize(map) {
    map = transformDeserialize(map);
    return _$HouseFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$HouseToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _housesFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $HouseHiveLocalAdapter = HiveLocalAdapter<House> with $HouseLocalAdapter;

class $HouseRemoteAdapter = RemoteAdapter<House> with NothingMixin;

final internalHousesRemoteAdapterProvider = Provider<RemoteAdapter<House>>(
    (ref) => $HouseRemoteAdapter(
        $HouseHiveLocalAdapter(ref.read), InternalHolder(_housesFinders)));

final housesRepositoryProvider =
    Provider<Repository<House>>((ref) => Repository<House>(ref.read));

extension HouseDataRepositoryX on Repository<House> {}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) => House(
      id: json['id'] as String?,
      address: json['address'] as String,
      owner: json['owner'] == null
          ? null
          : BelongsTo<Familia>.fromJson(json['owner'] as Map<String, dynamic>),
      currentLibrary: json['currentLibrary'] == null
          ? null
          : HasMany<Book>.fromJson(
              json['currentLibrary'] as Map<String, dynamic>),
    )..house = BelongsTo<House>.fromJson(json['house'] as Map<String, dynamic>);

Map<String, dynamic> _$HouseToJson(House instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'owner': instance.owner,
      'currentLibrary': instance.currentLibrary,
      'house': instance.house,
    };
