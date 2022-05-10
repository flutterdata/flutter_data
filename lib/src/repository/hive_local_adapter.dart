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
  String get _hiveAdapterKey => 'key'.namespaceWith(_hiveAdapterNs);

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
    } catch (e, stackTrace) {
      print('[flutter_data] Box failed to open:\n$stackTrace');
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
  List<T>? findAll() {
    if (_isLocalStorageTouched) {
      return box?.values.toImmutableList();
    }
    return null;
  }

  @override
  T? findOne(String? key) {
    return box?.get(key);
  }

  @override
  Future<T> save(String key, T model, {bool notify = true}) async {
    if (box == null) return model;

    _touchLocalStorage();

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
  Future<void> delete(String key) async {
    if (box == null) return;
    final delete = box!.delete(key); // delete in bg
    // id will become orphan & purged
    graph.removeKey(key);
    await delete;
  }

  @override
  Future<void> clear() async {
    await box?.clear();
  }

  // Touching local storage means the box has received data;
  // this is used to know whether `findAll` should return
  // null, or its models (possibly empty)

  // _boxMetadata: {
  //   '_boxMetadata:touched': ['_'],
  // }

  @override
  bool get _isLocalStorageTouched {
    return graph._hasEdge('_boxMetadata', metadata: '_boxMetadata:touched');
  }

  @override
  void _touchLocalStorage() {
    graph._addEdge('_boxMetadata', '_',
        metadata: '_boxMetadata:touched', addNode: true, notify: false);
  }

  // hive adapter

  @override
  int get typeId {
    // _adapter_hive:key: {
    //   '_adapter_hive:posts': ['_adapter_hive:1'],
    //   '_adapter_hive:comments': ['_adapter_hive:2'],
    //   '_adapter_hive:houses': ['_adapter_hive:3'],
    // }

    final _typesNode =
        graph._getNode(_hiveAdapterKey, orAdd: true, notify: false)!;

    final edge = _typesNode[_internalType.namespaceWith(_hiveAdapterNs)];

    if (edge != null && edge.isNotEmpty) {
      // first is of format: _adapter_hive:1
      return int.parse(edge.first.denamespace());
    }

    // get namespaced indices
    final index = _typesNode.values
            // denamespace and parse single
            .map((e) => int.parse(e.first.denamespace()))
            // find max
            .fold(0, math.max) +
        1;

    graph._addEdge(
        _hiveAdapterKey, index.toString().namespaceWith(_hiveAdapterNs),
        metadata: _internalType.namespaceWith(_hiveAdapterNs), notify: false);
    return index;
  }

  @override
  T read(reader) {
    // read attributes (no relationships stored)
    final total = reader.readByte();
    final map = <String, dynamic>{
      for (var i = 0; i < total; i++) reader.read().toString(): reader.read(),
    };

    final model = deserialize(map);
    return model;
  }

  @override
  void write(writer, T obj) {
    final _map = serialize(obj, withRelationships: false);

    final keys = _map.keys;
    writer.writeByte(keys.length);
    for (final k in keys) {
      writer.write(k);
      writer.write(_map[k]);
    }
  }
}
