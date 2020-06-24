part of flutter_data;

/// Public API to the graph
mixin _DataGraph {
  DataGraphNotifier _graph;

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

  String getId(String key) {
    final tos = _graph.getEdge(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (denamespace(tos.first).split('#')..removeAt(0)).join('#');
  }

  void removeId(String type, dynamic id) => _graph.removeNode('id:$type#$id');

  ///

  void addNode(String namespace, String key) {
    assert(!namespace.contains(':') && !key.contains(':'));
    _graph.addNode('$namespace:$key');
  }

  List<Map<String, List<String>>> getNodes(String namespace) {
    return _graph.getNodes(namespace);
  }

  Map<String, List<String>> getNode(String namespace, String key) {
    return _graph.getNode('$namespace:$key');
  }

  bool hasNode(String namespace, String key) {
    return _graph.hasNode('$namespace:$key');
  }

  void removeNode(String namespace, String key) {
    return _graph.removeNode('$namespace:$key');
  }

  String denamespace(String namespacedKey) => namespacedKey.split(':').last;

  //

  Map<String, Object> dumpGraph() => _graph.toMap();

  @visibleForTesting
  @protected
  void removeKey(String key) => _graph.removeNode(key);

  @visibleForTesting
  @protected
  void debugClearGraph() => _graph.clear();

  @visibleForTesting
  @protected
  set debugGraph(DataGraphNotifier value) => _graph = value;
}
