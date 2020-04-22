// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$FamilyRepository extends Repository<Family> {
  _$FamilyRepository(LocalAdapter<Family> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {'persons': 'people', 'dogs': 'dogs'},
        'BelongsTo': {'house': 'houses'},
        'repository#people': manager.locator<Repository<Person>>(),
        'repository#dogs': manager.locator<Repository<Dog>>(),
        'repository#houses': manager.locator<Repository<House>>()
      };
}

class $FamilyRepository extends _$FamilyRepository {
  $FamilyRepository(LocalAdapter<Family> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $FamilyLocalAdapter extends LocalAdapter<Family> {
  $FamilyLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    map['persons'] = {
      '_': [map['persons'], manager]
    };
    map['dogs'] = {
      '_': [map['dogs'], manager]
    };
    map['house'] = {
      '_': [map['house'], manager]
    };
    return _$FamilyFromJson(map);
  }

  @override
  serialize(model) {
    final map = _$FamilyToJson(model);
    map['persons'] = model.persons?.toJson();
    map['dogs'] = model.dogs?.toJson();
    map['house'] = model.house?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.persons?.owner = owner;
    model.dogs?.owner = owner;
    model.house?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Person>) {
      model.persons?.inverse = inverse;
    }
    if (inverse is DataId<Dog>) {
      model.dogs?.inverse = inverse;
    }
    if (inverse is DataId<House>) {
      model.house?.inverse = inverse;
    }
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
    dogs: json['dogs'] == null
        ? null
        : HasMany.fromJson(json['dogs'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'surname': instance.surname,
      'house': instance.house?.toJson(),
      'persons': instance.persons?.toJson(),
      'dogs': instance.dogs?.toJson(),
    };
