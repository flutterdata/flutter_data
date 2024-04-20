// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'house.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin _$HouseAdapter on Adapter<House> {
  static final Map<String, RelationshipMeta> _kHouseRelationshipMetas = {
    'owner': RelationshipMeta<Familia>(
      name: 'owner',
      inverseName: 'residence',
      type: 'familia',
      kind: 'BelongsTo',
      instance: (_) => (_ as House).owner,
    ),
    'currentLibrary': RelationshipMeta<Book>(
      name: 'currentLibrary',
      inverseName: 'house',
      type: 'books',
      kind: 'HasMany',
      serialize: false,
      instance: (_) => (_ as House).currentLibrary,
    ),
    'house': RelationshipMeta<House>(
      name: 'house',
      inverseName: 'house',
      type: 'houses',
      kind: 'BelongsTo',
      serialize: false,
      instance: (_) => (_ as House).house,
    )
  };

  @override
  Map<String, RelationshipMeta> get relationshipMetas =>
      _kHouseRelationshipMetas;

  @override
  House deserialize(map, {String? key}) {
    map = transformDeserialize(map);
    return internalWrapStopInit(() => _$HouseFromJson(map), key: key);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$HouseToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _housesFinders = <String, dynamic>{};

class $HouseAdapter = Adapter<House> with _$HouseAdapter, NothingMixin;

final housesAdapterProvider = Provider<Adapter<House>>(
    (ref) => $HouseAdapter(ref, InternalHolder(_housesFinders)));

extension HouseAdapterX on Adapter<House> {}

extension HouseRelationshipGraphNodeX on RelationshipGraphNode<House> {
  RelationshipGraphNode<Familia> get owner {
    final meta = _$HouseAdapter._kHouseRelationshipMetas['owner']
        as RelationshipMeta<Familia>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<Book> get currentLibrary {
    final meta = _$HouseAdapter._kHouseRelationshipMetas['currentLibrary']
        as RelationshipMeta<Book>;
    return meta.clone(
        parent: this is RelationshipMeta ? this as RelationshipMeta : null);
  }

  RelationshipGraphNode<House> get house {
    final meta = _$HouseAdapter._kHouseRelationshipMetas['house']
        as RelationshipMeta<House>;
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
    )..house = BelongsTo<House>.fromJson(json['house'] as Map<String, dynamic>);

Map<String, dynamic> _$HouseToJson(House instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'owner': instance.owner,
      'currentLibrary': instance.currentLibrary,
      'house': instance.house,
    };
