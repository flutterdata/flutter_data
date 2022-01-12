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

final peopleRemoteAdapterProvider = Provider<RemoteAdapter<Person>>((ref) =>
    $PersonRemoteAdapter(
        ref.watch(peopleLocalAdapterProvider), personProvider, peopleProvider));

final peopleRepositoryProvider =
    Provider<Repository<Person>>((ref) => Repository<Person>(ref.read));

final _personProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Person?>, DataState<Person?>, WatchArgs<Person>>(
        (ref, args) {
  return ref.watch(peopleRepositoryProvider).watchOneNotifier(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Person?>, DataState<Person?>>
    personProvider(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Person>? alsoWatch}) {
  return _personProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _peopleProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Person>>,
    DataState<List<Person>>,
    WatchArgs<Person>>((ref, args) {
  return ref.watch(peopleRepositoryProvider).watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Person>>,
        DataState<List<Person>>>
    peopleProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal}) {
  return _peopleProvider(WatchArgs(
      remote: remote, params: params, headers: headers, syncLocal: syncLocal));
}

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
