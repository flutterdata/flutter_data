// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$FamilyModelAdapter on Repository<Family> {
  @override
  Map<String, Map<String, Object>> relationshipsFor(Family model) => {
        'persons': {'type': 'people', 'instance': model?.persons},
        'dogs': {'type': 'dogs', 'instance': model?.dogs},
        'dacha': {'type': 'houses', 'instance': model?.dacha},
        'residence': {'type': 'houses', 'instance': model?.residence}
      };

  @override
  Map<String, Repository> get relatedRepositories => {
        'people': manager.locator<Repository<Person>>(),
        'dogs': manager.locator<Repository<Dog>>(),
        'houses': manager.locator<Repository<House>>()
      };

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipNames) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$FamilyFromJson(map);
  }

  @override
  localSerialize(model) {
    final map = _$FamilyToJson(model);
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
    }
    return map;
  }
}

class $FamilyRepository = Repository<Family>
    with _$FamilyModelAdapter, RemoteAdapter<Family>, WatchAdapter<Family>;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) {
  return Family(
    id: json['id'] as String,
    surname: json['surname'] as String,
    persons: json['persons'] == null
        ? null
        : HasMany.fromJson(json['persons'] as Map<String, dynamic>),
    dacha: json['dacha'] == null
        ? null
        : BelongsTo.fromJson(json['dacha'] as Map<String, dynamic>),
    residence: json['residence'] == null
        ? null
        : BelongsTo.fromJson(json['residence'] as Map<String, dynamic>),
    dogs: json['dogs'] == null
        ? null
        : HasMany.fromJson(json['dogs'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'surname': instance.surname,
      'persons': instance.persons?.toJson(),
      'dacha': instance.dacha?.toJson(),
      'residence': instance.residence?.toJson(),
      'dogs': instance.dogs?.toJson(),
    };
