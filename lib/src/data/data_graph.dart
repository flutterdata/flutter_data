part of flutter_data;

/// Public API to the graph
mixin _DataGraph {
  DataGraphNotifier _graph;

  // key

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    type = Repository.getType(type);
    if (id != null) {
      final _id = 'id:$type#$id';

      if (_graph.getNode(_id) != null) {
        final tos = _graph.getEdge(_id, metadata: 'key');
        if (tos != null && tos.isNotEmpty) {
          final key = tos.first;
          return key;
        }
      }

      if (keyIfAbsent != null) {
        // this means the method is instructed to
        // create nodes and edges

        if (!_graph.hasNode(keyIfAbsent)) {
          _graph.addNode(keyIfAbsent, notify: false);
        }
        if (!_graph.hasNode(_id)) {
          _graph.addNode(_id, notify: false);
        }
        _graph.removeEdges(keyIfAbsent,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        _graph.addEdge(keyIfAbsent, _id,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      // if no ID is supplied but keyIfAbsent is, create node for key
      if (!_graph.hasNode(keyIfAbsent)) {
        _graph.addNode(keyIfAbsent, notify: false);
      }
      return keyIfAbsent;
    }
    return null;
  }

  void removeKey(String key) => _graph.removeNode(key);

  // id

  String getId(String key) {
    final tos = _graph.getEdge(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (denamespace(tos.first).split('#')..removeAt(0)).join('#');
  }

  void removeId(String type, dynamic id) => _graph.removeNode('id:$type#$id');

  // other namespaced

  // nodes

  void _assertKey(String key) {
    if (key != null) {
      assert(key.split(':').length == 2);
    }
  }

  void addNode(String key, {bool notify = true}) {
    _assertKey(key);
    _graph.addNode(key, notify: notify);
  }

  Map<String, List<String>> getNode(String key) {
    _assertKey(key);
    return _graph.getNode(key);
  }

  bool hasNode(String key) {
    _assertKey(key);
    return _graph.hasNode(key);
  }

  void removeNode(String key) {
    _assertKey(key);
    return _graph.removeNode(key);
  }

  // edges

  List<String> getEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _graph.getEdge(key, metadata: metadata);
  }

  void addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _graph.addEdge(from, to,
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
    return _graph.removeEdges(from,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  void removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(metadata);
    _assertKey(inverseMetadata);
    return _graph.removeEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  bool hasEdge(String key, {@required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _graph.hasEdge(key, metadata: metadata);
  }

  String denamespace(String namespacedKey) => namespacedKey.split(':').last;

  // debug utilities

  Map<String, Object> dumpGraph() => _graph.toMap();

  @visibleForTesting
  @protected
  void debugClearGraph() => _graph.clear();

  @visibleForTesting
  @protected
  set debugGraph(DataGraphNotifier value) => _graph = value;
}
