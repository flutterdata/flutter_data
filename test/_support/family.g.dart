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

Map<String, dynamic> _$FamilyToJson(Family instance) => <String, dynamic>{
      'id': instance.id,
      'surname': instance.surname,
      'persons': instance.persons?.toJson(),
      'cottage': instance.cottage?.toJson(),
      'residence': instance.residence?.toJson(),
      'dogs': instance.dogs?.toJson(),
    };

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

final familiesLocalAdapterProvider =
    Provider<LocalAdapter<Family>>((ref) => $FamilyHiveLocalAdapter(ref.read));

final familiesRemoteAdapterProvider = Provider<RemoteAdapter<Family>>(
    (ref) => $FamilyRemoteAdapter(ref.watch(familiesLocalAdapterProvider)));

final familiesRepositoryProvider =
    Provider<Repository<Family>>((ref) => Repository<Family>(ref.read));

final _watchFamily = StateNotifierProvider.autoDispose
    .family<DataStateNotifier<Family?>, DataState<Family?>, WatchArgs<Family>>(
        (ref, args) {
  return ref.watch(familiesRepositoryProvider).watchOne(args.id,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<Family?>, DataState<Family?>>
    watchFamily(dynamic id,
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        AlsoWatch<Family>? alsoWatch}) {
  return _watchFamily(WatchArgs(
      id: id,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch));
}

final _watchFamilies = StateNotifierProvider.autoDispose.family<
    DataStateNotifier<List<Family>>,
    DataState<List<Family>>,
    WatchArgs<Family>>((ref, args) {
  ref.maintainState = false;
  return ref.watch(familiesRepositoryProvider).watchAll(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      filterLocal: args.filterLocal,
      syncLocal: args.syncLocal);
});

AutoDisposeStateNotifierProvider<DataStateNotifier<List<Family>>,
        DataState<List<Family>>>
    watchFamilies(
        {bool? remote,
        Map<String, dynamic>? params,
        Map<String, String>? headers,
        bool Function(Family)? filterLocal,
        bool? syncLocal}) {
  return _watchFamilies(WatchArgs(
      remote: remote,
      params: params,
      headers: headers,
      filterLocal: filterLocal,
      syncLocal: syncLocal));
}

extension FamilyX on Family {
  /// Initializes "fresh" models (i.e. manually instantiated) to use
  /// [save], [delete] and so on.
  ///
  /// Can be obtained via `context.read`, `ref.read`, `container.read`
  Family init(Reader read, {bool save = true}) {
    final repository = internalLocatorFn(familiesRepositoryProvider, read);
    final updatedModel =
        repository.remoteAdapter.initializeModel(this, save: save);
    return save ? updatedModel : this;
  }
}
