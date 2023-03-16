part of flutter_data;

/// Hive implementation of [LocalAdapter] and Hive's [TypeAdapter].
// ignore: must_be_immutable
abstract class HiveLocalAdapter<T extends DataModel<T>> extends LocalAdapter<T>
    with TypeAdapter<T> {
  HiveLocalAdapter(Ref ref, {int? typeId})
      : _typeId = typeId,
        _hiveLocalStorage = ref.read(hiveLocalStorageProvider),
        super(ref);

  final int? _typeId;
  final HiveLocalStorage _hiveLocalStorage;

  final _hiveAdapterNs = '_adapter_hive';
  String get _hiveAdapterKey => 'key'.namespaceWith(_hiveAdapterNs);

  @protected
  @visibleForTesting
  Box<T>? get box => (_box?.isOpen ?? false) ? _box : null;
  Box<T>? _box;

  @override
  Future<HiveLocalAdapter<T>> initialize() async {
    if (isInitialized) return this;
    final hive = _hiveLocalStorage.hive;

    if (!hive.isBoxOpen(internalType)) {
      if (!hive.isAdapterRegistered(typeId)) {
        hive.registerAdapter(this);
      }
    }

    try {
      if (_hiveLocalStorage.clear == LocalStorageClearStrategy.always) {
        await _hiveLocalStorage.deleteBox(internalType);
      }
      _box = await _hiveLocalStorage.openBox<T>(internalType);
    } catch (e, stackTrace) {
      print('[flutter_data] Box failed to open:\n$e\n$stackTrace');
    }

    return this;
  }

  @override
  bool get isInitialized => box != null;

  @override
  void dispose() {
    box?.close();
  }

  // protected API

  @override
  List<T> findAll() {
    return box?.values.toImmutableList() ?? [];
  }

  @override
  T? findOne(String? key) {
    if (key == null) return null;
    return box?.get(key);
  }

  @override
  Future<T> save(String key, T model, {bool notify = true}) async {
    if (box == null) return model;

    final keyExisted = box!.containsKey(key);
    final save = box!.put(key, model);
    if (notify) {
      graph._notify(
        [key],
        type: keyExisted
            ? DataGraphEventType.updateNode
            : DataGraphEventType.addNode,
      );
    }

    await save;
    return model;
  }

  @override
  Future<void> delete(String key, {bool notify = true}) async {
    if (box == null) return;
    final delete = box!.delete(key); // delete in bg
    final id = graph.getIdForKey(key);
    if (id != null) {
      graph.removeId(internalType, id, notify: false);
    }
    graph.removeKey(key);
    await delete;
  }

  @override
  Future<void> clear() async {
    if (box == null) return;

    final keys = box!.keys;

    for (final key in keys) {
      key as String;
      final id = graph.getIdForKey(key);
      if (id != null) {
        graph.removeId(internalType, id);
      }
      graph._removeNode(key, notify: false);
    }

    await box!.clear();
    graph._notify([internalType], type: DataGraphEventType.clear);
  }

  // hive adapter

  @override
  int get typeId {
    late final int id;

    // initialize typesNode
    final typesNode =
        graph._getNode(_hiveAdapterKey, orAdd: true, notify: false)!;

    // if `typeId` was supplied, use it
    if (_typeId != null) {
      id = _typeId!;
    } else {
      // otherwise auto-calculate (and persist)

      // _adapter_hive:key: {
      //   '_adapter_hive:posts': ['_adapter_hive:1'],
      //   '_adapter_hive:comments': ['_adapter_hive:2'],
      //   '_adapter_hive:houses': ['_adapter_hive:3'],
      // }

      final edge = typesNode[internalType.namespaceWith(_hiveAdapterNs)];

      if (edge != null && edge.isNotEmpty) {
        // first is of format: _adapter_hive:1
        return int.parse(edge.first.denamespace());
      }

      // get namespaced indices
      id = typesNode.values
              // denamespace and parse single
              .map((e) => int.parse(e.first.denamespace()))
              // find max
              .fold(0, math.max) +
          1;
    }

    graph._addEdge(_hiveAdapterKey, id.toString().namespaceWith(_hiveAdapterNs),
        metadata: internalType.namespaceWith(_hiveAdapterNs), notify: false);

    return id;
  }

  @override
  T read(reader) {
    // read attributes (no relationships stored)
    final total = reader.readByte();
    final map = <String, dynamic>{
      for (var i = 0; i < total; i++) reader.read().toString(): reader.read(),
    };

    final model = deserialize(map);

    // Model initialization is necessary here as `DataModel`s
    // auto-initialization is not ready at this point
    // (reading adapters during FD initialization)
    initModel(model);

    return model;
  }

  @override
  void write(writer, T obj) {
    final map = serialize(obj, withRelationships: false);

    final keys = map.keys;
    writer.writeByte(keys.length);
    for (final k in keys) {
      writer.write(k);
      writer.write(map[k]);
    }
  }
}
