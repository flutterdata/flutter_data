// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'familia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Familia _$FamiliaFromJson(Map<String, dynamic> json) => Familia(
      id: json['id'] as String?,
      surname: json['surname'] as String,
      persons: json['persons'] == null
          ? null
          : HasMany<Person>.fromJson(json['persons'] as Map<String, dynamic>),
      cottage: json['cottage'] == null
          ? null
          : BelongsTo<House>.fromJson(json['cottage'] as Map<String, dynamic>),
      residence: json['residence'] == null
          ? null
          : BelongsTo<House>.fromJson(
              json['residence'] as Map<String, dynamic>),
      dogs: json['dogs'] == null
          ? null
          : HasMany<Dog>.fromJson(json['dogs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FamiliaToJson(Familia instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['surname'] = instance.surname;
  val['persons'] = instance.persons.toJson();
  writeNotNull('cottage', instance.cottage?.toJson());
  writeNotNull('residence', instance.residence?.toJson());
  writeNotNull('dogs', instance.dogs?.toJson());
  return val;
}

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, non_constant_identifier_names

mixin $FamiliaLocalAdapter on LocalAdapter<Familia> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Familia? model]) => {
        'persons': {
          'name': 'persons',
          'inverse': 'familia',
          'type': 'people',
          'kind': 'HasMany',
          'instance': model?.persons
        },
        'cottage': {
          'name': 'cottage',
          'inverse': 'owner',
          'type': 'houses',
          'kind': 'BelongsTo',
          'instance': model?.cottage
        },
        'residence': {
          'name': 'residence',
          'inverse': 'owner',
          'type': 'houses',
          'kind': 'BelongsTo',
          'instance': model?.residence
        },
        'dogs': {
          'name': 'dogs',
          'type': 'dogs',
          'kind': 'HasMany',
          'instance': model?.dogs
        }
      };

  @override
  Familia deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$FamiliaFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$FamiliaToJson(model);
}

// ignore: must_be_immutable
class $FamiliaHiveLocalAdapter = HiveLocalAdapter<Familia>
    with $FamiliaLocalAdapter;

class $FamiliaRemoteAdapter = RemoteAdapter<Familia> with NothingMixin;

final _familiaStrategies = <String, dynamic>{};

//

final familiaRemoteAdapterProvider = Provider<RemoteAdapter<Familia>>((ref) =>
    $FamiliaRemoteAdapter($FamiliaHiveLocalAdapter(ref.read),
        InternalHolder(familiumProvider, familiaProvider, _familiaStrategies)));

final familiaRepositoryProvider =
    Provider<Repository<Familia>>((ref) => Repository<Familia>(ref.read));

final _familiumProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<Familia?>,
    DataState<Familia?>,
    WatchArgs<Familia>>((ref, args) {
  final adapter = ref.watch(familiaRemoteAdapterProvider);
  final _watcherStrategy = _familiaStrategies[args.watcher]?.call(adapter);
  final notifier = _watcherStrategy is DataWatcherOne<Familia>
      ? _watcherStrategy as DataWatcherOne<Familia>
      : adapter.watchOneNotifier;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Familia?>,
        DataState<Familia?>>
    familiumProvider(Object? id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Familia>? alsoWatch,
        String? finder,
        String? watcher}) {
  return _familiumProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher));
}

final _familiaProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Familia>?>,
    DataState<List<Familia>?>,
    WatchArgs<Familia>>((ref, args) {
  final adapter = ref.watch(familiaRemoteAdapterProvider);
  final _watcherStrategy = _familiaStrategies[args.watcher]?.call(adapter);
  final notifier = _watcherStrategy is DataWatcherAll<Familia>
      ? _watcherStrategy as DataWatcherAll<Familia>
      : adapter.watchAllNotifier;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Familia>?>,
        DataState<List<Familia>?>>
    familiaProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal,
        String? finder,
        String? watcher}) {
  return _familiaProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher));
}

extension FamiliaDataX on Familia {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Familia init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(familiaRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension FamiliaDataRepositoryX on Repository<Familia> {}
