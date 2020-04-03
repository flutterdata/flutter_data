// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$FamilyRepository extends Repository<Family> {
  _$FamilyRepository(LocalAdapter<Family> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => {
        "HasMany": {"persons": "people"},
        "BelongsTo": {"house": "houses"}
      };

  @override
  Family internalDeserialize(obj, {withKey, included}) {
    var map = <String, dynamic>{...?obj?.relationships};

    map['persons'] = {
      'HasMany': HasMany<Person>.fromToMany(map['persons'], manager,
          included: included)
    };
    map['house'] = {
      'BelongsTo':
          BelongsTo<House>.fromToOne(map['house'], manager, included: included)
    };

    var dataId = manager.dataId<Family>(obj.id, key: withKey);
    return Family.fromJson({
      ...{'id': dataId.id},
      ...obj.attributes,
      ...map,
    });
  }

  @override
  internalSerialize(Family model) {
    var relationships = {
      'persons': model.persons?.toMany,
      'house': model.house?.toOne,
    };

    final map = model.toJson();
    final dataId = manager.dataId<Family>(model.id);

    map.remove('id');
    map.remove('persons');
    map.remove('house');

    return DataResourceObject(
      dataId.type,
      dataId.id,
      attributes: map,
      relationships: relationships,
    );
  }

  @override
  void setOwnerInRelationships(DataId<Family> owner, Family model) {
    model.persons?.owner = owner;
    model.house?.owner = owner;
  }

  @override
  void setOwnerInModel(DataId owner, Family model) {
    if (owner is DataId<Person>) {
      model.persons?.owner = owner;
    }
    if (owner is DataId<House>) {
      model.house?.owner = owner;
    }
  }
}

class $FamilyRepository extends _$FamilyRepository {
  $FamilyRepository(LocalAdapter<Family> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $FamilyLocalAdapter extends LocalAdapter<Family> {
  $FamilyLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  Family internalLocalDeserialize(map) {
    map = fixMap(map);

    map['persons'] = {
      'HasMany': HasMany<Person>.fromKeys(map['persons'], manager)
    };
    map['house'] = {
      'BelongsTo': BelongsTo<House>.fromKey(map['house'], manager)
    };

    return Family.fromJson(map);
  }

  @override
  Map<String, dynamic> internalLocalSerialize(Family model) {
    var map = model.toJson();
    map['persons'] = model.persons?.keys;
    map['house'] = model.house?.key;
    return map;
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) {
  return Family(
    id: json['id'] as String,
    surname: json['surname'] as String,
    house: json['house'] == null
        ? null
        : BelongsTo.fromJson(json['house'] as Map<String, dynamic>),
    persons: json['persons'] == null
        ? null
        : HasMany.fromJson(json['persons'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'surname': instance.surname,
      'house': instance.house,
      'persons': instance.persons,
    };
