part of flutter_data;

/// Hive implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class ObjectboxLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  ObjectboxLocalAdapter(Ref ref) : super(ref);

  @protected
  @visibleForTesting
  Store get store => graph._store;

  @override
  bool get isInitialized => true;

  @override
  void dispose() {}

  // protected API

  @override
  List<T> findAll() {
    return store
        .box<StoredModel>()
        .query(StoredModel_.typeId.startsWith(internalType) &
            StoredModel_.data.notNull())
        .build()
        .find()
        .map((e) => initModel(deserialize(e.toJson()!)))
        .toList();
  }

  @override
  T? findOne(String? key) {
    if (key == null) return null;
    final internalKey = key.detypify() as int;
    final json = store.box<StoredModel>().get(internalKey)?.toJson();
    return _deserializeWithKey(json, internalKey);
  }

  @override
  T? findOneById(Object? id) {
    if (id == null) return null;
    final model = store
        .box<StoredModel>()
        .query(StoredModel_.typeId.equals(id.typifyWith(internalType)))
        .build()
        .findFirst();
    return _deserializeWithKey(model?.toJson(), model?.key);
  }

  @override
  List<T> findMany(Iterable<String> keys) {
    final _keys = keys.map((key) => key.detypify() as int).toList();
    final models = graph._store.box<StoredModel>().getMany(_keys).nonNulls;
    return models
        // Models are auto-initialized with other random keys
        // so we need to reassign the corresponding key
        .mapIndexed((i, map) => _deserializeWithKey(map.toJson(), _keys[i]))
        .nonNulls
        .toList();
  }

  @override
  bool exists(String key) {
    return graph._store
            .box<StoredModel>()
            .query(StoredModel_.key.equals(key.detypify() as int) &
                StoredModel_.data.notNull())
            .build()
            .count() >
        0;
  }

  @override
  T save(String key, T model, {bool notify = true}) {
    final packer = Packer();
    packer.packJson(serialize(model, withRelationships: false));

    final buffer = graph._mappingBuffer[key];
    final typeId = switch (buffer) {
      (String typeId,) => typeId, // ID mapping was added
      (null,) => ''.typifyWith(internalType), // ID mapping was removed
      null => model.id.typifyWith(internalType), // no mapping so assign default
    };

    final storedModel = StoredModel(
      typeId: typeId,
      key: key.detypify() as int,
      data: packer.takeBytes(),
    );

    final savedKey = graph._store.runInTransaction(TxMode.write, () {
      for (final rel in DataModel.relationshipsFor(model).values) {
        rel.save();
      }
      return store.box<StoredModel>().put(storedModel).typifyWith(internalType);
    });
    graph._mappingBuffer.remove(savedKey);

    if (notify) {
      graph._notify([savedKey], type: DataGraphEventType.updateNode);
    }
    return model;
  }

  @override
  Future<void> bulkSave(Iterable<DataModel> models,
      {bool notify = true}) async {
    print('bulkSave');
    final storedModels = models.map((m) {
      final key = DataModel.keyFor(m);
      final packer = Packer();
      final a = DataModel.adapterFor(m).localAdapter;
      packer.packJson(a.serialize(m, withRelationships: false));
      final buffer = graph._mappingBuffer[key];
      final typeId = switch (buffer) {
        (String typeId,) => typeId, // ID mapping was added
        (null,) => ''.typifyWith(a.internalType), // ID mapping was removed
        null => m.id.typifyWith(a.internalType), // no mapping so assign default
      };
      return StoredModel(
        typeId: typeId,
        key: key.detypify() as int,
        data: packer.takeBytes(),
      );
    }).toList();

    final savedKeys =
        await store.runInTransactionAsync(TxMode.write, (store, storedModels) {
      return storedModels.map((m) {
        return store.box<StoredModel>().put(m).typifyWith(m.type);
      }).toList();
    }, storedModels);

    if (storedModels.length != savedKeys.length) {
      print('WARNING! Not all models stored!');
    }
    // remove keys that were saved from buffer
    for (final key in savedKeys) {
      graph._mappingBuffer.remove(key);
    }

    if (notify) {
      graph._notify(
        savedKeys,
        type: DataGraphEventType.updateNode,
      );
    }
  }

  @override
  Future<void> delete(String key, {bool notify = true}) async {
    graph.removeIdForKey(key);
    store.box<StoredModel>().remove(key.detypify() as int);
    graph._notify([key], type: DataGraphEventType.removeNode);
  }

  @override
  void clear() {
    graph._store.box<Edge>().removeAll();
    graph._store.box<StoredModel>().removeAll();
    graph._notify([internalType], type: DataGraphEventType.clear);
  }

  @override
  int get count {
    return store
        .box<StoredModel>()
        .query(StoredModel_.typeId.startsWith(internalType))
        .build()
        .count();
  }

  @override
  List<String> get keys {
    return store
        .box<StoredModel>()
        .query(StoredModel_.typeId.startsWith(internalType))
        .build()
        .property(StoredModel_.key)
        .find()
        .map((k) => k.typifyWith(internalType))
        .toList();
  }

  ///

  T? _deserializeWithKey(Map<String, dynamic>? map, int? internalKey) {
    if (map != null) {
      var model = deserialize(map);
      if (model.id == null) {
        // if model has no ID, deserializing will assign a new key
        // but we want to keep the supplied one, so we use `withKey`
        model = DataModel.withKey(internalKey.typifyWith(internalType),
            applyTo: model);
      }
      return initModel(model);
    } else {
      return null;
    }
  }
}
