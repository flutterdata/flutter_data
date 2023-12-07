part of flutter_data;

/// Hive implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class ObjectboxLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  ObjectboxLocalAdapter(Ref ref) : super(ref);

  @protected
  @visibleForTesting
  Store get store => core._store;

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
    final models = core._store.box<StoredModel>().getMany(_keys).nonNulls;
    return models
        // Models are auto-initialized with other random keys
        // so we need to reassign the corresponding key
        .mapIndexed((i, map) => _deserializeWithKey(map.toJson(), _keys[i]))
        .nonNulls
        .toList();
  }

  @override
  bool exists(String key) {
    return core._store
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

    final buffer = core._mappingBuffer[key];
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

    final savedKey = core._store.runInTransaction(TxMode.write, () {
      for (final rel in DataModel.relationshipsFor(model)) {
        rel.save();
      }
      return store.box<StoredModel>().put(storedModel).typifyWith(internalType);
    });
    core._mappingBuffer.remove(savedKey);

    if (notify) {
      core._notify([savedKey], type: DataGraphEventType.updateNode);
    }
    return model;
  }

  @override
  Future<void> saveMany(Iterable<DataModelMixin> models,
      {bool notify = true}) async {
    final storedModels = models.map((m) {
      final key = DataModelMixin.keyFor(m)!;
      final packer = Packer();
      final a = DataModel.adapterFor(m).localAdapter;
      packer.packJson(a.serialize(m, withRelationships: false));
      final buffer = core._mappingBuffer[key];
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

    final savedKeys = store.runInTransaction(TxMode.write, () {
      return storedModels.map((m) {
        return store.box<StoredModel>().put(m).typifyWith(m.type);
      }).toList();
    });

    if (storedModels.length != savedKeys.length) {
      print('WARNING! Not all models stored!');
    }
    // remove keys that were saved from buffer
    for (final key in savedKeys) {
      core._mappingBuffer.remove(key);
    }

    if (notify) {
      core._notify(
        savedKeys,
        type: DataGraphEventType.updateNode,
      );
    }
  }

  @override
  Future<void> delete(String key, {bool notify = true}) {
    return deleteKeys([key], notify: notify);
  }

  @override
  Future<void> deleteKeys(Iterable<String> keys, {bool notify = true}) async {
    core._writeTxn(() {
      for (final key in keys) {
        core.removeIdForKey(key);
        store.box<StoredModel>().remove(key.detypify() as int);
      }
    });
    core._notify([...keys], type: DataGraphEventType.removeNode);
  }

  @override
  Future<void> clear() async {
    core._store.box<Edge>().removeAll();
    core._store.box<StoredModel>().removeAll();
    core._notify([internalType], type: DataGraphEventType.clear);
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
