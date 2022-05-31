part of flutter_data;

/// Hive implementation of [LocalAdapter] and Hive's [TypeAdapter].
// ignore: must_be_immutable
abstract class IsarLocalAdapter<T extends DataModel<T>>
    extends LocalAdapter<T> {
  IsarLocalAdapter(this.read) : super(read);

  final Reader? read;
  late final IsarCollection<T> _collection;

  String get _internalType => DataHelpers.getType<T>();

  @override
  Future<IsarLocalAdapter<T>> initialize() async {
    _collection = read!(isarLocalStorageProvider)._isar!.getCollection<T>();
    _isInit = true;
    return this;
  }

  bool _isInit = false;

  @override
  bool get isInitialized => _isInit;

  @override
  void dispose() {}

  // protected API

  @override
  List<T> findAll() {
    return _collection.where().findAllSync();
  }

  @override
  T? findOne(int? key) {
    if (key == null) return null;
    return _collection.getSync(key);
  }

  @override
  int save(T model, {bool notify = true}) {
    final key =
        _collection.isar.writeTxnSync((_) => _collection.putSync(model));

    if (notify) {
      graph._notify(
        [model._key],
        type: model.__key == key // TODO check (was keyExisted)
            ? DataGraphEventType.updateNode
            : DataGraphEventType.addNode,
      );
    }

    return model.__key = key;
  }

  @override
  Future<void> delete(int key) async {
    await _collection.delete(key);
  }

  @override
  Future<void> clear() async {
    await _collection.clear();
  }

  // schema

  CollectionSchema get schema {
    final attributeMetas = fieldMetas.attributes.values.toList();
    final indexAttributeMetas =
        fieldMetas.attributes.values.where((e) => e.index != null).toList();
    final relationshipMetas = fieldMetas.relationships.values.toList();
    final schemaName = _internalType == '_GraphEdges' ? 'graph' : _internalType;

    final schema = CollectionSchema<T>(
      name: schemaName,
      schema: json.encode({
        'name': schemaName,
        'idName': '__key',
        'properties': [
          for (final meta in attributeMetas)
            {
              'name': meta.name,
              'type': _getNativeTypeFor(meta.internalType),
            }
        ],
        'indexes': [
          for (final e
              in attributeMetas.groupListsBy((meta) => meta.index).entries)
            if (e.key != null)
              {
                'name': e.key,
                'unique': false,
                'replace': false,
                'properties': [
                  for (final meta in e.value)
                    {
                      'name': meta.name,
                      'type': 'Hash',
                      'caseSensitive': true,
                    }
                ]
              }
        ],
        'links': [
          for (final meta in relationshipMetas)
            {
              'name': meta.name,
              'target': meta.type,
            }
        ],
      }),
      idName: '__key',
      propertyIds: {
        for (var i = 0; i < attributeMetas.length; i++)
          attributeMetas[i].name: i,
      },
      listProperties: {
        for (final e in attributeMetas)
          if (e.internalType.startsWith('List')) e.name,
      },
      indexIds: {
        for (var i = 0; i < indexAttributeMetas.length; i++)
          indexAttributeMetas[i].index!: i,
      },
      indexValueTypes: {
        for (final e in indexAttributeMetas)
          e.index!: [IndexValueType.stringHash],
      },
      linkIds: {},
      backlinkLinkNames: {},
      getId: internalGetId,
      setId: internalSetId,
      getLinks: internalGetLinks,
      attachLinks: internalAttachLinks,
      serializeNative: internalSerializeNative,
      deserializeNative: internalDeserializeNative,
      deserializePropNative: internalDeserializePropNative,
      serializeWeb: internalSerializeWeb,
      deserializeWeb: internalDeserializeWeb,
      deserializePropWeb: internalDeserializePropWeb,
      version: 4,
    );
    return schema;
  }

  int? internalGetId(T object) => object.__key;

  void internalSetId(T object, int id) => object.__key = id;

  List<IsarLinkBase> internalGetLinks(T object) {
    return [];
  }

  // serialization

  void internalSerializeNative(
    IsarCollection<T> collection,
    IsarCObject cObj,
    T object,
    int staticSize,
    List<int> offsets,
    AdapterAlloc alloc,
  ) {
    final metaMap = fieldMetas.attributes;
    final map = serialize(object, withRelationships: false);

    var dynamicSize = 0;

    final isarMap = <String, dynamic>{};

    for (final meta in metaMap.entries) {
      final value = map[meta.key];
      final type = meta.value.type;
      final internalType = meta.value.internalType;

      if (value != null) {
        if (internalType == 'List<int>') {
          dynamicSize += (value as List).length * 8;
          isarMap[meta.key] = value;
        } else if (internalType == 'List<bool>') {
          dynamicSize += (value as List?)?.length ?? 0;
          isarMap[meta.key] = value;
        } else if (internalType == 'String' || internalType == 'Map') {
          if (type == 'DateTime') {
            isarMap[meta.key] = DateTime.parse(value as String);
          } else {
            final _value =
                internalType == 'Map' ? json.encode(value) : value as String;
            final u = IsarBinaryWriter.utf8Encoder.convert(_value);
            dynamicSize += u.length;
            isarMap[meta.key] = u;
          }
        } else if (internalType == 'List') {
          if (type == 'List<DateTime>') {
            dynamicSize += (value as List).length * 8;
            isarMap[meta.key] = value
                .map((e) => e != null ? DateTime.parse(e.toString()) : null)
                .toList();
          } else {
            final list = (value as Iterable).map((e) => e?.toString()).toList();
            dynamicSize += list.length * 8;
            final ul = <IsarUint8List?>[];
            for (final s in list) {
              if (s != null) {
                final u = IsarBinaryWriter.utf8Encoder.convert(s);
                ul.add(u);
                dynamicSize += u.length;
              } else {
                ul.add(null);
              }
            }
            isarMap[meta.key] = ul;
          }
        } else if (['int', 'bool', 'double'].contains(internalType)) {
          isarMap[meta.key] = value;
        } else {
          throw UnimplementedError('missing type $internalType');
        }
      }
    }

    final size = staticSize + dynamicSize;

    cObj.buffer = alloc(size);
    cObj.buffer_length = size;
    final buffer = IsarNative.bufAsBytes(cObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, staticSize);

    var i = 0;
    for (final e in metaMap.entries) {
      _setValueFor(writer, offsets[i], e.value.type, e.value.internalType,
          isarMap[e.key], e.key);
      i++;
    }
  }

  T internalDeserializeNative(IsarCollection<T> collection, int id,
      IsarBinaryReader reader, List<int> offsets) {
    var i = 0;
    final map = <String, dynamic>{
      // if id was not a local auto-generated
      if (id > _RemoteAdapter.kMinKey) 'id': id.toString(), // TODO fix
      for (final e in fieldMetas.attributes.entries)
        e.key: _getValueFor(reader, offsets[i++], e.value.type,
            e.value.internalType, e.value.nullable, e.key),
    };

    final model = deserialize(map);
    model.__key = id;
    return model;
  }

  // temporarily unsupported

  void internalAttachLinks(IsarCollection col, int id, T object) {
    // no-op
  }

  P internalDeserializePropNative<P>(
      int id, IsarBinaryReader reader, int propertyIndex, int offset) {
    throw UnsupportedError('internalDeserializePropNative');
  }

  dynamic internalSerializeWeb(IsarCollection<T> collection, T object) {
    throw UnsupportedError('internalSerializeWeb');
  }

  T internalDeserializeWeb(IsarCollection<T> collection, dynamic jsObj) {
    throw UnsupportedError('internalDeserializeWeb');
  }

  P internalDeserializePropWeb<P>(Object jsObj, String propertyName) {
    throw UnsupportedError('internalDeserializePropWeb');
  }

  // internal helpers

  Object? _getValueFor(IsarBinaryReader reader, int offset, String type,
      String internalType, bool nullable, String key) {
    if (internalType == 'int') {
      return nullable ? reader.readLongOrNull(offset) : reader.readLong(offset);
    }
    if (type == 'DateTime') {
      return (nullable
              ? reader.readDateTimeOrNull(offset)
              : reader.readDateTime(offset))
          ?.toIso8601String();
    }
    if (internalType == 'bool') {
      return nullable ? reader.readBoolOrNull(offset) : reader.readBool(offset);
    }
    if (internalType == 'double') {
      return nullable
          ? reader.readFloatOrNull(offset)
          : reader.readFloat(offset);
    }
    if (internalType == 'String' || internalType.startsWith('Map')) {
      final value = nullable
          ? reader.readStringOrNull(offset)
          : reader.readString(offset);
      if (internalType.startsWith('Map') && value != null) {
        return json.decode(value);
      } else {
        return value;
      }
    }

    if (internalType == 'List') {
      if (type == 'List<DateTime>') {
        return (nullable
                ? reader.readDateTimeOrNullList(offset)
                : reader.readDateTimeList(offset))
            ?.map((e) => e?.toIso8601String())
            .toList();
      }
      return nullable
          ? reader.readStringOrNullList(offset)
          : reader.readStringList(offset);
    }

    if (internalType == 'List<int>') {
      return nullable
          ? reader.readLongOrNullList(offset)
          : reader.readLongList(offset);
    }

    if (internalType == 'List<bool>') {
      return nullable
          ? reader.readBoolOrNullList(offset)
          : reader.readBoolList(offset);
    }

    throw UnsupportedError('what? passed type $internalType -- $type');
  }

  void _setValueFor(IsarBinaryWriter writer, int offset, String type,
      String internalType, dynamic value, String key) {
    if (internalType == 'int') {
      return writer.writeLong(offset, value as int?);
    }
    if (internalType == 'String' || internalType == 'Map') {
      if (type == 'DateTime') {
        return writer.writeDateTime(offset, value as DateTime?);
      } else {
        return writer.writeBytes(offset, value as IsarUint8List?);
      }
    }

    if (internalType == 'List') {
      if (type == 'List<DateTime>') {
        return writer.writeDateTimeList(offset, value as List<DateTime?>?);
      } else {
        return writer.writeStringList(offset, value as List<IsarUint8List?>?);
      }
    }
    if (internalType == 'List<int>') {
      return writer.writeLongList(offset, value as List<int?>?);
    }

    if (internalType == 'bool') {
      return writer.writeBool(offset, value as bool?);
    }
    if (internalType == 'List<bool>') {
      return writer.writeBoolList(offset, value as List<bool?>?);
    }
    if (internalType == 'double') {
      return writer.writeFloat(offset, value as double?);
    }
    if (internalType == 'List<double>') {
      return writer.writeFloatList(offset, value as List<double?>?);
    }
    throw UnimplementedError('not found $internalType');
  }

  String _getNativeTypeFor(String internalType) {
    if (internalType == 'int' || internalType == 'DateTime') return 'Long';
    if (internalType == 'String' || internalType == 'Map') return 'String';
    if (internalType == 'bool') return 'Bool';
    if (['List<int>', 'List<DateTime'].contains(internalType)) {
      return 'LongList';
    }
    if (internalType == 'List<String>' || internalType == 'List') {
      return 'StringList';
    }
    if (internalType == 'List<bool>') return 'BoolList';

    throw UnsupportedError('$internalType?');
  }
}
