part of flutter_data;

// ignore: must_be_immutable
abstract class HiveLocalAdapter<T extends DataSupport<T>>
    extends LocalAdapter<T> with TypeAdapter<T> {
  HiveLocalAdapter(DataGraphNotifier graph) : super(graph);

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

    final storage = graph._hiveLocalStorage;

    if (!storage.hive.isBoxOpen(_type)) {
      storage.hive.registerAdapter(this);
    }
    box = await storage.hive
        .openBox<T>(_type, encryptionCipher: storage.encryptionCipher);

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
    final n = reader.readByte();
    final fields = <String, dynamic>{
      for (var i = 0; i < n; i++) reader.read().toString(): reader.read(),
    };
    return deserialize(fields);
  }

  @override
  void write(writer, T obj) {
    final _map = serialize(obj);
    writer.writeByte(_map.keys.length);
    for (final k in _map.keys) {
      writer.write(k);
      writer.write(_map[k]);
    }
  }
}
