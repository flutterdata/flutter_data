// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

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
  Person deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return Person.fromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => model.toJson();
}

// ignore: must_be_immutable
class $PersonHiveLocalAdapter = HiveLocalAdapter<Person>
    with $PersonLocalAdapter;

class $PersonRemoteAdapter = RemoteAdapter<Person>
    with
        PersonLoginAdapter,
        GenericDoesNothingAdapter<Person>,
        YetAnotherLoginAdapter;

//

final personLocalAdapterProvider = Provider<LocalAdapter<Person>>((ref) =>
    $PersonHiveLocalAdapter(
        ref.read(hiveLocalStorageProvider), ref.read(graphProvider)));

final personRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(ref.read(personLocalAdapterProvider)));

final personRepositoryProvider =
    Provider<Repository<Person>>((_) => Repository<Person>());

extension PersonX on Person {
  Person init(owner) {
    return internalLocatorFn(personRepositoryProvider, owner)
        .internalAdapter
        .initializeModel(this, save: true) as Person;
  }
}

extension PersonRepositoryX on Repository<Person> {
  Future<String> login(String email, String password) =>
      (internalAdapter as YetAnotherLoginAdapter).login(email, password);
  Future<Person> doNothing(Person model, int n) =>
      (internalAdapter as GenericDoesNothingAdapter<Person>)
          .doNothing(model, n);
}
