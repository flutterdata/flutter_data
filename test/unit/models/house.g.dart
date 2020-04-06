// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$HouseRepository extends Repository<House> {
  _$HouseRepository(LocalAdapter<House> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {'families': 'families'},
        'BelongsTo': {},
        'repository#families': manager.locator<Repository<Family>>()
      };

  @override
  setOwnerInRelationships(owner, model) {
    model.families?.owner = owner;
  }

  @override
  void setOwnerInModel(owner, model) {
    if (owner is DataId<Family>) {
      model.families?.owner = owner;
    }
  }
}

class $HouseRepository extends _$HouseRepository {
  $HouseRepository(LocalAdapter<House> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $HouseLocalAdapter extends LocalAdapter<House> {
  $HouseLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    map['families'] = {
      '_': [map['families'], manager]
    };

    manager.dataId<House>(map.id, key: key);
    return House.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();
    map['families'] = model.families?.keys;

    return map;
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) {
  return House(
    id: json['id'] as String,
    address: json['address'] as String,
    families: json['families'] == null
        ? null
        : HasMany.fromJson(json['families'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$HouseToJson(House instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'families': instance.families,
    };
