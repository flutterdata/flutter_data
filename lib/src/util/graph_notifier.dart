import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

class GraphEvent {
  const GraphEvent({this.keys, this.removed = false, this.graph});
  final Iterable<String> keys;
  final bool removed;
  final DataGraph graph;
}

class GraphNotifier extends StateNotifier<GraphEvent> {
  GraphNotifier(Box<Map<String, String>> box)
      : _graph = DataGraph(box),
        super(GraphEvent(keys: [])) {
    super.onError = (error, stackTrace) {
      throw error;
    };
  }

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
      state = GraphEvent(keys: [key], removed: true, graph: _graph);
    }
  }

  void add(String from, String to, {String metadata, String inverseMetadata}) {
    if (_graph.add(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata)) {
      state = GraphEvent(keys: [from, to], graph: _graph);
    }
  }

  void remove(String from, String to, {bool notify = true}) {
    if (_graph.remove(from, to) && notify) {
      state = GraphEvent(keys: [from, to], removed: true, graph: _graph);
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
    final tos = _graph.getFor(from, metadata)?.toSet(); // make a copy
    if (tos != null) {
      for (var to in tos) {
        remove(from, to);
      }
      state = GraphEvent(
        keys: [...tos, from],
        removed: true,
        graph: _graph,
      );
    }
  }

  void clear() {
    _graph.clear();
  }

  //

  String getId(String key) {
    final tos = _graph.getFor(key, 'id');
    return tos == null || tos.isEmpty
        ? null
        : (tos.first.split('#')..removeAt(0)).join('#');
  }

  void removeKey(String key) {
    final tos = _graph.getFor(key, 'id');
    if (tos.isNotEmpty) {
      remove(key, tos.first);
    }
  }

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    assert(id != null);
    final nodeId = '$type#$id';
    final tos = _graph.getFor(nodeId, '_key');
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

  Set<String> getFor<E>(String from, String metadata) {
    return _graph.getFor(from, metadata);
  }
}

// heavily adapted from https://github.com/kevmoo/graph/
// under MIT license
// https://github.com/kevmoo/graph/blob/14c7f0cf000aeede1c55a3298990a7007b16a4dd/LICENSE

class DataGraph {
  @protected
  @visibleForTesting
  final Box<Map<String, String>> box;

  Iterable<String> get nodes => box.keys.cast();

  @protected
  @visibleForTesting
  DataGraph(this.box);

  bool addNode(String key) {
    assert(key != null, 'node cannot be null');
    final existingCount = box.length;
    _nodeFor(key);
    return existingCount < box.length;
  }

  bool removeNode(String key) {
    final fromNode = box.get(key);

    if (fromNode == null) {
      return false;
    } else {
      box.delete(key);
    }

    // sever all to/from edges
    for (var to in fromNode.keys) {
      final toNode = box.get(to);
      removeEdge(toNode, key);
      removeEdge(fromNode, to);
    }
    return true;
  }

  bool connected(String a, String b) {
    final nodeA = box.get(a);
    if (nodeA == null) {
      return false;
    }
    return nodeA.containsKey(b) || box.get(b).containsKey(a);
  }

  bool contains(String key) {
    return box.containsKey(key);
  }

  bool add(String from, String to, {String metadata, String inverseMetadata}) {
    final fromNode = _nodeFor(from);

    if (fromNode == null) {
      return false;
    }
    final toNode = _nodeFor(to);
    return addEdge(fromNode, to, metadata) &&
        addEdge(toNode, from, inverseMetadata);
  }

  bool remove(String from, String to) {
    final fromNode = box.get(from);
    final toNode = box.get(to);

    if (fromNode == null || toNode == null) {
      return false;
    }
    return removeEdge(fromNode, to) && removeEdge(toNode, from);
  }

  Map<String, String> _nodeFor(String nodeKey) {
    assert(nodeKey != null);
    var node = box.get(nodeKey);
    if (node == null) {
      node = {};
      box.put(nodeKey, node);
    }
    return node;
  }

  void clear() {
    box.clear();
  }

  Set<String> getFor(String from, String metadata) {
    final map = getAll(from);
    if (map != null) {
      return map[metadata];
    }
    return null;
  }

  Map<String, Set<String>> getAll(String from) {
    final fromNode = box.get(from);
    if (fromNode == null) {
      return null;
    }
    return groupBy<MapEntry<String, String>, String>(
            fromNode.entries, (entry) => entry.value)
        .map((key, value) => MapEntry(key, value.map((e) => e.key).toSet()));
  }

  bool addEdge(Map<String, String> node, String to, String metadata) {
    assert(to != null);
    node[to] = metadata;
    return true;
  }

  bool removeEdge(Map<String, String> node, String to) {
    return node.remove(to) != null;
  }

  Map<String, Map<String, String>> toMap() => box.toMap().cast();
}
