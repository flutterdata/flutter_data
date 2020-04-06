// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$PersonRepository extends Repository<Person> {
  _$PersonRepository(LocalAdapter<Person> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'family': 'families'},
        'repository#families': manager.locator<Repository<Family>>()
      };

  @override
  setOwnerInRelationships(owner, model) {
    model.family?.owner = owner;
  }

  @override
  void setOwnerInModel(owner, model) {
    if (owner is DataId<Family>) {
      model.family?.owner = owner;
    }
  }
}

class $PersonRepository extends _$PersonRepository {
  $PersonRepository(LocalAdapter<Person> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $PersonLocalAdapter extends LocalAdapter<Person> {
  $PersonLocalAdapter(box, DataManager manager) : super(box, manager);

  @override
  deserialize(map, {key}) {
    map['family'] = {
      '_': [map['family'], manager]
    };

    manager.dataId<Person>(map.id, key: key);
    return Person.fromJson(map);
  }

  @override
  serialize(model) {
    final map = model.toJson();

    map['family'] = model.family?.key;
    return map;
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) {
  return Person(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    family: json['family'] == null
        ? null
        : BelongsTo.fromJson(json['family'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'age': instance.age,
      'family': instance.family,
    };
