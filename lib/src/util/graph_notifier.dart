import 'dart:collection';
import 'package:state_notifier/state_notifier.dart';

class GraphNotifier extends StateNotifier<DirectedGraph<String, String>> {
  GraphNotifier(DirectedGraph<String, String> graph) : super(graph);

  void add(String key, [String to, bool isId = false]) {
    assert(key != null);
    if (to == null) {
      state.addNode(key);
    } else {
      assert(!to.startsWith('_'));
      if (isId) {
        to = '_$to';
      }
      state.addEdge(key, to);
      state.addEdge(to, key);
    }
    state = state;
  }

  void remove(String key, [String to, bool isId = false]) {
    assert(key != null);
    if (to == null) {
      state.removeNode(key);
    } else {
      assert(!to.startsWith('_'));
      if (isId) {
        to = '_$to';
      }
      state.removeEdge(key, to);
      state.removeEdge(to, key);
    }
    state = state;
  }

  String getId(String key) {
    final entries = state.findNode(key)?.entries;
    final e =
        entries.firstWhere((e) => e.key.startsWith('_'), orElse: () => null);
    return e?.key?.substring(1, e.key.length);
  }

  String getKey(String id, {String keyIfAbsent}) {
    final node = state.findNode('_$id');
    if (node != null && node.isNotEmpty) {
      return node.keys.first;
    }
    if (keyIfAbsent != null) {
      add(keyIfAbsent, id, true);
    }
    return null;
  }

  void deleteKey(String key) {
    state.removeNode(key);
  }
}

class RelNotifier extends StateNotifier<Set<String>> {
  RelNotifier({this.notifier, this.ownerKey}) : super({}) {
    notifier.add(ownerKey); // ensure key exists
    _disposeFn = notifier.addListener((graphState) {
      state = graphState.edgesFrom(ownerKey).toSet();
    });
  }
  final String ownerKey;
  final GraphNotifier notifier;
  RemoveListener _disposeFn;

  void add(String to, {String withKey}) {
    notifier.add(withKey ?? ownerKey, to);
  }

  void addAll(Iterable<String> tos) {
    for (var to in tos) {
      add(to);
    }
  }

  void remove(String to, {String withKey}) {
    notifier.remove(withKey ?? ownerKey, to);
  }

  void removeAll() {
    for (var to in relationshipKeys) {
      remove(to);
    }
  }

  void addId(String id, {String withKey}) {
    notifier.add(withKey ?? ownerKey, id, true);
  }

  void removeId(String id, {String withKey}) {
    notifier.remove(withKey ?? ownerKey, id, true);
  }

  String getId({String withKey}) {
    return notifier.getId(withKey ?? ownerKey);
  }

  String getKey({String id}) {
    return id != null ? notifier.getKey(id) : ownerKey;
  }

  Set<String> get relationshipKeys =>
      state.where((key) => !key.startsWith('_')).toSet();

  @override
  void dispose() {
    _disposeFn?.call();
    super.dispose();
  }
}

extension GraphNotifierX on GraphNotifier {
  RelNotifier notifierFor(String key) =>
      RelNotifier(notifier: this, ownerKey: key);
}

// void main() {
//   final _graph = DirectedGraph<String, String>();
//   var gn = GraphNotifier(_graph);
//   var b1 = gn.notifierFor('b1');
//   var p1 = gn.notifierFor('p1');

//   b1.addListener((keys) {
//     print('from b1: $keys');
//   });

//   p1.addListener((keys) {
//     print('from p1: $keys');
//   });

//   print('adding h1');
//   b1.add('h1');
//   print('adding p1');
//   b1.add('p1');
//   print('adding p2');
//   b1.add('p2');
//   print('adding id=1');
//   b1.addId('1');
//   print('adding p3');
//   b1.add('p3');

//   print('removing p1');
//   b1.remove('p1');

//   print('getting id for b1');
//   print(b1.getId());

//   print('getting key for id=1');
//   print(b1.getKey());

//   print('remove id=1');
//   b1.removeId('1');
//   b1.removeId('3');
//   b1.remove('aaasda');
//   // b1.removeLink('h1');
//   // b1.removeLink('p2');
//   // b1.removeLink('p3');

//   print('getting id for b1');
//   print(b1.getId());

//   print('getting key for id=1');
//   print(b1.getKey(id: '1'));

//   print('assign id=1 to b2 from graph');
//   gn.add('b2', '1', true);
//   // b1.addId('1');

//   print('get id for b1');
//   print(b1.getId());
//   print('get id for b2');
//   print(b1.getId(withKey: 'b2'));

//   print(gn.state.toMap());

//   var _g2 = DirectedGraph<String, String>.fromMap(gn.state.toMap());
//   var gn2 = GraphNotifier(_g2);

//   print(gn2.state.toMap());

//   var _b1 = gn2.notifierFor('b1');
//   print('get key for id=1 in graph2');
//   print(_b1.getKey(id: '1'));

//   _b1.addListener((keys) {
//     print('from _b1: $keys');
//   });
// }

// adapted from https://github.com/kevmoo/graph/
// under MIT license
// https://github.com/kevmoo/graph/blob/14c7f0cf000aeede1c55a3298990a7007b16a4dd/LICENSE

class DirectedGraph<K, E> {
  final Map<K, NodeImpl<K, E>> _nodes;
  final Map<K, Map<K, Set<E>>> mapView;

  // final HashHelper<K> _hashHelper;

  int get nodeCount => _nodes.length;

  Iterable<K> get nodes => _nodes.keys;

  int get edgeCount =>
      _nodes.values.expand((n) => n.values).expand((s) => s).length;

  DirectedGraph._(this._nodes) // , this._hashHelper
      : mapView = UnmodifiableMapView(_nodes);

  DirectedGraph({
    bool Function(K key1, K key2) equals,
    int Function(K key) hashCode,
  }) : this._(
          HashMap<K, NodeImpl<K, E>>(hashCode: hashCode, equals: equals),
          // HashHelper(equals, hashCode),
        );

  factory DirectedGraph.fromMap(Map<K, Object> source) {
    final graph = DirectedGraph<K, E>();

    MapEntry<K, E> fromMapValue(Object e) {
      if (e is Map &&
          e.length == 2 &&
          e.containsKey('target') &&
          e.containsKey('data')) {
        return MapEntry(e['target'] as K, e['data'] as E);
      }

      return MapEntry(e as K, null);
    }

    for (var entry in source.entries) {
      final entryNode = graph._nodeFor(entry.key);
      final edgeData = entry.value as List ?? const [];

      for (var to in edgeData.map(fromMapValue)) {
        graph._nodeFor(to.key);
        entryNode.addEdge(to.key, to.value);
        // restore IDs (= keys starting with _) stripped out in serialization
        if (to.key.toString().startsWith('_')) {
          final inverseNode = graph._nodeFor(to.key);
          inverseNode.addEdge(entry.key, to.value);
        }
      }
    }

    return graph;
  }

  bool addNode(K key) {
    // bool add(K key)
    assert(key != null, 'node cannot be null');
    final existingCount = nodeCount;
    _nodeFor(key);
    return existingCount < nodeCount;
  }

  bool removeNode(K key) {
    final node = _nodes.remove(key);

    if (node == null) {
      return false;
    }

    // find all edges coming into `node` - and remove them
    for (var otherNode in _nodes.values) {
      assert(otherNode != node);
      otherNode.removeAllEdgesTo(key);
    }

    return true;
  }

  bool connected(K a, K b) {
    final nodeA = _nodes[a];

    if (nodeA == null) {
      return false;
    }

    return nodeA.containsKey(b) || _nodes[b].containsKey(a);
  }

  bool addEdge(K from, K to, {E edgeData}) {
    assert(from != null, 'from cannot be null');
    assert(to != null, 'to cannot be null');

    // ensure the `to` node exists
    _nodeFor(to);
    return _nodeFor(from).addEdge(to, edgeData);
  }

  bool removeEdge(K from, K to, {E edgeData}) {
    final fromNode = _nodes[from];

    if (fromNode == null) {
      return false;
    }

    return fromNode.removeEdge(to, edgeData);
  }

  NodeImpl<K, E> _nodeFor(K nodeKey) {
    assert(nodeKey != null);
    final node = _nodes.putIfAbsent(nodeKey, () => NodeImpl());
    return node;
  }

  void clear() {
    _nodes.clear();
  }

  /// Returns all of the nodes with edges from [node].
  Iterable<K> edgesFrom(K node) {
    return _nodes[node]?.keys;
  }

  /// Returns [node].
  NodeImpl<K, E> findNode(K node) {
    return _nodes[node];
  }

  // removes: IDs (= keys starting with _) & orphan nodes from serialization
  Map<K, Object> toMap() => Map.fromEntries(_nodes.entries
      .map(_toMapValue)
      .where((e) => !e.key.toString().startsWith('_') && e.value.isNotEmpty));
}

MapEntry<Key, List<Object>> _toMapValue<Key>(
    MapEntry<Key, Map<Key, Set>> entry) {
  final nodeEdges = entry.value.entries.expand((e) {
    assert(e.value.isNotEmpty);
    return e.value.map((edgeData) {
      if (edgeData == null) {
        return e.key;
      }
      return {'target': e.key, 'data': edgeData};
    });
  }).toList();

  return MapEntry(entry.key, nodeEdges);
}

class NodeImpl<K, E> extends UnmodifiableMapBase<K, Set<E>> {
  final Map<K, Set<E>> _map;

  NodeImpl._(this._map);

  factory NodeImpl({Iterable<MapEntry<K, E>> edges}) {
    final node = NodeImpl._(
      HashMap<K, Set<E>>(
          // equals: hashHelper.equalsField,
          // hashCode: hashHelper.hashCodeField,
          ),
    );

    if (edges != null) {
      for (var e in edges) {
        node.addEdge(e.key, e.value);
      }
    }

    return node;
  }

  bool addEdge(K target, E data) {
    assert(target != null);
    return _map.putIfAbsent(target, _createSet).add(data);
  }

  Set<E> _createSet() => HashSet<E>();

  bool removeAllEdgesTo(K target) => _map.remove(target) != null;

  bool removeEdge(K target, E data) {
    assert(target != null);

    final set = _map[target];
    if (set == null) {
      return false;
    }
    try {
      return set.remove(data);
    } finally {
      if (set.isEmpty) {
        _map.remove(target);
      }
      assert(!_map.containsKey(target) || _map[target].isNotEmpty);
    }
  }

  @override
  Set<E> operator [](Object key) => _map[key];

  @override
  Iterable<K> get keys => _map.keys;
}
