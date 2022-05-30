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

  // IsarCollection<GraphEdge> get _nodes =>
  //     read(isarLocalStorageProvider)._isar!.getCollection();

  // bool _doAssert = true;

  // Future<void> clear() async {
  //   await _nodes.clear();
  // }

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

//   void _assertKey(String key) {
//     if (_doAssert) {
//       if (key.split(':').length != 2 || key.startsWith('_')) {
//         throw AssertionError('''
// Key "$key":
//   - Key must be namespaced (my:key)
//   - Key can't contain a colon (my:precious:key)
//   - Namespace can't start with an underscore (_my:key)
// ''');
//       }
//     }
//   }

//   /// Obtains a node (i.e. list of edges)
//   List<GraphEdge> getNode(String key, {bool notify = true}) {
//     return _getNode(key, notify: notify);
//   }

//   /// Removes a node, [key] MUST be namespaced (e.g. `manager:key`)
//   void removeNode(String key) {
//     _assertKey(key);
//     return _removeNode(key);
//   }

//   // edges

//   /// See [addEdge]
//   void addEdge(String from,
//       {required String metadata,
//       required Iterable<String> tos,
//       String? inverseMetadata,
//       bool addNode = false,
//       bool notify = true}) {
//     _assertKey(from);
//     for (final to in tos) {
//       _assertKey(to);
//     }
//     _assertKey(metadata);
//     if (inverseMetadata != null) {
//       _assertKey(inverseMetadata);
//     }
//     _addEdge(from,
//         metadata: metadata, tos: tos, inverseMetadata: inverseMetadata);
//   }

//   /// Returns edge by [metadata]
//   ///
//   /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
//   GraphEdge? getEdge(String key, {required String metadata}) {
//     _assertKey(key);
//     _assertKey(metadata);
//     return _getEdge(key, metadata: metadata);
//   }

//   /// See [removeEdge]
//   void removeEdge(String from,
//       {required String metadata,
//       Iterable<String> tos = const [],
//       String? inverseMetadata,
//       bool notify = true}) {
//     _assertKey(from);
//     for (final to in tos) {
//       _assertKey(to);
//     }
//     _assertKey(metadata);
//     if (inverseMetadata != null) {
//       _assertKey(inverseMetadata);
//     }
//     return _removeEdge(from,
//         metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
//   }

//   /// Returns whether the requested edge is present in this graph.
//   ///
//   /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
//   bool hasEdge(String key, {required String metadata}) {
//     _assertKey(key);
//     _assertKey(metadata);
//     return _hasEdge(key, metadata: metadata);
//   }

//   // utils

//   /// Returns a [Map] representation of this graph.
//   Map<String, Map> toMap() => _toMap();

//   @protected
//   @visibleForTesting
//   void debugAssert(bool value) => _doAssert = value;

//   // private API

//   Query<GraphEdge> _q(String key, {String? metadata}) =>
//       _nodes.buildQuery<GraphEdge>(
//         whereClauses: [
//           IndexWhereClause.equalTo(indexName: 'from', value: [key]),
//           // or
//           IndexWhereClause.equalTo(indexName: 'tos', value: [key]),
//         ],
//         filter: metadata == null
//             ? null
//             : FilterGroup.or([
//                 FilterGroup.and([
//                   FilterCondition(
//                     type: ConditionType.eq,
//                     property: 'from',
//                     value: key,
//                     caseSensitive: false,
//                   ),
//                   FilterCondition(
//                     type: ConditionType.eq,
//                     property: 'metadata',
//                     value: metadata,
//                     caseSensitive: false,
//                   ),
//                 ]),
//                 FilterGroup.and([
//                   FilterCondition(
//                     type: ConditionType.contains,
//                     property: 'tos',
//                     value: key,
//                     caseSensitive: false,
//                   ),
//                   FilterCondition(
//                     type: ConditionType.eq,
//                     property: 'inverseMetadata',
//                     value: metadata,
//                     caseSensitive: false,
//                   ),
//                 ]),
//               ]),
//       );

//   GraphEdge _w(GraphEdge edge) {
//     _nodes.isar.writeTxnSync((isar) => _nodes.putSync(edge));
//     return edge;
//   }

//   void _d(GraphEdge edge) {
//     _nodes.isar.writeTxnSync((isar) => _nodes.deleteSync(edge.id!));
//   }

//   //

//   List<GraphEdge> _getNode(String from, {bool notify = true}) {
//     return _q(from).findAllSync().map((e) {
//       if (e.from == from) {
//         return e;
//       } else {
//         // invert direction
//         return GraphEdge(from, metadata: e.inverseMetadata!, tos: [e.from]);
//       }
//     }).toList();
//   }

//   void _removeNode(String from, {bool notify = true}) {
//     final edges = _q(from);
//     _nodes.isar.writeTxnSync((_) => edges.deleteAllSync());

//     if (notify) {
//       state = DataGraphEvent(keys: [from], type: DataGraphEventType.removeNode);
//     }
//   }

//   Set<String> _getEdge(String from,
//       {required String metadata,
//       Iterable<String>? orAddWith,
//       String? inverseMetadata}) {
//     final tos = _q(from, metadata: metadata).findAllSync().tos;

//     if (tos.isEmpty && orAddWith != null) {
//       return _addEdge(
//         from,
//         metadata: metadata,
//         inverseMetadata: inverseMetadata,
//         tos: orAddWith,
//       );
//     }
//     return tos.toSet();
//   }

//   bool _hasEdge(String key, {required String metadata}) {
//     return _q(key, metadata: metadata).countSync() > 0;
//   }

//   // write

//   Set<String> _addEdge(String from,
//       {required String metadata,
//       required Iterable<String> tos,
//       bool overwriteTos = false,
//       String? inverseMetadata,
//       bool notify = true}) {
//     final edges = _q(from, metadata: metadata).findAllSync();

//     if (edges.isEmpty) {
//       _w(GraphEdge(
//         from,
//         metadata: metadata,
//         inverseMetadata: inverseMetadata,
//         tos: tos,
//       ));
//       return tos.toSet();
//     } else {
//       final currentTos = edges.tos;

//       // if we have tos currently, need to update adding them
//       _w(GraphEdge(
//         from,
//         metadata: metadata,
//         inverseMetadata: inverseMetadata,
//         tos: {if (!overwriteTos) ...currentTos, ...tos},
//       ));
//       if (notify) {
//         state = DataGraphEvent(
//           keys: [from, ...tos],
//           metadata: metadata,
//           type: DataGraphEventType.addEdge,
//         );
//       }
//       return edge.tos.toSet();
//     }
//   }

//   void _removeEdge(String from,
//       {required String metadata,
//       Iterable<String>? tos,
//       String? inverseMetadata,
//       bool notify = true}) {
//     final edge =
//         _getEdge(from, metadata: metadata, inverseMetadata: inverseMetadata);
//     if (edge != null) {
//       if (tos?.isEmpty ?? true) {
//         // if no specified tos, delete the whole edge
//         _d(edge);

//         if (notify) {
//           state = DataGraphEvent(
//             keys: [from, ...edge.tos],
//             metadata: metadata,
//             type: DataGraphEventType.removeEdge,
//           );
//         }
//       } else {
//         // update edge removing specified tos
//         _w(GraphEdge(
//           from,
//           metadata: metadata,
//           inverseMetadata: inverseMetadata,
//           tos: edge.tos..removeWhere(tos!.contains),
//         )..id = edge.id);

//         if (notify) {
//           state = DataGraphEvent(
//             keys: [from, ...tos],
//             metadata: metadata,
//             type: DataGraphEventType.removeEdge,
//           );
//         }
//       }
//     }
//   }

  void _notify(List<String> keys,
      {String? metadata, required DataGraphEventType type}) {
    if (mounted) {
      state = DataGraphEvent(type: type, metadata: metadata, keys: keys);
    }
  }

  // misc

  // Map<String, Map> _toMap() {
  //   final map = _nodes.where().findAllSync().groupListsBy((edge) => edge.from);

  //   return {
  //     for (final e in map.entries)
  //       e.key: {
  //         for (final e2 in e.value.groupListsBy((e) => e.metadata).entries)
  //           e2.key: e2.value.map((e) => e.tos).toSet(),
  //       },
  //   };
  // }
}

// extension _ASX on List<GraphEdge> {
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
