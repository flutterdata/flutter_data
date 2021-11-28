// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Person? model]) => {
        'family': {
          'name': 'family',
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

final peopleLocalAdapterProvider =
    Provider<LocalAdapter<Person>>((ref) => $PersonHiveLocalAdapter(ref.read));

final peopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(ref.watch(peopleLocalAdapterProvider)));

final peopleRepositoryProvider =
    Provider<Repository<Person>>((ref) => Repository<Person>(ref.read));

final _watchPerson = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Person?>, DataState<Person?>, WatchArgs<Person>>(
        (ref, args) {
  return ref.watch(peopleRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Person?>, DataState<Person?>>
    watchPerson(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Person>? alsoWatch}) {
  return _watchPerson(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchPeople = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Person>>,
    DataState<List<Person>>,
    WatchArgs<Person>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(peopleRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Person>>,
        DataState<List<Person>>>
    watchPeople(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(Person)? filterLocal,
        bool? syncLocal}) {
  return _watchPeople(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension PersonX on Person {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Person init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(peopleRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
