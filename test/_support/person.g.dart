// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Person? model]) => {
        'familia': {
          'name': 'familia',
          'inverse': 'persons',
          'type': 'familia',
          'kind': 'BelongsTo',
          'instance': model?.familia
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

final peopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter($PersonHiveLocalAdapter(ref.read)));

final peopleRepositoryProvider =
    Provider<Repository<Person>>((ref) => Repository<Person>(ref.read));

extension PersonDataX on Person {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Person init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(peopleRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension PersonDataRepositoryX on Repository<Person> {
  PersonLoginAdapter get personLoginAdapter =>
      remoteAdapter as PersonLoginAdapter;
  GenericDoesNothingAdapter<Person> get genericDoesNothingAdapter =>
      remoteAdapter as GenericDoesNothingAdapter<Person>;
  YetAnotherLoginAdapter get yetAnotherLoginAdapter =>
      remoteAdapter as YetAnotherLoginAdapter;
}
