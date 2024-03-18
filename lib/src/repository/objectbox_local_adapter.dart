part of flutter_data;

/// Objectbox implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class ObjectboxLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  ObjectboxLocalAdapter(Ref ref) : super(ref);

  ObjectboxLocalStorage get _storage => storage as ObjectboxLocalStorage;

  @override
  bool get isInitialized => true;

  @override
  void dispose() {}

  // protected API

  @override
  List<T> findAll() {
    final models = _storage.store
        .box<StoredModel>()
        .query(StoredModel_.type.equals(internalType) &
            StoredModel_.data.notNull())
        .build()
        .find();
    return _deserializeAndInitWithKeys(models).toList();
  }

  @override
  T? findOne(String? key) {
    final intKey = key?.detypifyKey();
    if (intKey == null) return null;
    final model = _storage.store.box<StoredModel>().get(intKey);
    if (model != null) {
      return _deserializeAndInitWithKeys([model], [intKey]).safeFirst;
    }
    return null;
  }

  @override
  List<T> findMany(Iterable<String> keys) {
    if (keys.isEmpty) return [];
    final intKeys = keys.map((key) => key.detypifyKey()).nonNulls.toList();
    final models =
        _storage.store.box<StoredModel>().getMany(intKeys).nonNulls.toList();
    return _deserializeAndInitWithKeys(models, intKeys).toList();
  }

  @override
  bool exists(String key) {
    final intKey = key.detypifyKey();
    if (intKey == null) {
      return false;
    }
    return logTime(null, () {
      return _storage.store.box<StoredModel>().contains(intKey);
    });
  }

  @override
  T save(String key, T model, {bool notify = true}) {
    saveMany([model], runAsync: false);
    return model;
  }

  @override
  Future<void> saveMany(Iterable<DataModelMixin> models,
      {bool runAsync = true, bool notify = true}) async {
    // group by key and start decomposing model into type, id,
    // serialized, (owner,metadata) relationship pairs
    final modelRecords = models.map((model) {
      // serialize model (can be of any type)
      // (serialize can't be passed into an isolate (depends on core.store))
      final serialized = DataModel.adapterFor(model)
          .localAdapter
          .serialize(model, withRelationships: false);
      return (model._key!, model._internalType, model.id, serialized);
    }).toList();

    // given a list of (key, type, id, serialized), return stored model instances
    final storedModels = runAsync
        ? (await _packModelsAsync(modelRecords))
        : _packModels(modelRecords);

    // relationships

    final localEdgeMap = <(String, String), List<Edge>?>{};

    for (final model in models) {
      for (final rel in DataModelMixin.relationshipsFor(model)) {
        final pair = (rel._ownerKey!, rel._name!);
        if (rel._uninitializedKeys == null) {
          localEdgeMap[pair] = null;
        } else {
          localEdgeMap[pair] = rel._uninitializedKeys!
              .map((to) => Edge(
                  from: rel._ownerKey!,
                  name: rel._name!,
                  to: to,
                  inverseName: rel._inverseName))
              .toList();
          rel._uninitializedKeys = null;
        }
      }
    }

    // query for all ids pointed to by (owner,metadata) pairs
    final pairs = localEdgeMap.keys;
    final allStoredEdges = storage.edgesFor(pairs);

    final ops = <_EdgeOperation>[];

    for (final e in localEdgeMap.entries) {
      final pair = e.key;
      final storedEdges = allStoredEdges.where((edge) {
        return {(edge.from, edge.name), (edge.to, edge.inverseName)}
            .contains(pair);
      });

      if (e.value != null) {
        for (final edge in e.value!) {
          if (!storedEdges.containsFirst(edge)) {
            // TODO fix adding symmetric operations, should add 1 not 2
            // probably fixed with good equality in EdgeOperations
            ops.add(AddEdgeOperation(edge));
          }
        }

        final localEdges = e.value!;

        for (final edge in storedEdges) {
          if (!localEdges.containsFirst(edge)) {
            // print('removing $key');
            ops.add(RemoveEdgeByKeyOperation(edge.internalKey));
          }
        }
      }
    }

    // save all relationships + models
    final param = (storedModels, ops);
    final savedKeys = runAsync
        ? (await storage.writeTxnAsync(_saveModelsAndOperations, param))
        : (storage
            .writeTxn(() => _saveModelsAndOperations(_storage.store, param)));

    if (storedModels.length != savedKeys.length) {
      print('WARNING! Not all models stored!');
    }

    if (notify) {
      core._notify(
        savedKeys.toList(),
        type: DataGraphEventType.updateNode,
      );

      for (final op in ops) {
        final type = switch (op) {
          AddEdgeOperation(edge: _) => DataGraphEventType.addEdge,
          UpdateEdgeOperation(edge: _, newTo: _) =>
            DataGraphEventType.updateEdge,
          _ => DataGraphEventType.removeEdge,
        };
        core._notify([op.edge.from, op.edge.to],
            metadata: op.edge.name, type: type);
      }
    }
  }

  static List<String> _saveModelsAndOperations(
      Store store, (Iterable<StoredModel>, List<_EdgeOperation>) record) {
    final keys = <String>[];
    final (models, operations) = record;
    for (final model in models) {
      final key = store.box<StoredModel>().put(model);
      keys.add(key.typifyWith(model.type));
    }

    store.runOperations(operations);

    return keys;
  }

  static Future<Iterable<StoredModel>> _packModelsAsync(
      Iterable<(String, String, Object?, Map<String, dynamic>)> models) {
    return Isolate.run(() => _packModels(models));
  }

  /// Turns maps into StoredModels
  static Iterable<StoredModel> _packModels(
      Iterable<(String, String, Object?, Map<String, dynamic>)> models) {
    return logTime(null, () {
      return models.map((m_) {
        // pack model
        final (key, type, id, map) = m_;
        final packer = Packer();
        packer.packJson(map);
        return StoredModel(
          internalKey: key.detypifyKey()!,
          type: type,
          id: id?.toString(),
          isInt: id is int,
          data: packer.takeBytes(),
        );
      });
    });
  }

  @override
  void delete(String key, {bool notify = true}) {
    return deleteKeys([key], notify: notify);
  }

  @override
  void deleteKeys(Iterable<String> keys, {bool notify = true}) {
    storage.writeTxn(() {
      for (final key in keys) {
        final intKey = key.detypifyKey();
        if (intKey != null) {
          _storage.store.box<StoredModel>().remove(intKey);
        }
        // TODO remove relationships
      }
    });
    core._notify([...keys], type: DataGraphEventType.removeNode);
  }

  @override
  Future<void> clear() async {
    storage.writeTxn(() {
      _storage.store.box<Edge>().removeAll();
      _storage.store.box<StoredModel>().removeAll();
    });
    core._notify([internalType], type: DataGraphEventType.clear);
  }

  // TODO should queries be closed() ?

  @override
  int get count {
    return _storage.store
        .box<StoredModel>()
        .query(StoredModel_.type.equals(internalType))
        .build()
        .count();
  }

  @override
  List<String> get keys {
    return logTime(
      null,
      () => storage.readTxn(() {
        final keys = _storage.store
            .box<StoredModel>()
            .query(StoredModel_.type.equals(internalType) &
                StoredModel_.id.notNull())
            .build()
            .property(StoredModel_.internalKey)
            .find()
            .map((k) => k.typifyWith(internalType));
        return keys.toList();
      }),
    );
  }

  // private

  Iterable<T> _deserializeAndInitWithKeys(List<StoredModel> storedModels,
      [List<int>? internalKeys]) {
    return storage.readTxn(
      () => storedModels.mapIndexed(
        (i, storedModel) {
          if (storedModel.data == null) {
            return null;
          }
          final map = storedModel.toJson();
          return deserialize(map,
              key: internalKeys?[i].typifyWith(internalType));
        },
      ).nonNulls,
    );
  }
}
