part of flutter_data;

// ignore: must_be_immutable
abstract class HiveLocalAdapter<T extends DataSupport<T>>
    extends LocalAdapter<T> with TypeAdapter<T> {
  HiveLocalAdapter(this._hiveLocalStorage, DataGraphNotifier graph)
      : super(graph);

  final HiveLocalStorage _hiveLocalStorage;
  final _type = DataHelpers.getType<T>();

  // late final field, remove ignore on class
  @protected
  @visibleForTesting
  Box<T> box;

  @override
  Future<HiveLocalAdapter<T>> initialize() async {
    if (isInitialized) return this;
    // IMPORTANT: initialize graph before registering
    await super.initialize();

    if (!_hiveLocalStorage.hive.isBoxOpen(_type)) {
      _hiveLocalStorage.hive.registerAdapter(this);
    }
    box = await _hiveLocalStorage.hive.openBox<T>(_type,
        encryptionCipher: _hiveLocalStorage.encryptionCipher);

    return this;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await box?.close();
  }

  // protected API

  @override
  List<T> findAll() {
    return box.values.toImmutableList();
  }

  @override
  T findOne(String key) => key != null ? box.get(key) : null;

  @override
  void save(String key, T model, {bool notify = true}) {
    assert(key != null);
    final keyExisted = box.containsKey(key);
    box.put(key, model); // save in bg
    if (notify) {
      graph._notify(
        [key],
        keyExisted ? DataGraphEventType.updateNode : DataGraphEventType.addNode,
      );
    }
  }

  @override
  void delete(String key) {
    if (key != null) {
      box.delete(key); // delete in bg
      // id will become orphan & purged
      graph.removeKey(key);
    }
  }

  // hive adapter

  @override
  int get typeId {
    // _types: {
    //   'posts': {'1'},
    //   'comments': {'2'},
    //   'houses': {'3'},
    // }

    if (!graph.hasNode('hive:adapter')) {
      graph.addNode('hive:adapter');
    }

    final _typesNode = graph.getNode('hive:adapter');

    if (_typesNode[_type] != null && _typesNode[_type].isNotEmpty) {
      return int.parse(_typesNode[_type].first);
    }

    final index = _typesNode.length + 1;
    // insert at last position of _typesNode map
    _typesNode[_type] = [index.toString()];
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
      final name = entry.key;
      final relKeys = graph.getEdge(key, metadata: name);
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
