import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:state_notifier/state_notifier.dart';

class DataGraphNotifier extends StateNotifier<DataGraphEvent> {
  DataGraphNotifier(this.box) : super(null);

  @protected
  @visibleForTesting
  final Box<Map<String, Set<String>>> box;

  // read

  Map<String, Set<String>> getNode(String key) {
    assert(key != null, 'key cannot be null');
    return box.get(key);
  }

  bool hasNode(String key) {
    return box.containsKey(key);
  }

  Set<String> getEdge(String key, {@required String metadata}) {
    final node = getNode(key);
    if (node != null) {
      return node[metadata];
    }
    return null;
  }

  bool hasEdge(String key, {@required String metadata}) {
    final fromNode = getNode(key);
    return fromNode?.keys?.contains(metadata) ?? false;
  }

  // write

  void addNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    if (!box.containsKey(key)) {
      box.put(key, {});
      if (notify) {
        state = DataGraphEvent(
            keys: [key], type: DataGraphEventType.addNode, graph: this);
      }
    }
  }

  void removeNode(String key, {bool notify = true}) {
    assert(key != null, 'key cannot be null');
    final fromNode = getNode(key);

    if (fromNode == null) {
      return;
    }

    // sever all incoming edges
    for (final toKey in connectedKeys(key)) {
      final toNode = getNode(toKey);
      // remove deleted key from all metadatas
      for (final entry in toNode.entries) {
        removeEdges(toKey, tos: [key], metadata: entry.key);
      }
    }

    box.delete(key);

    if (notify) {
      print('emitting deletion for $key');
      state = DataGraphEvent(
          keys: [key], type: DataGraphEventType.removeNode, graph: this);
    }
  }

  void addEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    addEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void addEdges(String from,
      {@required String metadata,
      @required Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = getNode(from);
    assert(fromNode != null && tos != null);

    fromNode[metadata] ??= {};
    fromNode[metadata].addAll(tos);
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
        final toNode = getNode(to);
        if (toNode != null) {
          toNode[inverseMetadata] ??= {};
          toNode[inverseMetadata].add(from);
        }
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

  void removeEdge(String from, String to,
      {@required String metadata, String inverseMetadata, bool notify = true}) {
    removeEdges(from,
        tos: [to],
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void removeEdges(String from,
      {@required String metadata,
      Iterable<String> tos,
      String inverseMetadata,
      bool notify = true}) {
    final fromNode = getNode(from);
    assert(fromNode != null);

    if (tos != null) {
      fromNode[metadata]?.removeAll(tos);
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
        final toNode = getNode(to);
        if (toNode != null) {
          toNode[inverseMetadata]?.remove(from);
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

  void notify(List<String> keys, DataGraphEventType type) {
    state = DataGraphEvent(
      type: type,
      keys: keys,
      graph: this,
    );
  }

  // key & id

  String getId(String key) {
    final tos = getEdge(key, metadata: 'id');
    return tos == null || tos.isEmpty
        ? null
        : (tos.first.split('#')..removeAt(0)).join('#');
  }

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    if (id != null) {
      final _id = '$type#$id';
      if (!hasNode(_id)) {
        addNode(_id, notify: false);
      }

      final tos = getEdge(_id, metadata: 'key');
      if (tos != null && tos.isNotEmpty) {
        final key = tos.first;
        return key;
      }

      if (keyIfAbsent != null) {
        if (!hasNode(keyIfAbsent)) {
          addNode(keyIfAbsent, notify: false);
        }
        removeEdges(keyIfAbsent,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        addEdge(keyIfAbsent, _id,
            metadata: 'id', inverseMetadata: 'key', notify: false);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      // if no ID is supplied but keyIfAbsent is, create node for key
      if (!hasNode(keyIfAbsent)) {
        addNode(keyIfAbsent, notify: false);
      }
      return keyIfAbsent;
    }
    return null;
  }

  // misc

  Set<String> connectedKeys(String key, {Iterable<String> metadatas}) {
    final node = getNode(key);
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

  void clear() {
    box.clear();
  }

  Map<String, Map<String, Set<String>>> toMap() => box.toMap().cast();
}

enum DataGraphEventType {
  addNode,
  removeNode,
  updateNode,
  addEdge,
  removeEdge,
  updateEdge
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
