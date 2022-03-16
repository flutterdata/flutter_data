part of flutter_data;

/// Hive implementation of [LocalAdapter] and Hive's [TypeAdapter].
// ignore: must_be_immutable
abstract class HiveLocalAdapter<T extends DataModel<T>> extends LocalAdapter<T>
    with TypeAdapter<T> {
  HiveLocalAdapter(Reader read)
      : _hiveLocalStorage = read(hiveLocalStorageProvider),
        super(read);

  final HiveLocalStorage _hiveLocalStorage;

  final _hiveAdapterNs = '_adapter_hive';
  String get _hiveAdapterKey => StringUtils.namespace(_hiveAdapterNs, 'key');

  String get _internalType => DataHelpers.getType<T>();

  @protected
  @visibleForTesting
  Box<T>? box;

  @override
  Future<HiveLocalAdapter<T>> initialize() async {
    if (isInitialized) return this;

    if (!_hiveLocalStorage.hive.isBoxOpen(_internalType)) {
      if (!_hiveLocalStorage.hive.isAdapterRegistered(typeId)) {
        _hiveLocalStorage.hive.registerAdapter(this);
      }
      if (_hiveLocalStorage.clear) {
        await _hiveLocalStorage.deleteBox(_internalType);
      }
    }

    try {
      box = await _hiveLocalStorage.openBox<T>(_internalType);
    } catch (e) {
      await _hiveLocalStorage.deleteBox(_internalType);
      box = await _hiveLocalStorage.openBox<T>(_internalType);
    }

    return this;
  }

  @override
  bool get isInitialized => box?.isOpen ?? false;

  @override
  void dispose() {
    box?.close();
  }

  // protected API

  @override
  List<T> findAll() {
    return box!.values.toImmutableList();
  }

  @override
  T? findOne(String key) => box!.get(key);

  @override
  Future<T> save(String key, T model, {bool notify = true}) async {
    final keyExisted = box!.containsKey(key);
    final save = box!.put(key, model);
    if (notify) {
      graph._notify(
        [key],
        keyExisted ? DataGraphEventType.updateNode : DataGraphEventType.addNode,
      );
    }
    await save;
    return model;
  }

  @override
  Future<void> delete(String key) async {
    final delete = box!.delete(key); // delete in bg
    // id will become orphan & purged
    graph.removeKey(key);
    await delete;
  }

  @override
  Future<void> clear() async {
    await box!.clear();
  }

  // hive adapter

  @override
  int get typeId {
    // _adapter_hive:key: {
    //   '_adapter_hive:posts': ['_adapter_hive:1'],
    //   '_adapter_hive:comments': ['_adapter_hive:2'],
    //   '_adapter_hive:houses': ['_adapter_hive:3'],
    // }

    if (!graph._hasNode(_hiveAdapterKey)) {
      graph._addNode(_hiveAdapterKey);
    }

    final _typesNode = graph._getNode(_hiveAdapterKey)!;

    final edge =
        _typesNode[StringUtils.namespace(_hiveAdapterNs, _internalType)];

    if (edge != null && edge.isNotEmpty) {
      // first is of format: _adapter_hive:1
      return int.parse(edge.first.denamespace());
    }

    // get namespaced indices
    final index = _typesNode.values
            // denamespace and parse single
            .map((e) => int.parse(e.first.denamespace()))
            // find max
            .fold(0, max) +
        1;

    graph._addEdge(_hiveAdapterKey,
        StringUtils.namespace(_hiveAdapterNs, index.toString()),
        metadata: StringUtils.namespace(_hiveAdapterNs, _internalType));
    return index;
  }

  @override
  T read(reader) {
    // read key first
    final key = reader.read().toString();

    // read attributes (no relationships stored)
    final total = reader.readByte();
    final map = <String, dynamic>{
      for (var i = 0; i < total; i++) reader.read().toString(): reader.read(),
    };

    // reconstruct relationship information from graph
    for (final entry in relationshipsFor().entries) {
      // entry keys are the name of relationships => metadata
      final name = entry.value['name']! as String;
      final relKeys = graph._getEdge(key, metadata: name);
      map[name] =
          entry.value['kind'] == 'BelongsTo' ? relKeys.safeFirst : relKeys;
    }

    return deserialize(map);
  }

  @override
  void write(writer, T obj) {
    final _map = serialize(obj);
    // write key first
    writer.write(obj._key);

    // exclude relationships
    final keys = _map.keys.where((k) => !relationshipsFor().containsKey(k));
    writer.writeByte(keys.length);
    for (final k in keys) {
      writer.write(k);
      writer.write(_map[k]);
    }
  }
}
