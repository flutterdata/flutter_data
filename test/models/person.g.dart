// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable
// ignore_for_file: always_declare_return_types
mixin _$PersonModelAdapter on Repository<Person> {
  @override
  Map<String, Relationship> relationshipsFor(Person model) =>
      {'family': model?.family};

  @override
  Map<String, Repository> get relationshipRepositories =>
      {'families': manager.locator<Repository<Family>>()};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipsFor(null).keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key), manager]
      };
    }
    return Person.fromJson(map);
  }

  @override
  localSerialize(model) {
    final map = model.toJson();
    for (var e in relationshipsFor(model).entries) {
      map[e.key] = e.value?.toJson();
    }
    return map;
  }
}

class $PersonRepository = Repository<Person>
    with
        _$PersonModelAdapter,
        RemoteAdapter<Person>,
        WatchAdapter<Person>,
        PersonLoginAdapter;
