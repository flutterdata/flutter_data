// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fruit.dart';

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, duplicate_ignore

mixin $FruitLocalAdapter on LocalAdapter<Fruit> {
  static final Map<String, FieldMeta> _kFruitFieldMetas = {
    'bigInt': AttributeMeta<Fruit>(
      name: 'bigInt',
      type: 'BigInt',
      nullable: false,
      internalType: 'String',
    ),
    'boolMap': AttributeMeta<Fruit>(
      name: 'boolMap',
      type: 'Map<String, bool>',
      nullable: false,
      internalType: 'Map',
    ),
    'boolean': AttributeMeta<Fruit>(
      name: 'boolean',
      type: 'bool',
      nullable: false,
      internalType: 'bool',
    ),
    'classification': AttributeMeta<Fruit>(
      name: 'classification',
      type: 'Classification',
      nullable: true,
      internalType: 'int',
    ),
    'classificationNoDefault': AttributeMeta<Fruit>(
      name: 'classificationNoDefault',
      type: 'Classification',
      nullable: true,
      internalType: 'int',
    ),
    'date': AttributeMeta<Fruit>(
      name: 'date',
      type: 'DateTime',
      nullable: false,
      internalType: 'String',
    ),
    'delimitedString': AttributeMeta<Fruit>(
      name: 'delimitedString',
      type: 'Set<String>',
      nullable: false,
      internalType: 'String',
    ),
    'duration': AttributeMeta<Fruit>(
      name: 'duration',
      type: 'Duration',
      nullable: false,
      internalType: 'int',
    ),
    'integer': AttributeMeta<Fruit>(
      name: 'integer',
      type: 'int',
      nullable: false,
      internalType: 'int',
    ),
    'iterable': AttributeMeta<Fruit>(
      name: 'iterable',
      type: 'Iterable',
      nullable: false,
      internalType: 'List',
    ),
    'listMaybeBoolean': AttributeMeta<Fruit>(
      name: 'listMaybeBoolean',
      type: 'List<bool>',
      nullable: true,
      internalType: 'List<bool>',
    ),
    'listMaybeDate': AttributeMeta<Fruit>(
      name: 'listMaybeDate',
      type: 'List<DateTime>',
      nullable: true,
      internalType: 'List',
    ),
    'listMaybeInteger': AttributeMeta<Fruit>(
      name: 'listMaybeInteger',
      type: 'List<int>',
      nullable: true,
      internalType: 'List<int>',
    ),
    'listMaybeString': AttributeMeta<Fruit>(
      name: 'listMaybeString',
      type: 'List<String>',
      nullable: true,
      internalType: 'List',
    ),
    'map': AttributeMeta<Fruit>(
      name: 'map',
      type: 'Map<String, dynamic>',
      nullable: false,
      internalType: 'Map',
    ),
    'maybeBoolean': AttributeMeta<Fruit>(
      name: 'maybeBoolean',
      type: 'bool',
      nullable: true,
      internalType: 'bool',
    ),
    'maybeDate': AttributeMeta<Fruit>(
      name: 'maybeDate',
      type: 'DateTime',
      nullable: true,
      internalType: 'String',
    ),
    'maybeInteger': AttributeMeta<Fruit>(
      name: 'maybeInteger',
      type: 'int',
      nullable: true,
      internalType: 'int',
    ),
    'maybeListMaybeBoolean': AttributeMeta<Fruit>(
      name: 'maybeListMaybeBoolean',
      type: 'List<bool>',
      nullable: true,
      internalType: 'List<bool>',
    ),
    'maybeListMaybeDate': AttributeMeta<Fruit>(
      name: 'maybeListMaybeDate',
      type: 'List<DateTime>',
      nullable: true,
      internalType: 'List',
    ),
    'maybeListMaybeInteger': AttributeMeta<Fruit>(
      name: 'maybeListMaybeInteger',
      type: 'List<int>',
      nullable: true,
      internalType: 'List<int>',
    ),
    'maybeListMaybeString': AttributeMeta<Fruit>(
      name: 'maybeListMaybeString',
      type: 'List<String>',
      nullable: true,
      internalType: 'List',
    ),
    'maybeString': AttributeMeta<Fruit>(
      name: 'maybeString',
      type: 'String',
      nullable: true,
      internalType: 'String',
    ),
    'props': AttributeMeta<Fruit>(
      name: 'props',
      type: 'List<Object>',
      nullable: true,
      internalType: 'List',
    ),
    'set': AttributeMeta<Fruit>(
      name: 'set',
      type: 'Set<String>',
      nullable: false,
      internalType: 'List',
    ),
    'string': AttributeMeta<Fruit>(
      name: 'string',
      type: 'String',
      nullable: false,
      internalType: 'String',
    ),
    'uri': AttributeMeta<Fruit>(
      name: 'uri',
      type: 'Uri',
      nullable: false,
      internalType: 'String',
    )
  };

  @override
  Map<String, FieldMeta> get fieldMetas => _kFruitFieldMetas;

  @override
  Fruit deserialize(map) {
    map = transformDeserialize(map);
    return _$FruitFromJson(map);
  }

  @override
  Map<String, dynamic> serialize(model, {bool withRelationships = true}) {
    final map = _$FruitToJson(model);
    return transformSerialize(map, withRelationships: withRelationships);
  }
}

final _fruitsFinders = <String, dynamic>{};

// ignore: must_be_immutable
class $FruitIsarLocalAdapter = IsarLocalAdapter<Fruit> with $FruitLocalAdapter;

class $FruitRemoteAdapter = RemoteAdapter<Fruit> with NothingMixin;

final internalFruitsRemoteAdapterProvider = Provider<RemoteAdapter<Fruit>>(
    (ref) => $FruitRemoteAdapter(
        $FruitIsarLocalAdapter(ref.read), InternalHolder(_fruitsFinders)));

final fruitsRepositoryProvider =
    Provider<Repository<Fruit>>((ref) => Repository<Fruit>(ref.read));

extension FruitDataRepositoryX on Repository<Fruit> {}

extension FruitRelationshipGraphNodeX on RelationshipGraphNode<Fruit> {}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fruit _$FruitFromJson(Map<String, dynamic> json) => Fruit(
      id: json['id'],
      bigInt: BigInt.parse(json['bigInt'] as String),
      duration: Duration(microseconds: json['duration'] as int),
      iterable: json['iterable'] as List<dynamic>,
      map: json['map'] as Map<String, dynamic>,
      boolMap: Map<String, bool>.from(json['boolMap'] as Map),
      set: (json['set'] as List<dynamic>).map((e) => e as String).toSet(),
      uri: Uri.parse(json['uri'] as String),
      integer: json['integer'] as int,
      maybeInteger: json['maybeInteger'] as int?,
      listMaybeInteger: (json['listMaybeInteger'] as List<dynamic>)
          .map((e) => e as int?)
          .toList(),
      maybeListMaybeInteger: (json['maybeListMaybeInteger'] as List<dynamic>?)
          ?.map((e) => e as int?)
          .toList(),
      date: DateTime.parse(json['date'] as String),
      maybeDate: json['maybeDate'] == null
          ? null
          : DateTime.parse(json['maybeDate'] as String),
      listMaybeDate: (json['listMaybeDate'] as List<dynamic>)
          .map((e) => e == null ? null : DateTime.parse(e as String))
          .toList(),
      maybeListMaybeDate: (json['maybeListMaybeDate'] as List<dynamic>?)
          ?.map((e) => e == null ? null : DateTime.parse(e as String))
          .toList(),
      string: json['string'] as String,
      maybeString: json['maybeString'] as String?,
      listMaybeString: (json['listMaybeString'] as List<dynamic>)
          .map((e) => e as String?)
          .toList(),
      maybeListMaybeString: (json['maybeListMaybeString'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      boolean: json['boolean'] as bool,
      maybeBoolean: json['maybeBoolean'] as bool?,
      listMaybeBoolean: (json['listMaybeBoolean'] as List<dynamic>)
          .map((e) => e as bool?)
          .toList(),
      maybeListMaybeBoolean: (json['maybeListMaybeBoolean'] as List<dynamic>?)
          ?.map((e) => e as bool?)
          .toList(),
      delimitedString: SetConverter.fromJson(json['delimitedString'] as String),
      classification: $enumDecode(
          _$ClassificationEnumMap, json['classification'],
          unknownValue: Classification.inactive),
    )..classificationNoDefault = $enumDecodeNullable(
        _$ClassificationEnumMap, json['classificationNoDefault']);

Map<String, dynamic> _$FruitToJson(Fruit instance) => <String, dynamic>{
      'id': instance.id,
      'integer': instance.integer,
      'maybeInteger': instance.maybeInteger,
      'listMaybeInteger': instance.listMaybeInteger,
      'maybeListMaybeInteger': instance.maybeListMaybeInteger,
      'date': instance.date.toIso8601String(),
      'maybeDate': instance.maybeDate?.toIso8601String(),
      'listMaybeDate':
          instance.listMaybeDate.map((e) => e?.toIso8601String()).toList(),
      'maybeListMaybeDate': instance.maybeListMaybeDate
          ?.map((e) => e?.toIso8601String())
          .toList(),
      'string': instance.string,
      'maybeString': instance.maybeString,
      'listMaybeString': instance.listMaybeString,
      'maybeListMaybeString': instance.maybeListMaybeString,
      'boolean': instance.boolean,
      'maybeBoolean': instance.maybeBoolean,
      'listMaybeBoolean': instance.listMaybeBoolean,
      'maybeListMaybeBoolean': instance.maybeListMaybeBoolean,
      'bigInt': instance.bigInt.toString(),
      'duration': instance.duration.inMicroseconds,
      'classification': _$ClassificationEnumMap[instance.classification],
      'classificationNoDefault':
          _$ClassificationEnumMap[instance.classificationNoDefault],
      'iterable': instance.iterable.toList(),
      'map': instance.map,
      'boolMap': instance.boolMap,
      'set': instance.set.toList(),
      'uri': instance.uri.toString(),
      'delimitedString': SetConverter.toJson(instance.delimitedString),
    };

const _$ClassificationEnumMap = {
  Classification.none: 0,
  Classification.open: 1,
  Classification.inactive: 2,
  Classification.closed: 3,
};
