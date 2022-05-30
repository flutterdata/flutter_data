part of flutter_data;

/// A bidirected graph data structure that notifies
/// modification events through a [StateNotifier].
///
/// It's a core framework component as it holds all
/// relationship information.
///
/// Watchers like [Repository.watchAllNotifier]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class GraphNotifier extends DelayedStateNotifier<DataGraphEvent> {
  final Reader read;
  @protected
  GraphNotifier(this.read);

  IsarCollection<_GraphEdge> get _collection =>
      read(isarLocalStorageProvider)._isar!.getCollection();

  bool _doAssert = true;

  Future<void> clear() async {
    await _collection.clear();
  }

  // key-related methods

  /// Finds a model's key in the graph.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  int? getKeyForId(String type, Object? id, {String? keyIfAbsent}) {
    type = DataHelpers.getType(type);
    // if (id != null) {
    //   final namespace = id is int ? '_id_int' : '_id';
    //   final namespacedId =
    //       id.toString().typifyWith(type).namespaceWith(namespace);

    //   final key = _getEdge(namespacedId, metadata: '_key')?.tos.safeFirst;
    //   if (key != null) return key;

    //   if (keyIfAbsent != null) {
    //     _removeEdge(keyIfAbsent,
    //         metadata: '_id', inverseMetadata: '_key', notify: false);
    //     _addEdge(keyIfAbsent,
    //         metadata: '_id',
    //         inverseMetadata: '_key',
    //         tos: [namespacedId],
    //         notify: false);
    //     return keyIfAbsent;
    //   }
    // } else if (keyIfAbsent != null) {
    //   // if no ID is supplied but keyIfAbsent is, create node for key
    //   // _addNode(keyIfAbsent, notify: false);
    //   return keyIfAbsent;
    // }
    return null;
  }

  // /// Removes key (and its edges) from graph
  // void removeKey(String key) => _removeNode(key);

  /// Finds an ID in the graph, given a [key].
  Object? getIdForKey(String key) {
    return null;
    // final edge = _getEdge(key, metadata: '_id');
    // if (edge?.tos.isEmpty ?? true) {
    //   return null;
    // }
    // final isInt = edge!.tos.first.namespace == '_id_int';
    // final id = edge.tos.first.denamespace().detypify();
    // return isInt ? int.tryParse(id) : id;
  }

  // /// Removes [type]/[id] (and its edges) from graph
  // void removeId(String type, Object id, {bool notify = true}) =>
  //     _removeNode(id.toString().typifyWith(type).namespaceWith('_id'),
  //         notify: notify);

  // nodes

  void _assertKey(String key) {
    if (_doAssert) {
      if (key.split(':').length != 2 || key.startsWith('_')) {
        throw AssertionError('''
Key "$key":
  - Key must be namespaced (my:key)
  - Key can't contain a colon (my:precious:key)
  - Namespace can't start with an underscore (_my:key)
''');
      }
    }
  }

  /// Obtains a node (i.e. list of edges)
  List<_GraphEdge> getNode(String key, {bool notify = true}) {
    return _getNode(key, notify: notify);
  }

  /// Removes a node, [key] MUST be namespaced (e.g. `manager:key`)
  void removeNode(String key) {
    _assertKey(key);
    return _removeNode(key);
  }

  // edges

  /// See [addEdges]
  void addEdges(String from,
      {required String metadata,
      required Iterable<String> tos,
      String? inverseMetadata,
      bool addNode = false,
      bool notify = true}) {
    _assertKey(from);
    for (final to in tos) {
      _assertKey(to);
    }
    _assertKey(metadata);
    if (inverseMetadata != null) {
      _assertKey(inverseMetadata);
    }
    _addEdges(from,
        tos: tos, metadata: metadata, inverseMetadata: inverseMetadata);
  }

  /// Returns edge by [metadata]
  ///
  /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
  Iterable<_GraphEdge> getEdges(String key, {required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _getEdges(key, metadata: metadata);
  }

  /// See [removeEdge]
  void removeEdge(String from,
      {required String metadata,
      required String to,
      String? inverseMetadata,
      bool notify = true}) {
    _assertKey(from);
    // for (final to in tos) {
    _assertKey(to);
    // }
    _assertKey(metadata);
    if (inverseMetadata != null) {
      _assertKey(inverseMetadata);
    }
    return _removeEdge(from,
        to: to,
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  /// Returns whether the requested edge is present in this graph.
  ///
  /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
  bool hasEdge(String key, {required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _hasEdge(key, metadata: metadata);
  }

  // utils

  /// Returns a [Map] representation of this graph.
  Map<String, Map> toMap() => _toMap();

  @protected
  @visibleForTesting
  void debugAssert(bool value) => _doAssert = value;

  // private API

  Query<_GraphEdge> _q(String key, {String? metadata}) =>
      _collection.buildQuery<_GraphEdge>(
        whereClauses: [
          IndexWhereClause.equalTo(indexName: 'from', value: [key]),
          // or
          IndexWhereClause.equalTo(indexName: 'to', value: [key]),
        ],
        filter: metadata == null
            ? null
            : FilterGroup.or([
                FilterGroup.and([
                  FilterCondition(
                    type: ConditionType.eq,
                    property: 'from',
                    value: key,
                    caseSensitive: false,
                  ),
                  FilterCondition(
                    type: ConditionType.startsWith,
                    property: 'metadata',
                    value: '$metadata#',
                  ),
                ]),
                FilterGroup.and([
                  FilterCondition(
                    type: ConditionType.eq,
                    property: 'to',
                    value: key,
                  ),
                  FilterCondition(
                    type: ConditionType.endsWith,
                    property: 'metadata',
                    value: '#$metadata',
                  ),
                ]),
              ]),
      );

  _GraphEdge _w(_GraphEdge edge) {
    _collection.isar.writeTxnSync((_) => _collection.putSync(edge));
    return edge;
  }

  void _d(_GraphEdge edge) {
    _collection.isar.writeTxnSync((_) => _collection.deleteSync(edge.id!));
  }

  //

  List<_GraphEdge> _getNode(String from, {bool notify = true}) {
    return _q(from).findAllSync().map((e) {
      return e.from == from ? e : e.invert();
    }).toList();
  }

  void _removeNode(String from, {bool notify = true}) {
    final edges = _q(from);
    _collection.isar.writeTxnSync((_) => edges.deleteAllSync());

    if (notify) {
      state = DataGraphEvent(keys: [from], type: DataGraphEventType.removeNode);
    }
  }

  Iterable<_GraphEdge> _getEdges(String key,
      {required String metadata,
      Iterable<String> orAddWithTo = const [],
      String? orAddInverseMetadata}) {
    var edges = _q(key, metadata: metadata).findAllSync();
    print('found edges $edges for $key / $metadata');

    if (edges.isEmpty && orAddWithTo.isNotEmpty) {
      edges = _addEdges(
        key,
        tos: orAddWithTo,
        metadata: metadata,
        // TODO add inverse meta
        // inverseMetadata: orAddInverseMetadata,
      ).toList();
    }
    return edges.map((e) => key == e.from ? e : e.invert());
  }

  bool _hasEdge(String key, {required String metadata}) {
    return _q(key, metadata: metadata).countSync() > 0;
  }

  // write

  _GraphEdge _getOrderedEdge(String from, String to,
      {required String metadata, String? inverseMetadata}) {
    var edge = _GraphEdge(
      from,
      to,
      metadata: metadata,
      inverseMetadata: inverseMetadata,
    );
    // need to be written in order
    if (edge.from.compareTo(edge.to) > 0) {
      edge = edge.invert();
    }
    return edge;
  }

  Iterable<_GraphEdge> _addEdges(String from,
      {required Iterable<String> tos,
      required String metadata,
      String? inverseMetadata,
      bool notify = true}) {
    final edges = tos.map((to) {
      final edge = _getOrderedEdge(from, to,
          metadata: metadata, inverseMetadata: inverseMetadata);
      print('adding $edge');
      return _w(edge);
    }).toList();
    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...edges.map((e) => e.to)],
        metadata: metadata,
        type: DataGraphEventType.addEdge,
      );
    }
    return edges;
  }

  void _removeEdge(String from,
      {required String to,
      required String metadata,
      String? inverseMetadata,
      bool notify = true}) {
    _d(_getOrderedEdge(from, to, metadata: metadata));

    if (notify) {
      state = DataGraphEvent(
        keys: [from, to],
        metadata: metadata,
        type: DataGraphEventType.removeEdge,
      );
    }
  }

  void _notify(List<String> keys,
      {String? metadata, required DataGraphEventType type}) {
    if (mounted) {
      state = DataGraphEvent(type: type, metadata: metadata, keys: keys);
    }
  }

  // misc

  Map<String, Map> _toMap() {
    final map =
        _collection.where().findAllSync().groupListsBy((edge) => edge.from);
    print('__map $map // ${_collection.where().countSync()}');

    return {
      for (final e in map.entries)
        e.key: {
          for (final e2 in e.value.groupListsBy((e) => e.metadata).entries)
            e2.key: e2.value.map((e) => e.to).toSet(),
        },
    };
  }
}

// extension _ASX on List<_GraphEdge> {
//   Set<String> get tos {
//     return fold<Set<String>>({}, (acc, e) => {...acc, ...e.tos});
//   }
// }

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
    required this.keys,
    required this.type,
    this.metadata,
  });
  final List<String> keys;
  final DataGraphEventType type;
  final String? metadata;

  @override
  String toString() {
    return '${type.toShortString()}: $keys';
  }
}

extension _DataGraphEventX on DataGraphEventType {
  String toShortString() => toString().split('.').last;
}

final graphNotifierProvider =
    Provider<GraphNotifier>((ref) => GraphNotifier(ref.read));
