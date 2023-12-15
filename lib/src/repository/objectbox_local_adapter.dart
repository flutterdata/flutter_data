part of flutter_data;

/// Hive implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class ObjectboxLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  ObjectboxLocalAdapter(Ref ref) : super(ref);

  @protected
  @visibleForTesting
  Store get store => core.store;

  @override
  bool get isInitialized => true;

  @override
  void dispose() {}

  // protected API

  @override
  List<T> findAll() {
    final result = store
        .box<StoredModel>()
        .query(StoredModel_.typeId.startsWith(internalType) &
            StoredModel_.data.notNull())
        .build()
        .find()
        .map((e) => initModel(deserialize(e.toJson()!)))
        .toList();
    print('--- [read] findAll: ${result.length}');
    return result;
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
    print('--- [read] findOneById');
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
    final models = core.store.box<StoredModel>().getMany(_keys).nonNulls;
    return models
        // Models are auto-initialized with other random keys
        // so we need to reassign the corresponding key
        .mapIndexed((i, map) => _deserializeWithKey(map.toJson(), _keys[i]))
        .nonNulls
        .toList();
  }

  @override
  bool exists(String key) {
    print('--- [read] exists');
    return core.store
            .box<StoredModel>()
            .query(StoredModel_.key.equals(key.detypify() as int) &
                StoredModel_.data.notNull())
            .build()
            .count() >
        0;
  }

  @override
  T save(String key, T model, {bool notify = true}) {
    print('---- calling save on type $internalType');
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

    final savedKey = core._writeTxn(() {
      // TODO restore
      // for (final rel in DataModelMixin.relationshipsFor(model)) {
      //   rel._save(core._store);
      // }
      return store.box<StoredModel>().put(storedModel).typifyWith(internalType);
    });
    core._mappingBuffer.remove(savedKey);

    if (notify) {
      core._notify([savedKey], type: DataGraphEventType.updateNode);
    }
    return model;
  }

  static Future<List<(String, StoredModel)>> _pack(
      List<(String, String, Map<String, dynamic>)> models) async {
    return await Isolate.run(() async {
      return await logTime('pack inside isolate', () async {
        return models.map((m_) {
          final (key, typeId, s) = m_;
          final packer = Packer();
          packer.packJson(s);
          final model = StoredModel(
            typeId: typeId,
            key: key.detypify() as int,
            data: packer.takeBytes(),
          );
          return (key, model);
        }).toList();
      });
    });
  }

  // TODO implement cutoff for sync/async saving, allow specifying it too
  @override
  Future<void> saveMany(Iterable<DataModelMixin> models,
      {bool notify = true}) async {
    print('---- calling savemany (on type $internalType) ${models.length}');

    final Map<String, (String, dynamic, List<_EdgeOperation>)> map =
        models.groupFoldBy((m) => m._key!, (acc, model) {
      final key = DataModelMixin.keyFor(model)!;
      final buffer = core._mappingBuffer[key];
      final typeId = switch (buffer) {
        (String typeId,) => typeId, // ID mapping was added
        (null,) => ''.typifyWith(model._internalType), // ID mapping was removed
        null => model.id
            .typifyWith(model._internalType), // no mapping so assign default
      };
      final serialized = DataModel.adapterFor(model)
          .localAdapter
          .serialize(model, withRelationships: false);
      final edgeOperations = <_EdgeOperation>{};
      for (final rel in DataModelMixin.relationshipsFor(model)) {
        edgeOperations.addAll(rel._edgeOperations);
        // TODO what if this fails, we lose the ops?
        rel._edgeOperations.clear();
      }
      return (typeId, serialized, edgeOperations.toList());
    });

    final storedModels = await _pack([
      for (final e in map.entries)
        (e.key, e.value.$1, e.value.$2 as Map<String, dynamic>)
    ]);

    for (final (key, storedModel) in storedModels) {
      final value = map[key]!;
      map[key] = (value.$1, storedModel, value.$3);
    }
    final records = map.values;

    final savedKeys = await core._writeTxnAsync((store, records) {
      final keys = <String>[];
      final allOperations = <_EdgeOperation>[];
      for (final record in records) {
        final (typeId, model, operations) = record;
        allOperations.addAll(operations);
        final key = store.box<StoredModel>().put(model);
        final type = typeId.split('#').first;
        keys.add(key.typifyWith(type));
      }
      print('---- saving ${allOperations.length} ops');
      allOperations.run(store);
      return keys;
    }, records);

    if (map.length != savedKeys.length) {
      print('WARNING! Not all models stored!');
    }

    // remove keys that were saved from buffer
    for (final key in savedKeys) {
      core._mappingBuffer.remove(key);
    }

    if (notify) {
      core._notify(
        savedKeys.toList(),
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
    core._writeTxn(() {
      core.store.box<Edge>().removeAll();
      core.store.box<StoredModel>().removeAll();
    });
    core._notify([internalType], type: DataGraphEventType.clear);
  }

  @override
  int get count {
    print('--- [read] count');
    return store
        .box<StoredModel>()
        .query(StoredModel_.typeId.startsWith(internalType))
        .build()
        .count();
  }

  @override
  List<String> get keys {
    print('--- [read] keys');
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
