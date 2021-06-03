part of flutter_data;

const _kGraphBoxName = '_graph';

/// A bidirected graph data structure that notifies
/// modification events through a [StateNotifier].
///
/// It's a core framework component as it holds all
/// relationship information.
///
/// Watchers like [Repository.watchAll] or [BelongsTo.watch]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class GraphNotifier extends StateNotifier<DataGraphEvent>
    with _Lifecycle<GraphNotifier> {
  @protected
  GraphNotifier(this._hiveLocalStorage) : super(null);

  final HiveLocalStorage _hiveLocalStorage;

  @protected
  Box<Map> box;
  bool _doAssert = true;

  /// Initializes Hive local storage and box it depends on
  @override
  Future<GraphNotifier> initialize() async {
    if (isInitialized) return this;
    await _hiveLocalStorage.initialize();
    if (_hiveLocalStorage.clear ?? false) {
      await _hiveLocalStorage.deleteBox(_kGraphBoxName);
    }
    box = await _hiveLocalStorage.openBox(_kGraphBoxName);

    await super.initialize();
    return this;
  }

  Future<void> clear() async {
    return await box.clear();
  }

  @override
  bool get isInitialized => box != null && box.isOpen;

  // key-related methods

  /// Finds a model's key in the graph.
  ///
  ///  - Attempts a lookup by [type]/[id] (these are allowed to be `null`)
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    type = DataHelpers.getType(type);
    if (id != null) {
      final namespacedId =
          StringUtils.namespace('id', StringUtils.typify(type, id));

      if (_getNode(namespacedId) != null) {
        final tos = _getEdge(namespacedId, metadata: 'key');
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
        if (!_hasNode(namespacedId)) {
          _addNode(namespacedId, notify: false);
        }
        _removeEdges(keyIfAbsent,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        _addEdge(keyIfAbsent, namespacedId,
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

  /// Removes key (and its edges) from graph
  void removeKey(String key) => _removeNode(key);

  /// Finds an ID in the graph, given a [key].
  String getIdForKey(String key) {
    final tos = _getEdge(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (tos.first).denamespace().detypify();
  }

  /// Removes [type]/[id] (and its edges) from graph
  void removeId(String type, dynamic id) =>
      _removeNode(StringUtils.namespace('id', StringUtils.typify(type, id)));

  // nodes

  void _assertKey(String key) {
    if (_doAssert && key != null) {
      assert(key.split(':').length == 2);
    }
  }

  /// Adds a node, [key] MUST be namespaced (e.g. `manager:key`)
  void addNode(String key, {bool notify = true}) {
    _assertKey(key);
    _addNode(key, notify: notify);
  }

  /// Adds nodes, all [keys] MUST be namespaced (e.g. `manager:key`)
  void addNodes(Iterable<String> keys, {bool notify = true}) {
    for (final key in keys) {
      _assertKey(key);
    }
    _addNodes(keys, notify: notify);
  }

  /// Obtains a node, [key] MUST be namespaced (e.g. `manager:key`)
  Map<String, List<String>> getNode(String key) {
    _assertKey(key);
    return _getNode(key);
  }

  /// Returns whether [key] is present in this graph.
  ///
  /// [key] MUST be namespaced (e.g. `manager:key`)
  bool hasNode(String key) {
    _assertKey(key);
    return _hasNode(key);
  }

  /// Removes a node, [key] MUST be namespaced (e.g. `manager:key`)
  void removeNode(String key) {
    _assertKey(key);
    return _removeNode(key);
  }

  // edges

  /// See [addEdge]
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

  /// Returns edge by [metadata]
  ///
  /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
  List<String> getEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _getEdge(key, metadata: metadata);
  }

  /// Adds a bidirectional edge:
  ///
  ///  - [from]->[to] with [metadata]
  ///  - [to]->[from] with [inverseMetadata]
  ///
  /// [from], [metadata] & [inverseMetadata] MUST be namespaced (e.g. `manager:key`)
  void addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _addEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  /// See [removeEdge]
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

  /// Removes a bidirectional edge:
  ///
  ///  - [from]->[to] with [metadata]
  ///  - [to]->[from] with [inverseMetadata]
  ///
  /// [from], [metadata] & [inverseMetadata] MUST be namespaced (e.g. `manager:key`)
  void removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _removeEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  /// Returns whether the requested edge is present in this graph.
  ///
  /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
  bool hasEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _hasEdge(key, metadata: metadata);
  }

  /// Removes orphan nodes (i.e. nodes without edges)
  @protected
  @visibleForTesting
  void removeOrphanNodes() {
    final orphanEntries = {...toMap()}.entries.where((e) => e.value.isEmpty);
    for (final e in orphanEntries) {
      _removeNode(e.key);
    }
  }

  // utils

  /// Returns a [Map] representation of this graph, the underlying Hive [box].
  Map<String, Map> toMap() => _toMap();

  @protected
  @visibleForTesting
  void debugAssert(bool value) => _doAssert = value;

  // private API

  Map<String, List<String>> _getNode(String key) {
    assert(key != null, 'key cannot be null');
    return box.get(key)?.cast<String, List<String>>();
  }

  bool _hasNode(String key) {
    return box.containsKey(key);
  }

  List<String> _getEdge(String key, {@required String metadata}) {
    final node = _getNode(key);
    if (node != null) {
      return node[metadata] ?? [];
    }
    return [];
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
    // persist change
    box.put(from, fromNode);

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
        // persist change
        box.put(to, toNode);
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
      // persist change
      box.put(from, fromNode);
    } else {
      // tos == null as argument means ALL
      // remove metadata and retrieve all tos
      tos = fromNode.remove(metadata);
      // persist change
      box.put(from, fromNode);
    }

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...?tos],
        metadata: metadata,
        type: DataGraphEventType.removeEdge,
        graph: this,
      );
    }

    if (tos != null) {
      for (final to in tos) {
        final toNode = _getNode(to);
        if (toNode != null &&
            inverseMetadata != null &&
            toNode[inverseMetadata] != null) {
          toNode[inverseMetadata].remove(from);
          if (toNode[inverseMetadata].isEmpty) {
            toNode.remove(inverseMetadata);
          }
          // persist change
          box.put(to, toNode);
        }
        if (toNode == null || toNode.isEmpty) {
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

  Map<String, Map> _toMap() => box.toMap().cast();
}

enum DataGraphEventType {
  addNode,
  removeNode,
  updateNode,
  addEdge,
  removeEdge,
  updateEdge,
  doneLoading,
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
  final GraphNotifier graph;

  @override
  String toString() {
    return '[GraphEvent] $type: $keys';
  }
}

final graphNotifierProvider = Provider<GraphNotifier>((ref) {
  return GraphNotifier(ref.read(hiveLocalStorageProvider));
});
