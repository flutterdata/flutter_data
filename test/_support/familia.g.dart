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

final _familiaFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $FamiliaHiveLocalAdapter = HiveLocalAdapter<Familia>
    with $FamiliaLocalAdapter;

class $FamiliaRemoteAdapter = RemoteAdapter<Familia> with NothingMixin;

final familiaRemoteAdapterProvider = Provider<RemoteAdapter<Familia>>((ref) =>
    $FamiliaRemoteAdapter(
        $FamiliaHiveLocalAdapter(ref.read), InternalHolder(_familiaFinders)));

final familiaRepositoryProvider =
    Provider<Repository<Familia>>((ref) => Repository<Familia>(ref.read));

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
