// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$HouseRepository extends Repository<House> {
  _$HouseRepository(LocalAdapter<House> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => {
        "HasMany": {"families": "families"},
        "BelongsTo": {}
      };

  @override
  House internalDeserialize(obj, {withKey, included}) {
    var map = <String, dynamic>{...?obj?.relationships};

    map['families'] = {
      'HasMany': HasMany<Family>.fromToMany(
          map['families'], localAdapter.manager,
          included: included)
    };

    var dataId = DataId<House>(obj.id, localAdapter.manager, key: withKey);
    return House.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize(House model) {
    var relationships = {
      'families': model.families?.toMany,
    };

    final map = model.toJson();
    final dataId = DataId<House>(model.id, localAdapter.manager);

    map.remove('id');
    map.remove('families');

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: relationships,
    );
  }

  @override
  void setOwnerInRelationships(DataId<House> owner, House model) {
    assertRel(model.families, 'families', 'HasMany<Family>');
    model.families.owner = owner;
  }

  @override
  void setOwnerInModel(DataId owner, House model) {
    if (owner is DataId<Family>) {
      assertRel(model.families, 'families', 'HasMany<Family>');
      model.families.owner = owner;
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
  House internalLocalDeserialize(map) {
    map = fixMap(map);

    map['families'] = {
      'HasMany': HasMany<Family>.fromKeys(map['families'], manager)
    };

    return House.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize(House model) {
    var map = model.toJson();
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
