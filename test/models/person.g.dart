// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// DataGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names
mixin _$PersonModelAdapter on Repository<Person> {
  @override
  Map<String, Map<String, Object>> relationshipsFor(Person model) => {
        'family': {'type': 'families', 'instance': model?.family}
      };

  @override
  Map<String, Repository> get relatedRepositories =>
      {'families': manager.locator<Repository<Family>>()};

  @override
  localDeserialize(map, {metadata}) {
    for (var key in relationshipNames) {
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
      map[e.key] = (e.value['instance'] as Relationship)?.toJson();
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
