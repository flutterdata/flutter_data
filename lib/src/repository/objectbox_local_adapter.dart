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
    final models = store
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
    final model = store.box<StoredModel>().get(intKey);
    if (model != null) {
      return _deserializeAndInitWithKeys([model], [intKey]).first;
    }
    return null;
  }

  @override
  List<T> findMany(Iterable<String> keys) {
    if (keys.isEmpty) return [];
    final intKeys = keys.map((key) => key.detypifyKey()).nonNulls.toList();
    final models =
        core.store.box<StoredModel>().getMany(intKeys).nonNulls.toList();
    return _deserializeAndInitWithKeys(models, intKeys).toList();
  }

  @override
  bool exists(String key) {
    final intKey = key.detypifyKey();
    if (intKey == null) {
      return false;
    }
    return logTime(null, () {
      return core.store.box<StoredModel>().contains(intKey);
    });
  }

  @override
  T save(String key, T model, {bool notify = true}) {
    saveMany([model], runAsync: false);
    return model;
    // TODO shouldn't this just call saveMany()
    // final packer = Packer();
    // packer.packJson(serialize(model, withRelationships: false));

    // final storedModel = StoredModel(
    //   internalKey: key.detypifyKey()!,
    //   type: internalType,
    //   id: model.id?.toString(),
    //   isInt: model.id is int,
    //   data: packer.takeBytes(),
    // );

    // final savedKey = core._writeTxn(() {
    //   // TODO should better group this shit
    //   for (final rel in DataModelMixin.relationshipsFor(model)) {
    //     rel.save();
    //   }
    //   return store.box<StoredModel>().put(storedModel).typifyWith(internalType);
    // });

    // // TODO where does it make sense to use putQueued?

    // if (notify) {
    //   core._notify([savedKey], type: DataGraphEventType.updateNode);
    // }
    // return model;
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
        ? (await Isolate.run(() => _packModels(modelRecords)))
        : _packModels(modelRecords);

    // relationships

    final relationshipRecords = models.map((model) {
      final relationships = DataModelMixin.relationshipsFor(model);
      return relationships
          .map((rel) => (rel._ownerKey!, rel._name!, rel._edgeOperations));
    }).flattened;

    // query for all ids pointed to by (owner,metadata) pairs
    final existingEdgeIds =
        _edgeIdsFor(relationshipRecords, core.store.box<Edge>());

    final aggregateOperations = relationshipRecords.map((e) => e.$3).flattened;

    // calculate edge operations (they are all add operations, create in initialize)
    final edgeMap = {
      for (final op in aggregateOperations.cast<AddEdgeOperation>())
        op.edge.internalKey: op.edge
    };

    final toRemove = {
      for (final key in existingEdgeIds)
        if (!edgeMap.keys.contains(key)) RemoveEdgeByIdOperation(key)
    };

    final toAdd = {
      for (final edge in edgeMap.values)
        if (!existingEdgeIds.contains(edge.internalKey)) AddEdgeOperation(edge)
    };

    // save all relationships + models
    final param = (storedModels, [...toAdd, ...toRemove]);
    final savedKeys = runAsync
        ? (await core._writeTxnAsync(_saveModelsAndOperations, param))
        : (core._writeTxn(() => _saveModelsAndOperations(core.store, param)));

    if (storedModels.length != savedKeys.length) {
      print('WARNING! Not all models stored!');
    }

    if (notify) {
      core._notify(
        savedKeys.toList(),
        type: DataGraphEventType.updateNode,
      );
    }
  }

  List<String> _saveModelsAndOperations(
      Store store, (Iterable<StoredModel>, List<_EdgeOperation>) record) {
    final keys = <String>[];
    final (models, operations) = record;
    for (final model in models) {
      final key = store.box<StoredModel>().put(model);
      keys.add(key.toString().typifyWith(model.type));
    }
    print('---- saving ${operations.length} ops');
    operations.run(store);
    return keys;
  }

  Set<int> _edgeIdsFor(
      Iterable<(String, String, dynamic)> pairs, Box<Edge> box) {
    if (pairs.isEmpty) {
      return {};
    }
    final conditions =
        pairs.map((p) => Relationship._queryConditionTo(p.$1, p.$2));
    final condition = conditions.reduce((acc, e) => acc | e);
    return box.query(condition).build().findIds().toSet();
  }

  /// Turns maps into StoredModels, and resolve add/remove edge operations
  Iterable<StoredModel> _packModels(
      Iterable<(String, String, Object?, Map<String, dynamic>)> models) {
    return logTime('_packModels', () {
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
    core._writeTxn(() {
      for (final key in keys) {
        final intKey = key.detypifyKey();
        if (intKey != null) {
          store.box<StoredModel>().remove(intKey);
        }
        // TODO should remove relationships
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

  // TODO should queries be closed() ?

  @override
  int get count {
    return store
        .box<StoredModel>()
        .query(StoredModel_.type.equals(internalType))
        .build()
        .count();
  }

  @override
  List<String> get keys {
    return logTime(
      null,
      () => core._readTxn(() {
        final keys = store
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
    // TODO worth/possible doing inside an isolate if > cutoff?
    return core._readTxn(
      () => storedModels.mapIndexed(
        (i, storedModel) {
          final map = storedModel.toJson();
          return deserialize(map,
              key: internalKeys?[i].typifyWith(internalType));
        },
      ),
    );
  }
}
