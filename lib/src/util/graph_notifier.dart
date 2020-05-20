import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

class GraphNotifier extends StateNotifier<DataGraph> {
  GraphNotifier() : super(DataGraph());

  // this layer translates keys/ids
  // tags rel names

  void add(String fromNode, [String toNode]) {
    if (toNode == null) {
      state.addNode(fromNode);
    } else {
      state.addEdge(fromNode, toNode);
    }
    state = state;
  }

  void remove(String fromNode, [String toNode]) {
    state.removeEdge(fromNode, toNode);
    state = state;
  }

  void addAll(String fromNode, Iterable<String> toNodes) {
    for (var toNode in toNodes) {
      add(fromNode, toNode);
    }
  }

  void removeAllFor(String fromNode, String type) {
    for (var toNode in relationshipKeysFor(fromNode, type)) {
      remove(fromNode, toNode);
    }
  }

  //

  String getId(String key) {
    final edges = state.edgesFrom(key);
    final id = edges?.firstWhere((e) => e.startsWith('_'), orElse: () => null);
    return id != null ? (id.split('#')..removeAt(0)).join('#') : null;
  }

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    assert(!id.toString().startsWith('_'));

    final nodeId = '_$type#$id';
    final edges = state.edgesFrom(nodeId);
    if (edges != null && edges.isNotEmpty) {
      return edges.first;
    }
    if (keyIfAbsent != null) {
      add(keyIfAbsent, nodeId);
      return keyIfAbsent;
    }
    return null;
  }

  void deleteKey(String key) {
    state.removeNode(key);
  }

  Set<String> relationshipKeysFor<E>(String fromNode, String type) => state
      .edgesFrom(fromNode)
      .where((key) => key.startsWith('$type#'))
      .toSet();
}

// adapted from https://github.com/kevmoo/graph/
// under MIT license
// https://github.com/kevmoo/graph/blob/14c7f0cf000aeede1c55a3298990a7007b16a4dd/LICENSE

class DataGraph {
  final Map<String, _NodeImpl> _nodes;
  final Map<String, Map<String, String>> mapView;

  int get nodeCount => _nodes.length;

  Iterable<String> get nodes => _nodes.keys;

  int get edgeCount => _nodes.values.expand((n) => n.values).length;

  DataGraph._(this._nodes) : mapView = UnmodifiableMapView(_nodes);

  @protected
  @visibleForTesting
  DataGraph() : this._(HashMap<String, _NodeImpl>());

  factory DataGraph.fromMap(Map<String, Map<String, Iterable<String>>> source) {
    final graph = DataGraph();

    for (var entry in source.entries) {
      final entryNode = graph._nodeFor(entry.key);
      final map = entry.value;

      // map = {posts: (p2, p1), host: (h1)},
      for (var group in map.entries) {
        // group.key = posts
        // group.value = (p2, p1)
        graph._nodeFor(group.key);

        if (group.key == 'id' && group.value.isNotEmpty) {
          final idNode = graph._nodeFor(group.value.first);
          idNode.addEdge(entry.key, '_key');
        }

        // restore IDs (= keys starting with _) stripped out in serialization
        for (var to in group.value) {
          // to = p2
          // group.key = posts (group.key is now the metadata)
          entryNode.addEdge(to, group.key);
        }
      }
    }
    return graph;
  }

  bool addNode(String key) {
    assert(key != null, 'node cannot be null');
    final existingCount = nodeCount;
    _nodeFor(key);
    return existingCount < nodeCount;
  }

  bool removeNode(String key) {
    final node = _nodes.remove(key);

    if (node == null) {
      return false;
    }

    // find all edges coming into `node` - and remove them
    for (var otherNode in _nodes.values) {
      assert(otherNode != node);
      otherNode.removeEdge(key);
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

  bool addEdge(String from, String to,
      {String metadata, String inverseMetadata}) {
    assert(from != null, 'from cannot be null');
    assert(to != null, 'to cannot be null');

    // ensure the `to` node exists
    _nodeFor(to);
    return _nodeFor(from).addEdge(to, metadata) &&
        _nodeFor(to).addEdge(from, inverseMetadata);
  }

  bool removeEdge(String from, String to) {
    final fromNode = _nodes[from];
    final toNode = _nodes[to];

    if (fromNode == null || toNode == null) {
      return false;
    }

    return fromNode.removeEdge(to) && toNode.removeEdge(from);
  }

  _NodeImpl _nodeFor(String nodeKey) {
    assert(nodeKey != null);
    final node = _nodes.putIfAbsent(nodeKey, () => _NodeImpl());
    return node;
  }

  void clear() {
    _nodes.clear();
  }

  /// Returns all of the nodes with edges from [node].
  Iterable<String> edgesFrom(String node, [String metadata]) {
    return _nodes[node].entries.where((e) {
      if (metadata != null) {
        return e.value == metadata;
      }
      return true;
    }).map((e) => e.key);
  }

  Map<String, Map<String, Iterable<String>>> toMap() => Map.fromEntries(
        _nodes.entries.map((entry) {
          final map = groupBy<MapEntry<String, String>, String>(
                  entry.value.entries, (entry) => entry.value)
              .map((key, value) => MapEntry(key, value.map((e) => e.key)));
          return MapEntry(entry.key, map);
        }).where((e) {
          // do not export IDs (entries containing _key) or empty metadata groups
          return e.value.isNotEmpty && !e.value.containsKey('_key');
        }),
      );
}

class _NodeImpl extends UnmodifiableMapBase<String, String> {
  final Map<String, String> _map;

  _NodeImpl._(this._map);

  factory _NodeImpl({Iterable<MapEntry<String, String>> edges}) {
    final node = _NodeImpl._(HashMap<String, String>());
    if (edges != null) {
      for (var e in edges) {
        node.addEdge(e.key, e.value);
      }
    }
    return node;
  }

  bool addEdge(String target, String data) {
    assert(target != null);
    _map.putIfAbsent(target, () => data);
    return true;
  }

  bool removeEdge(String target) {
    assert(target != null);
    return _map.remove(target) != null;
  }

  @override
  String operator [](Object key) => _map[key.toString()];

  @override
  Iterable<String> get keys => _map.keys;
}
