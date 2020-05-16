// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$FamilyModelAdapter on Repository<Family> {
  @override
  Map<String, Relationship> relationshipsFor(Family model) =>
      {'persons': model?.persons, 'dogs': model?.dogs, 'house': model?.house};

  @override
  Map<String, Repository> get relationshipRepositories => {
        'people': manager.locator<Repository<Person>>(),
        'dogs': manager.locator<Repository<Dog>>(),
        'houses': manager.locator<Repository<House>>()
      };

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return _$FamilyFromJson(map).._meta.addAll(metadata ?? const {});
  }

  @override
  localSerialize(model) {
    final map = _$FamilyToJson(model);
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

extension FamilyFDX on Family {
  Map<String, dynamic> get _meta => flutterDataMetadata;
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
