// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
class _$PersonRepository extends Repository<Person> {
  _$PersonRepository(LocalAdapter<Person> adapter) : super(adapter);

  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'family': 'families'},
        'repository#families': manager.locator<Repository<Family>>()
      };
}

class $PersonRepository extends _$PersonRepository
    with PersonPollAdapter<Person> {
  $PersonRepository(LocalAdapter<Person> adapter) : super(adapter);
}

// ignore: must_be_immutable, unused_local_variable
class $PersonLocalAdapter extends LocalAdapter<Person> {
  $PersonLocalAdapter(DataManager manager, {box}) : super(manager, box: box);

  @override
  deserialize(map) {
    map['family'] = {
      '_': [map['family'], manager]
    };
    return Person.fromJson(map);
  }

  @override
  serialize(model) {
    final map = _$PersonToJson(model);
    map['family'] = model.family?.toJson();
    return map;
  }

  @override
  setOwnerInRelationships(owner, model) {
    model.family?.owner = owner;
  }

  @override
  void setInverseInModel(inverse, model) {
    if (inverse is DataId<Family>) {
      model.family?.inverse = inverse;
    }
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
