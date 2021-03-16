// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $PersonLocalAdapter on LocalAdapter<Person> {
  @override
  Map<String, Map<String, Object>> relationshipsFor([Person model]) => {
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

final personLocalAdapterProvider =
    Provider<LocalAdapter<Person>>((ref) => $PersonHiveLocalAdapter(ref));

final personRemoteAdapterProvider = Provider<RemoteAdapter<Person>>(
    (ref) => $PersonRemoteAdapter(ref.read(personLocalAdapterProvider)));

final personRepositoryProvider =
    Provider<Repository<Person>>((ref) => Repository<Person>(ref));

final _watchPerson = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Person>, WatchArgs<Person>>((ref, args) {
  return ref.watch(personRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Person>> watchPerson(
    dynamic id,
    {bool remote = true,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    AlsoWatch<Person> alsoWatch}) {
  return _watchPerson(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchPeople = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<List<Person>>, WatchArgs<Person>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(personRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Person>>> watchPeople(
    {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
  return _watchPeople(
      WatchArgs(remote: remote, params: params, headers: headers));
}

extension PersonX on Person {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Requires a reader of type `Repository<Person> read(ProviderBase<Object, Repository<Person>> _)` (unless using GetIt).
  ///
  /// If needed, obtain it with:
  ///  - `context.read` if using Flutter with Riverpod or Provider
  ///  - `ref.read` or `container.read` if using Riverpod
  Person init(
      Repository<Person> read(ProviderBase<Object, Repository<Person>> _)) {
    final repository = internalLocatorFn(personRepositoryProvider, read);
    return repository.remoteAdapter.initializeModel(this, save: true) as Person;
  }
}
