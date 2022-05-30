// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $HouseLocalAdapter on LocalAdapter<House> {
  static final Map<String, FieldMeta> _kHouseFieldMetas = {
    'address': AttributeMeta<House>(
      name: 'address',
      type: 'String',
      nullable: false,
      internalType: 'String',
    ),
    'currentLibrary': RelationshipMeta<Book>(
      name: 'currentLibrary',
      inverseName: 'house',
      type: 'books',
      kind: 'HasMany',
      serialize: false,
      instance: (_) => (_ as House).currentLibrary,
    ),
    'owner': RelationshipMeta<Familia>(
      name: 'owner',
      inverseName: 'residence',
      type: 'familia',
      kind: 'BelongsTo',
      instance: (_) => (_ as House).owner,
    )
  };

  @override
  Map<String, FieldMeta> get fieldMetas => _kHouseFieldMetas;

  @override
  House deserialize(map) {
    map = transformDeserialize(map);
    return _$HouseFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$HouseToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _housesFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $HouseIsarLocalAdapter = IsarLocalAdapter<House> with $HouseLocalAdapter;

class $HouseRemoteAdapter = RemoteAdapter<House> with NothingMixin;

final internalHousesRemoteAdapterProvider = Provider<RemoteAdapter<House>>(
    (ref) => $HouseRemoteAdapter(
        $HouseIsarLocalAdapter(ref.read), InternalHolder(_housesFinders)));

final housesRepositoryProvider =
    Provider<Repository<House>>((ref) => Repository<House>(ref.read));

extension HouseDataRepositoryX on Repository<House> {}

extension HouseRelationshipGraphNodeX on RelationshipGraphNode<House> {
  RelationshipGraphNode<Book> get currentLibrary {
    final meta = $HouseLocalAdapter._kHouseFieldMetas['currentLibrary']
        as RelationshipMeta<Book>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Familia> get owner {
    final meta = $HouseLocalAdapter._kHouseFieldMetas['owner']
        as RelationshipMeta<Familia>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

House _$HouseFromJson(Map<String, dynamic> json) => House(
      id: json['id'] as String?,
      address: json['address'] as String,
      owner: json['owner'] == null
          ? null
          : BelongsTo<Familia>.fromJson(json['owner'] as Map<String, dynamic>),
      currentLibrary: json['currentLibrary'] == null
          ? null
          : HasMany<Book>.fromJson(
              json['currentLibrary'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HouseToJson(House instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'owner': instance.owner,
      'currentLibrary': instance.currentLibrary,
    };
