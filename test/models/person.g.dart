// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$PersonModelAdapter on Repository<Person> {
  @override
  get relationshipMetadata => {
        'HasMany': {},
        'BelongsTo': {'family': 'families'}
      };

  @override
  Repository repositoryFor(String type) {
    return <String, Repository>{
      'families': manager.locator<Repository<Family>>()
    }[type];
  }

  @override
  localDeserialize(map) {
    map['family'] = {
      '_': [map['family'], manager]
    };
    return Person.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
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

class $PersonRepository = Repository<Person>
    with
        _$PersonModelAdapter,
        RemoteAdapter<Person>,
        WatchAdapter<Person>,
        PersonLoginAdapter;
