part of flutter_data;

/// Hive implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class IsarLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  IsarLocalAdapter(Ref ref) : super(ref);

  @protected
  @visibleForTesting
  Isar get isar => graph._isar;

  @override
  bool get isInitialized => true;

  @override
  void dispose() {}

  // protected API

  @override
  List<T> findAll() {
    return isar.storedModels
        .where()
        .typeEqualTo(internalType)
        .dataIsNotEmpty()
        .findAll()
        .map((e) => initModel(deserialize(e.toJson()!)))
        .toList();
  }

  @override
  T? findOne(String? key) {
    if (key == null) return null;
    final internalKey = graph.intKey(key);
    final json = isar.storedModels.get(internalKey)?.toJson();
    return _deserializeWithKey(json, internalKey);
  }

  @override
  T? findOneById(Object? id) {
    if (id == null) return null;
    final model = isar.storedModels
        .where()
        .typeEqualTo(internalType)
        .idEqualTo(id.toString())
        .findFirst();
    return _deserializeWithKey(model?.toJson(), model?.key);
  }

  @override
  List<T> findMany(Iterable<String> keys) {
    final _keys = keys.map(graph.intKey).toList();
    return graph._isar.storedModels
        .getAll(_keys)
        .filterNulls
        .mapIndexed((i, map) => _deserializeWithKey(map.toJson(), _keys[i]))
        .filterNulls
        .toList();
  }

  @override
  bool exists(String key) {
    return graph._isar.storedModels
            .where()
            .keyEqualTo(graph.intKey(key))
            .dataIsNotNull()
            .count() >
        0;
  }

  @override
  Future<T> save(String key, T model, {bool notify = true}) async {
    final keyExisted = exists(key);

    final packer = Packer();
    // TODO could avoid saving ID
    packer.packJson(serialize(model, withRelationships: false));

    final storedModel = StoredModel(
      id: model.id?.toString(),
      isIdInt: model.id is int,
      type: internalType,
      key: graph.intKey(key),
      data: packer.takeBytes(),
    );
    isar.write((isar) => isar.storedModels.put(storedModel));

    if (notify) {
      graph._notify(
        [key],
        type: keyExisted
            ? DataGraphEventType.updateNode
            : DataGraphEventType.addNode,
      );
    }
    return model;
  }

  @override
  Future<void> delete(String key, {bool notify = true}) async {
    isar.write((isar) => isar.storedModels.delete(graph.intKey(key)));
    graph._notify([key], type: DataGraphEventType.removeNode);
  }

  @override
  Future<void> clear() async {
    graph._isar.write((isar) => isar.clear());
    graph._notify([internalType], type: DataGraphEventType.clear);
  }

  @override
  int get count {
    return isar.storedModels.where().typeEqualTo(internalType).count();
  }

  @override
  List<String> get keys {
    return isar.storedModels
        .where()
        .typeEqualTo(internalType)
        .keyProperty()
        .findAll()
        .map((k) => k.toString().typifyWith(internalType))
        .toList();
  }

  ///

  T? _deserializeWithKey(Map<String, dynamic>? map, int? internalKey) {
    if (map != null) {
      var model = deserialize(map);
      if (model.id == null) {
        // if model has no ID, deserializing will assign a new key
        // but we want to keep the supplied one, so we use `withKey`
        model = DataModel.withKey(
            internalKey.toString().typifyWith(internalType),
            applyTo: model);
      }
      return initModel(model);
    } else {
      return null;
    }
  }
}
