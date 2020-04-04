// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
class _$PersonRepository extends Repository<Person> {
  _$PersonRepository(LocalAdapter<Person> adapter) : super(adapter);

  @override
  Map<String, dynamic> get relationshipMetadata => {
        "HasMany": {},
        "BelongsTo": {"family": "families"}
      };

  @override
  void setOwnerInRelationships(DataId<Person> owner, Person model) {
    model.family?.owner = owner;
  }

  @override
  void setOwnerInModel(DataId owner, Person model) {
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
  deserialize(map, {key, included}) {
    map['family'] = {
      'BelongsTo':
          BelongsTo<Family>.fromKey(map['family'], manager, included: included)
    };

    manager.dataId<Person>(map.id, key: key);
    return Person.fromJson(map);
  }

  @override
  serialize(Person model) {
    return model.toJson();
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
