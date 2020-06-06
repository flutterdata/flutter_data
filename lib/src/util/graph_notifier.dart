import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

enum GraphEventType { added, removed, updated }

class GraphEvent {
  const GraphEvent({this.keys, this.type = GraphEventType.added, this.graph});
  final Iterable<String> keys;
  final GraphEventType type;
  final DataGraph graph;
}

class GraphNotifier extends StateNotifier<GraphEvent> {
  GraphNotifier(Box<Map<String, String>> box)
      : _graph = DataGraph(box),
        super(null) {
    onError = Zone.current.handleUncaughtError;
  }

  final DataGraph _graph;

  // this layer translates keys/ids and adds metadata to edges

  String addNode(String key, {bool notify = true}) {
    if (_graph.addNode(key) && notify) {
      state = GraphEvent(keys: [key], graph: _graph);
      return key;
    }
    return null;
  }

  void removeNode(String key, {bool notify = true}) {
    if (_graph.removeNode(key) && notify) {
      state =
          GraphEvent(keys: [key], type: GraphEventType.removed, graph: _graph);
    }
  }

  void add(String from, String to,
      {String metadata, String inverseMetadata, bool notify = true}) {
    if (_graph.add(from, to,
            metadata: metadata, inverseMetadata: inverseMetadata) &&
        notify) {
      state = GraphEvent(keys: [from, if (to != null) to], graph: _graph);
    }
  }

  void notify(Iterable<String> keys, GraphEventType type) {
    if (keys.isNotEmpty) {
      state = GraphEvent(keys: keys, type: type, graph: _graph);
    }
  }

  void remove(String from, String to, {bool notify = true}) {
    if (_graph.remove(from, to) && notify) {
      state = GraphEvent(
          keys: [from, to], type: GraphEventType.removed, graph: _graph);
    }
  }

  void addAll(String from, Iterable<String> tos,
      {String metadata, String inverseMetadata, bool notify = true}) {
    for (var to in tos) {
      add(from, to,
          metadata: metadata, inverseMetadata: inverseMetadata, notify: false);
    }
    if (notify) {
      state = GraphEvent(keys: [...?tos, from], graph: _graph);
    }
  }

  void removeAll(String from, {String metadata, bool notify = true}) {
    final tos = _graph.getEdge(from, metadata)?.toSet(); // make a copy
    if (tos != null) {
      for (var to in tos) {
        remove(from, to, notify: false);
      }
      if (notify) {
        state = GraphEvent(
          keys: [...tos, from],
          type: GraphEventType.removed,
          graph: _graph,
        );
      }
    }
  }

  void clear() {
    _graph.clear();
  }

  //

  String getId(String key) {
    final tos = _graph.getEdge(key, 'id');
    return tos == null || tos.isEmpty
        ? null
        : (tos.first.split('#')..removeAt(0)).join('#');
  }

  // creates key and notifies ONLY if it doesn't exist
  String createKey(String key) => addNode(key, notify: false);

  void removeKey(String key) {
    final tos = _graph.getEdge(key, 'id');
    if (tos.isNotEmpty) {
      remove(key, tos.first, notify: false);
    }
  }

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    if (id != null) {
      final nodeId = '$type#$id';
      final tos = _graph.getEdge(nodeId, 'key');
      if (tos != null && tos.isNotEmpty) {
        final key = tos.first;
        return key;
      }
      if (keyIfAbsent != null) {
        removeAll(keyIfAbsent, metadata: 'id', notify: false);
        add(keyIfAbsent, nodeId,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      // if no ID is supplied but keyIfAbsent is, create node for key
      add(keyIfAbsent, null, metadata: 'id', notify: false);
      return keyIfAbsent;
    }
    return null;
  }

  Set<String> getEdge<E>(String from, String metadata) {
    return _graph.getEdge(from, metadata);
  }

  Map<String, Map<String, String>> toMap() => _graph.toMap();
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

    // sever all incoming edges
    for (var to in fromNode.keys) {
      final toNode = box.get(to);
      removeEdge(toNode, key);
    }
    return true;
  }

  bool connected(String a, String b) {
    final nodeA = box.get(a);
    final nodeB = box.get(b);
    if (nodeA == null || nodeB == null) {
      return false;
    }
    return nodeA.containsKey(b) || nodeB.containsKey(a);
  }

  bool contains(String key) {
    return box.containsKey(key);
  }

  bool add(String from, String to, {String metadata, String inverseMetadata}) {
    final fromNode = _nodeFor(from);

    if (fromNode == null) {
      return false;
    }
    if (to != null) {
      final toNode = _nodeFor(to);
      return addEdge(fromNode, to, metadata) &&
          addEdge(toNode, from, inverseMetadata);
    } else {
      return addEdge(fromNode, null, metadata);
    }
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

  Set<String> getEdge(String from, String metadata) {
    final map = getEdges(from);
    if (map != null) {
      return map[metadata];
    }
    return null;
  }

  Map<String, Set<String>> getEdges(String from) {
    final fromNode = box.get(from);
    if (fromNode == null) {
      return null;
    }
    return groupBy<MapEntry<String, String>, String>(
            fromNode.entries, (entry) => entry.value)
        .map((key, value) => MapEntry(key, value.map((e) => e.key).toSet()));
  }

  bool hasEdge(String from, String metadata) {
    final fromNode = box.get(from);
    return fromNode?.values?.contains(metadata);
  }

  bool addEdge(Map<String, String> node, String to, String metadata) {
    node[to] = metadata;
    return true;
  }

  bool removeEdge(Map<String, String> node, String to) {
    return node.remove(to) != null;
  }

  Map<String, Map<String, String>> toMap() => box.toMap().cast();
}
