// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: unused_local_variable, always_declare_return_types, non_constant_identifier_names, invalid_use_of_protected_member

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Person model]) => {
        'family': {
          'inverse': 'persons',
          'type': 'families',
          'kind': 'BelongsTo',
          'instance': model?.family
        }
      };

  @override
  deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Person.fromJson(map);
  }

  @override
  serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $PersonHiveLocalAdapter = HiveLocalAdapter<Person>
    with $PersonLocalAdapter;

class $PersonRemoteAdapter = RemoteAdapter<Person> with PersonLoginAdapter;

//

final peopleLocalAdapterProvider = Provider<LocalAdapter<Person>>((ref) =>
    $PersonHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final peopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(ref.read(peopleLocalAdapterProvider)));

final peopleRepositoryProvider =
    Provider<Repository<Person>>((_) => Repository<Person>());

extension PersonX on Person {
  Person init([owner]) {
    if (owner == null && debugGlobalServiceLocatorInstance != null) {
      return debugInit(
          debugGlobalServiceLocatorInstance.get<Repository<Person>>());
    }
    return debugInit(owner.ref.read(peopleRepositoryProvider));
  }
}

extension PersonRepositoryX on Repository<Person> {
  Future<String> login(String email, String password) =>
      (adapter as PersonLoginAdapter).login(email, password);
}
