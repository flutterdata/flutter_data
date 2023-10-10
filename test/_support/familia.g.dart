// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'familia.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $FamiliaLocalAdapter on LocalAdapter<Familia> {
  static final Map<String, RelationshipMeta> _kFamiliaRelationshipMetas = {
    'persons': RelationshipMeta<Person>(
      name: 'persons',
      inverseName: 'familia',
      type: 'people',
      kind: 'HasMany',
      instance: (_) => (_ as Familia).persons,
    ),
    'cottage_id': RelationshipMeta<House>(
      name: 'cottage',
      inverseName: 'owner',
      type: 'houses',
      kind: 'BelongsTo',
      instance: (_) => (_ as Familia).cottage,
    ),
    'residence': RelationshipMeta<House>(
      name: 'residence',
      inverseName: 'owner',
      type: 'houses',
      kind: 'BelongsTo',
      instance: (_) => (_ as Familia).residence,
    ),
    'dogs': RelationshipMeta<Dog>(
      name: 'dogs',
      type: 'dogs',
      kind: 'HasMany',
      instance: (_) => (_ as Familia).dogs,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kFamiliaRelationshipMetas;

  @override
  Familia deserialize(map) {
    map = transformDeserialize(map);
    return _$FamiliaFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$FamiliaToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _familiaFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $FamiliaIsarLocalAdapter = IsarLocalAdapter<Familia>
    with $FamiliaLocalAdapter;

class $FamiliaRemoteAdapter = RemoteAdapter<Familia> with NothingMixin;

final internalFamiliaRemoteAdapterProvider = Provider<RemoteAdapter<Familia>>(
    (ref) => $FamiliaRemoteAdapter(
        $FamiliaIsarLocalAdapter(ref), InternalHolder(_familiaFinders)));

final familiaRepositoryProvider =
    Provider<Repository<Familia>>((ref) => Repository<Familia>(ref));

extension FamiliaDataRepositoryX on Repository<Familia> {}

extension FamiliaRelationshipGraphNodeX on RelationshipGraphNode<Familia> {
  RelationshipGraphNode<Person> get persons {
    final meta = $FamiliaLocalAdapter._kFamiliaRelationshipMetas['persons']
        as RelationshipMeta<Person>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<House> get cottage {
    final meta = $FamiliaLocalAdapter._kFamiliaRelationshipMetas['cottage_id']
        as RelationshipMeta<House>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<House> get residence {
    final meta = $FamiliaLocalAdapter._kFamiliaRelationshipMetas['residence']
        as RelationshipMeta<House>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Dog> get dogs {
    final meta = $FamiliaLocalAdapter._kFamiliaRelationshipMetas['dogs']
        as RelationshipMeta<Dog>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Familia _$FamiliaFromJson(Map<String, dynamic> json) => Familia(
      id: json['id'] as String?,
      surname: json['surname'] as String,
      persons: json['persons'] == null
          ? null
          : HasMany<Person>.fromJson(json['persons'] as Map<String, dynamic>),
      cottage: json['cottage_id'] == null
          ? null
          : BelongsTo<House>.fromJson(
              json['cottage_id'] as Map<String, dynamic>),
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
  val['cottage_id'] = instance.cottage.toJson();
  val['residence'] = instance.residence.toJson();
  writeNotNull('dogs', instance.dogs?.toJson());
  return val;
}
