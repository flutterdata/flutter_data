// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Family _$FamilyFromJson(Map<String, dynamic> json) => Family(
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

Map<String, dynamic> _$FamilyToJson(Family instance) {
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

mixin $FamilyLocalAdapter on LocalAdapter<Family> {
  @override
  Map<String, Map<String, Object?>> relationshipsFor([Family? model]) => {
        'persons': {
          'name': 'persons',
          'inverse': 'family',
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
  Family deserialize(map) {
    for (final key in relationshipsFor().keys) {
      map[key] = {
        '_': [map[key], !map.containsKey(key)],
      };
    }
    return _$FamilyFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model) => _$FamilyToJson(model);
}

// ignore: must_be_immutable
class $FamilyHiveLocalAdapter = HiveLocalAdapter<Family>
    with $FamilyLocalAdapter;

class $FamilyRemoteAdapter = RemoteAdapter<Family> with NothingMixin;

//

final familiesRemoteAdapterProvider = Provider<RemoteAdapter<Family>>((ref) =>
    $FamilyRemoteAdapter(
        $FamilyHiveLocalAdapter(ref.read), familyProvider, familiesProvider));

final familiesRepositoryProvider =
    Provider<Repository<Family>>((ref) => Repository<Family>(ref.read));

final _familyProvider = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Family?>, DataState<Family?>, WatchArgs<Family>>(
        (ref, args) {
  final adapter = ref.watch(familiesRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersOne[args.watcher] ?? adapter.watchOneNotifier;
  return notifier(args.id!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Family?>, DataState<Family?>>
    familyProvider(Object? id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Family>? alsoWatch,
        String? finder,
        String? watcher}) {
  return _familyProvider(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      watcher: watcher));
}

final _familiesProvider = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Family>>,
    DataState<List<Family>>,
    WatchArgs<Family>>((ref, args) {
  final adapter = ref.watch(familiesRemoteAdapterProvider);
  final notifier =
      adapter.strategies.watchersAll[args.watcher] ?? adapter.watchAllNotifier;
  return notifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Family>>,
        DataState<List<Family>>>
    familiesProvider(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool? syncLocal,
        String? finder,
        String? watcher}) {
  return _familiesProvider(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      watcher: watcher));
}

extension FamilyDataX on Family {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `ref.read`, `container.read`
  Family init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(familiesRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}

extension FamilyDataRepositoryX on Repository<Family> {}
