part of flutter_data;

class DataGraphNotifier extends StateNotifier<DataGraphEvent>
    with _Lifecycle<DataGraphNotifier> {
  @protected
  DataGraphNotifier(this._hiveLocalStorage) : super(null);

  final HiveLocalStorage _hiveLocalStorage;

  @protected
  Box<Map<String, List<String>>> box;
  bool _doAssert = true;

  @override
  Future<DataGraphNotifier> initialize() async {
    if (isInitialized) return this;
    await _hiveLocalStorage.initialize();
    box = await _hiveLocalStorage.hive.openBox('_meta');

    await super.initialize();
    return this;
  }

  @override
  bool get isInitialized => box != null;

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  // key-related methods

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    type = DataHelpers.getType(type);
    if (id != null) {
      final _id = 'id:$type#$id';

      if (_getNode(_id) != null) {
        final tos = _getEdge(_id, metadata: 'key');
        if (tos != null && tos.isNotEmpty) {
          final key = tos.first;
          return key;
        }
      }

      if (keyIfAbsent != null) {
        // this means the method is instructed to
        // create nodes and edges

        if (!_hasNode(keyIfAbsent)) {
          _addNode(keyIfAbsent, notify: false);
        }
        if (!_hasNode(_id)) {
          _addNode(_id, notify: false);
        }
        _removeEdges(keyIfAbsent,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        _addEdge(keyIfAbsent, _id,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      // if no ID is supplied but keyIfAbsent is, create node for key
      if (!_hasNode(keyIfAbsent)) {
        _addNode(keyIfAbsent, notify: false);
      }
      return keyIfAbsent;
    }
    return null;
  }

  void removeKey(String key) => _removeNode(key);

  // id-related methods

  String getId(String key) {
    final tos = _getEdge(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (denamespace(tos.first).split('#')..removeAt(0)).join('#');
  }

  void removeId(String type, dynamic id) => _removeNode('id:$type#$id');

  // nodes

  void _assertKey(String key) {
    if (_doAssert && key != null) {
      assert(key.split(':').length == 2);
    }
  }

  void addNode(String key, {bool notify = true}) {
    _assertKey(key);
    _addNode(key, notify: notify);
  }

  void addNodes(Iterable<String> keys, {bool notify = true}) {
    for (final key in keys) {
      _assertKey(key);
    }
    _addNodes(keys, notify: notify);
  }

  Map<String, List<String>> getNode(String key) {
    _assertKey(key);
    return _getNode(key);
  }

  bool hasNode(String key) {
    _assertKey(key);
    return _hasNode(key);
  }

  void removeNode(String key) {
    _assertKey(key);
    return _removeNode(key);
  }

  // edges

  void addEdges(String from,
      {@required String metadata,
      @required Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    _addEdges(from,
        metadata: metadata, tos: tos, inverseMetadata: inverseMetadata);
  }

  List<String> getEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _getEdge(key, metadata: metadata);
  }

  void addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _addEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  void removeEdges(String from,
      {@required String metadata,
      Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _removeEdges(from,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  void removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _removeEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  bool hasEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _hasEdge(key, metadata: metadata);
  }

  String denamespace(String namespacedKey) => namespacedKey.split(':').last;

  // debug utilities

  Map<String, Object> dumpGraph() => _toMap();

  @visibleForTesting
  @protected
  void debugClearGraph() => _clear();

  @protected
  @visibleForTesting
  void debugAssert(bool value) => _doAssert = value;

  // PRIVATE API

  Map<String, List<String>> _getNode(String key) {
    assert(key != null, 'key cannot be null');
    return box.get(key);
  }

  bool _hasNode(String key) {
    return box.containsKey(key);
  }

  List<String> _getEdge(String key, {@required String metadata}) {
    final node = _getNode(key);
    if (node != null) {
      return node[metadata];
    }
    return null;
  }

  bool _hasEdge(String key, {@required String metadata}) {
    final fromNode = _getNode(key);
    return fromNode?.keys?.contains(metadata) ?? false;
  }

  // write

  void _addNodes(Iterable<String> keys, {bool notify = true}) {
    for (final key in keys) {
      _addNode(key, notify: notify);
    }
  }

  void _addNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    if (!box.containsKey(key)) {
      box.put(key, {});
      if (notify) {
        state = DataGraphEvent(
            keys: [key], type: DataGraphEventType.addNode, graph: this);
      }
    }
  }

  void _removeNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    final fromNode = _getNode(key);

    if (fromNode == null) {
      return;
    }

    // sever all incoming edges
    for (final toKey in _connectedKeys(key)) {
      final toNode = _getNode(toKey);
      // remove deleted key from all metadatas
      if (toNode != null) {
        for (final entry in toNode.entries.toSet()) {
          _removeEdges(toKey, tos: [key], metadata: entry.key);
        }
      }
    }

    box.delete(key);

    if (notify) {
      state = DataGraphEvent(
          keys: [key], type: DataGraphEventType.removeNode, graph: this);
    }
  }

  void _addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _addEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void _addEdges(String from,
      {@required String metadata,
      @required Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = _getNode(from);
    assert(fromNode != null && tos != null);

    if (tos.isEmpty) {
      return;
    }

    // use a set to ensure resulting list elements are unique
    fromNode[metadata] = {...?fromNode[metadata], ...tos}.toList();

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...tos],
        metadata: metadata,
        type: DataGraphEventType.addEdge,
        graph: this,
      );
    }

    if (inverseMetadata != null) {
      for (final to in tos) {
        // get or create toNode
        final toNode =
            _hasNode(to) ? _getNode(to) : (this.._addNode(to))._getNode(to);

        // use a set to ensure resulting list elements are unique
        toNode[inverseMetadata] = {...?toNode[inverseMetadata], from}.toList();
      }

      if (notify) {
        state = DataGraphEvent(
          keys: [...tos, from],
          metadata: inverseMetadata,
          type: DataGraphEventType.addEdge,
          graph: this,
        );
      }
    }
  }

  void _removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _removeEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void _removeEdges(String from,
      {@required String metadata,
      Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = _getNode(from);
    assert(fromNode != null);

    if (tos != null && fromNode[metadata] != null) {
      // remove all tos from fromNode[metadata]
      fromNode[metadata].removeWhere(tos.contains);
      if (fromNode[metadata].isEmpty) {
        fromNode.remove(metadata);
      }
    } else {
      // tos == null as argument means ALL
      // remove metadata and retrieve all tos
      tos = fromNode.remove(metadata);
    }

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...?tos],
        metadata: metadata,
        type: DataGraphEventType.removeEdge,
        graph: this,
      );
    }

    if (tos != null && inverseMetadata != null) {
      for (final to in tos) {
        final toNode = _getNode(to);
        if (toNode != null && toNode[inverseMetadata] != null) {
          toNode[inverseMetadata].remove(from);
          if (toNode[inverseMetadata].isEmpty) {
            toNode.remove(inverseMetadata);
          }
        }
        if (toNode.isEmpty) {
          _removeNode(to, notify: notify);
        }
      }

      if (notify) {
        state = DataGraphEvent(
          keys: [...tos, from],
          metadata: inverseMetadata,
          type: DataGraphEventType.removeEdge,
          graph: this,
        );
      }
    }
  }

  void _notify(List<String> keys, DataGraphEventType type) {
    state = DataGraphEvent(
      type: type,
      keys: keys,
      graph: this,
    );
  }

  // misc

  Set<String> _connectedKeys(String key, {Iterable<String> metadatas}) {
    final node = _getNode(key);
    if (node == null) {
      return {};
    }

    return node.entries.fold({}, (acc, entry) {
      if (metadatas != null && !metadatas.contains(entry.key)) {
        return acc;
      }
      return acc..addAll(entry.value);
    });
  }

  void _clear() {
    box.clear();
  }

  Map<String, Map<String, List<String>>> _toMap() => box.toMap().cast();
}

enum DataGraphEventType {
  addNode,
  removeNode,
  updateNode,
  addEdge,
  removeEdge,
  updateEdge
}

extension DataGraphEventTypeX on DataGraphEventType {
  bool get isNode => [
        DataGraphEventType.addNode,
        DataGraphEventType.updateNode,
        DataGraphEventType.removeNode,
      ].contains(this);
  bool get isEdge => [
        DataGraphEventType.addEdge,
        DataGraphEventType.updateEdge,
        DataGraphEventType.removeEdge,
      ].contains(this);
}

class DataGraphEvent {
  const DataGraphEvent({
    this.keys,
    this.metadata,
    this.type,
    this.graph,
  });
  final List<String> keys;
  final String metadata;
  final DataGraphEventType type;
  final DataGraphNotifier graph;

  @override
  String toString() {
    return '[GraphEvent] $type: $keys';
  }
}

final graphProvider = Provider<DataGraphNotifier>((ref) {
  return DataGraphNotifier(ref.read(hiveLocalStorageProvider));
});
