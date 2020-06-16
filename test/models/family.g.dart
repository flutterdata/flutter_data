// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$FamilyModelAdapter on Repository<Family> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Family model]) => {
        'persons': {
          'type': 'people',
          'kind': 'HasMany',
          'instance': model?.persons
        },
        'cottage': {
          'type': 'houses',
          'kind': 'BelongsTo',
          'instance': model?.cottage
        },
        'residence': {
          'type': 'houses',
          'kind': 'BelongsTo',
          'instance': model?.residence
        },
        'dogs': {'type': 'dogs', 'kind': 'HasMany', 'instance': model?.dogs}
      };

  @override
  Map<String, Repository> get relatedRepositories => {
        'people': manager.locator<Repository<Person>>(),
        'houses': manager.locator<Repository<House>>(),
        'dogs': manager.locator<Repository<Dog>>()
      };

  @override
  localDeserialize(map) {
    for (var key in relationshipsFor().keys) {
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
    cottage: json['cottage'] == null
        ? null
        : BelongsTo.fromJson(json['cottage'] as Map<String, dynamic>),
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
      'cottage': instance.cottage?.toJson(),
      'residence': instance.residence?.toJson(),
      'dogs': instance.dogs?.toJson(),
    };
