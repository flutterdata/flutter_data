import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

class GraphEvent {
  const GraphEvent({this.keys, this.graph});
  final Iterable<String> keys;
  final DataGraph graph;
}

class GraphNotifier extends StateNotifier<GraphEvent> {
  GraphNotifier(DataGraph graph)
      : _graph = graph,
        super(GraphEvent(keys: []));

  final DataGraph _graph;

  // this layer translates keys/ids and adds metadata to edges

  String addNode(String key) {
    if (_graph.addNode(key)) {
      state = GraphEvent(keys: [key], graph: _graph);
      return key;
    }
    return null;
  }

  void removeNode(String key) {
    if (_graph.removeNode(key)) {
      state = GraphEvent(keys: [key], graph: _graph);
    }
  }

  void add(String from, String to, {String metadata, String inverseMetadata}) {
    if (_graph.add(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata)) {
      state = GraphEvent(keys: [from, to], graph: _graph);
    }
  }

  void remove(String from, String to,
      {String metadata, String inverseMetadata}) {
    if (_graph.remove(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata)) {
      state = GraphEvent(keys: [from, to], graph: _graph);
    }
  }

  void addAll(String from, Iterable<String> tos,
      {String metadata, String inverseMetadata}) {
    for (var to in tos) {
      add(from, to, metadata: metadata, inverseMetadata: inverseMetadata);
    }
    state = GraphEvent(keys: [...tos, from], graph: _graph);
  }

  void removeAll(String from, {String metadata}) {
    final tos = _graph.get(from, metadata: metadata)?.toSet(); // make a copy
    if (tos != null) {
      for (var to in tos) {
        remove(from, to);
      }
      state = GraphEvent(
        keys: [...tos, from],
        graph: _graph,
      );
    }
  }

  void clear() {
    _graph.clear();
  }

  //

  String getId(String key) {
    final tos = _graph.get(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (tos.first.split('#')..removeAt(0)).join('#');
  }

  void removeKey(String key) {
    final tos = _graph.get(key, metadata: 'id');
    if (tos.isNotEmpty) {
      remove(key, tos.first, metadata: 'id');
    }
  }

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    assert(id != null);
    final nodeId = '$type#$id';
    final tos = _graph.get(nodeId, metadata: '_key');
    if (tos != null && tos.isNotEmpty) {
      return tos.first;
    }
    if (keyIfAbsent != null) {
      removeAll(keyIfAbsent, metadata: 'id');
      add(keyIfAbsent, nodeId, metadata: 'id', inverseMetadata: '_key');
      return keyIfAbsent;
    }
    return null;
  }

  Set<String> get<E>(String from, {String metadata}) {
    return _graph.get(from, metadata: metadata);
  }
}

// adapted from https://github.com/kevmoo/graph/
// under MIT license
// https://github.com/kevmoo/graph/blob/14c7f0cf000aeede1c55a3298990a7007b16a4dd/LICENSE

class DataGraph {
  final Map<String, _NodeImpl> _nodes;

  Iterable<String> get nodes => _nodes.keys;

  DataGraph._(this._nodes);

  @protected
  @visibleForTesting
  DataGraph() : this._(HashMap<String, _NodeImpl>());

  factory DataGraph.fromMap(Map<String, Map<String, Set<String>>> source) {
    final graph = DataGraph();

    for (var entry in source.entries) {
      final entryNode = graph._nodeFor(entry.key);
      final map = entry.value;

      // map = {posts: (p2, p1), host: (h1)},
      for (var group in map.entries) {
        // group.key = posts
        // group.value = (p2, p1)
        graph._nodeFor(group.key);

        // restore IDs (= keys starting with _) stripped out in serialization
        if (group.key == 'id' && group.value.isNotEmpty) {
          final idNode = graph._nodeFor(group.value.first);
          idNode.addEdge(entry.key, metadata: '_key');
        }

        for (var to in group.value) {
          // to = p2
          // group.key = posts
          entryNode.addEdge(to, metadata: group.key);
        }
      }
    }
    return graph;
  }

  bool addNode(String key) {
    assert(key != null, 'node cannot be null');
    final existingCount = _nodes.length;
    _nodeFor(key);
    return existingCount < _nodes.length;
  }

  bool removeNode(String key) {
    final node = _nodes.remove(key);

    if (node == null) {
      return false;
    }

    // find all edges coming into `node` - and remove them
    for (var otherNode in _nodes.values) {
      assert(otherNode != node);
      for (final metadata in otherNode.keys.toSet()) {
        otherNode.removeEdge(key, metadata: metadata);
      }
    }

    return true;
  }

  bool connected(String a, String b) {
    final nodeA = _nodes[a];
    if (nodeA == null) {
      return false;
    }
    return nodeA.containsKey(b) || _nodes[b].containsKey(a);
  }

  bool add(String from, String to, {String metadata, String inverseMetadata}) {
    assert(from != null, 'from cannot be null');

    // ensure the `to` node exists
    _nodeFor(to);
    return _nodeFor(from).addEdge(to, metadata: metadata) &&
        _nodeFor(to).addEdge(from, metadata: inverseMetadata);
  }

  bool remove(String from, String to,
      {String metadata, String inverseMetadata}) {
    final fromNode = _nodes[from];
    final toNode = _nodes[to];

    if (fromNode == null || toNode == null) {
      return false;
    }
    return fromNode.removeEdge(to, metadata: metadata) &&
        toNode.removeEdge(from, metadata: inverseMetadata);
  }

  _NodeImpl _nodeFor(String nodeKey) {
    assert(nodeKey != null);
    final node = _nodes.putIfAbsent(nodeKey, () => _NodeImpl());
    return node;
  }

  void clear() {
    _nodes.clear();
  }

  Set<String> get(String from, {String metadata}) {
    final map = getAll(from);
    if (map != null) {
      return map[metadata];
    }
    return null;
  }

  Map<String, Set<String>> getAll(String from) {
    final map = _nodes[from];
    if (map == null) {
      return null;
    }
    return groupBy<MapEntry<String, String>, String>(
            map.entries, (entry) => entry.value)
        .map((key, value) => MapEntry(key, value.map((e) => e.key).toSet()));
  }

  Map<String, Map<String, Set<String>>> toMap({bool withKeys = false}) {
    return Map.fromEntries(
        _nodes.entries.map((e) => MapEntry(e.key, getAll(e.key))).where((e) {
      return e.value.isNotEmpty &&
          (withKeys
              ? true
              // remove entries like: people#1: {_key: {people#a1a1a1}}
              // that will be restored upon deserialization (if !withKeys)
              : !(e.value.length == 1 && e.value.keys.first == '_key'));
    }));
  }
}

class _NodeImpl extends UnmodifiableMapBase<String, String> {
  final Map<String, String> _map;

  _NodeImpl._(this._map);

  factory _NodeImpl() {
    final node = _NodeImpl._(HashMap<String, String>());
    return node;
  }

  bool addEdge(String to, {String metadata}) {
    assert(to != null);
    _map[to] = metadata;
    return true;
  }

  bool removeEdge(String to, {String metadata}) {
    _map.remove(to);
    return true;
  }

  @override
  String operator [](Object key) => _map[key.toString()];

  @override
  Iterable<String> get keys => _map.keys;
}
