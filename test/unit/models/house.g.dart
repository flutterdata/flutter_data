// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$HouseRepository extends Repository<House> {
  _$HouseRepository(LocalAdapter<House> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);

  @override
  get relationshipMetadata => {
        'HasMany': {'families': 'families'},
        'BelongsTo': {}
      };

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{
      'families': manager.locator<Repository<Family>>()
    }[type];
  }
}

class $HouseRepository extends _$HouseRepository {
  $HouseRepository(LocalAdapter<House> adapter, {bool remote, bool verbose})
      : super(adapter, remote: remote, verbose: verbose);
}

// ignore: must_be_immutable, unused_local_variable
class $HouseLocalAdapter extends LocalAdapter<House> {
  $HouseLocalAdapter(DataManager manager, {List<int> encryptionKey, box})
      : super(manager, encryptionKey: encryptionKey, box: box);

  @override
  deserialize(map) {
    map['families'] = {
      '_': [map['families'], manager]
    };
    return _$HouseFromJson(map);
  }

  @override
  serialize(model) {
    final map = _$HouseToJson(model);
    map['families'] = model.families?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.families?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Family>) {
      model.families?.inverse = inverse;
    }
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
