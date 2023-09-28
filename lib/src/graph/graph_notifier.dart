part of flutter_data;

const _kGraphBoxName = '_graph';

/// A bidirected graph data structure that notifies
/// modification events through a [StateNotifier].
///
/// It's a core framework component as it holds all
/// relationship information.
///
/// Watchers like [Repository.watchAllNotifier] or [BelongsTo.watch]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class GraphNotifier extends DelayedStateNotifier<DataGraphEvent>
    with _Lifecycle {
  final Ref ref;
  @protected
  GraphNotifier(this.ref);

  HiveLocalStorage get _hiveLocalStorage => ref.read(hiveLocalStorageProvider);

  bool _doAssert = true;
  bool _isInitialized = false;

  late Isar _isar;

  /// Initializes storage systems
  Future<GraphNotifier> initialize() async {
    if (isInitialized) return this;
    await _hiveLocalStorage.initialize();

    _isar = Isar.open(
      name: _kGraphBoxName,
      schemas: [EdgeSchema],
      directory: Hive.defaultDirectory!,
    );

    if (_hiveLocalStorage.clear == LocalStorageClearStrategy.always) {
      _isar.write((isar) => isar.clear());
    }

    return this;
  }

  @override
  void dispose() {
    if (isInitialized) {
      _isar.close();
      super.dispose();
    }
  }

  void clear() {
    _isar.write((isar) => isar.edges.clear());
  }

  @override
  bool get isInitialized => _isInitialized;

  // key-related methods

  /// Finds a model's key in the graph.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  String? getKeyForId(String type, Object? id, {String? keyIfAbsent}) {
    type = DataHelpers.internalTypeFor(type);
    if (id != null) {
      final namespace = id is int ? '_id_int' : '_id';
      final namespacedId =
          id.toString().typifyWith(type).namespaceWith(namespace);

      final tos = _getEdge(namespacedId, metadata: '_key');
      if (tos.isNotEmpty) {
        final key = tos.first;
        return key;
      }

      if (keyIfAbsent != null) {
        // this means the method is instructed to
        // create nodes and edges

        // _addNode(keyIfAbsent, notify: false);
        // _addNode(namespacedId, notify: false);
        _removeEdges(keyIfAbsent,
            metadata: '_id', inverseMetadata: '_key', notify: false);
        _addEdge(keyIfAbsent, namespacedId,
            metadata: '_id', inverseMetadata: '_key', notify: false);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      // if no ID is supplied but keyIfAbsent is, create node for key
      // _addNode(keyIfAbsent, notify: false);
      return keyIfAbsent;
    }
    return null;
  }

  /// Removes key (and its edges) from graph
  void removeKey(String key) => _removeNode(key);

  /// Finds an ID in the graph, given a [key].
  Object? getIdForKey(String key) {
    final tos = _getEdge(key, metadata: '_id');
    if (tos.isEmpty) {
      return null;
    }
    final isInt = tos.first.namespace == '_id_int';
    final id = tos.first.denamespace().detypify();
    return isInt ? int.tryParse(id) : id;
  }

  /// Removes [type]/[id] (and its edges) from graph
  void removeId(String type, Object id, {bool notify = true}) =>
      _removeNode(id.toString().typifyWith(type).namespaceWith('_id'),
          notify: notify);

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

  /// Obtains a node
  Map<String, Set<String>> getNode(String key) {
    _assertKey(key);
    return _getNode(key);
  }

  /// Returns whether [key] is present in this graph.
  ///
  /// [key] MUST be namespaced (e.g. `manager:key`)
  bool hasNode(String key) {
    _assertKey(key);
    return _hasNode(key);
  }

  /// Removes a node, [key] MUST be namespaced (e.g. `manager:key`)
  void removeNode(String key, {bool notify = true}) {
    _assertKey(key);
    return _removeNode(key, notify: notify);
  }

  // edges

  /// See [addEdge]
  void addEdges(String from,
      {required String metadata,
      required Set<String> tos,
      String? inverseMetadata,
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
        metadata: metadata, tos: tos, inverseMetadata: inverseMetadata);
  }

  /// Returns edge by [metadata]
  ///
  /// [key] and [metadata] MUST be namespaced (e.g. `manager:key`)
  Set<String> getEdge(String key, {required String metadata}) {
    _assertKey(key);
    _assertKey(metadata);
    return _getEdge(key, metadata: metadata);
  }

  /// Adds a bidirectional edge:
  ///
  ///  - [from]->[to] with [metadata]
  ///  - [to]->[from] with [inverseMetadata]
  ///
  /// [from], [metadata] & [inverseMetadata] MUST be namespaced (e.g. `manager:key`)
  void addEdge(String from, String to,
      {required String metadata, String? inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(to);
    _assertKey(metadata);
    if (inverseMetadata != null) {
      _assertKey(inverseMetadata);
    }
    return _addEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  /// See [removeEdge]
  void removeEdges(String from,
      {required String metadata,
      Iterable<String> tos = const [],
      String? inverseMetadata,
      bool notify = true}) {
    _assertKey(from);
    for (final to in tos) {
      _assertKey(to);
    }
    _assertKey(metadata);
    if (inverseMetadata != null) {
      _assertKey(inverseMetadata);
    }
    return _removeEdges(from,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
  }

  /// Removes a bidirectional edge:
  ///
  ///  - [from]->[to] with [metadata]
  ///  - [to]->[from] with [inverseMetadata]
  ///
  /// [from], [metadata] & [inverseMetadata] MUST be namespaced (e.g. `manager:key`)
  void removeEdge(String from, String to,
      {required String metadata, String? inverseMetadata, bool notify = true}) {
    _assertKey(from);
    _assertKey(to);
    _assertKey(metadata);
    if (inverseMetadata != null) {
      _assertKey(inverseMetadata);
    }
    return _removeEdge(from, to,
        metadata: metadata, inverseMetadata: inverseMetadata, notify: notify);
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

  /// Returns a [Map] representation of this graph from the underlying storage.
  Map<String, Map<String, List<String>>> toMap() => _toMap();

  void debugMap() => _prettyPrintJson(_toMap());

  @protected
  @visibleForTesting
  void debugAssert(bool value) => _doAssert = value;

  // private API

  Map<String, Set<String>> _getNode(String key) {
    final edges =
        _isar.edges.where().fromEqualTo(key).or().toEqualTo(key).findAll();
    final grouped = edges.groupListsBy((e) => e.name);
    return {
      for (final e in grouped.entries)
        e.key: e.value.map((e) => e.from == key ? e.to : e.from).toSet()
    };
  }

  bool _hasNode(String key) {
    return _isar.edges.where().fromEqualTo(key).or().toEqualTo(key).count() > 0;
  }

  Set<String> _getEdge(String key, {required String metadata}) {
    final edges = _isar.edges
        .where()
        .group((q) => q.fromEqualTo(key).and().nameEqualTo(metadata))
        .or()
        .group((q) => q.toEqualTo(key).and().inverseNameEqualTo(metadata))
        .findAll();
    return {for (final e in edges) e.from == key ? e.to : e.from};
  }

  bool _hasEdge(String key, {required String metadata}) {
    return _isar.edges
            .where()
            .group((q) => q.fromEqualTo(key).and().nameEqualTo(metadata))
            .or()
            .group((q) => q.toEqualTo(key).and().inverseNameEqualTo(metadata))
            .count() >
        0;
  }

  // write

  void _removeNode(String key, {bool notify = true}) {
    _isar.write((isar) =>
        isar.edges.where().fromEqualTo(key).or().toEqualTo(key).deleteAll());
    if (notify) {
      state = DataGraphEvent(keys: [key], type: DataGraphEventType.removeNode);
    }
  }

  void _addEdge(String from, String to,
      {required String metadata, String? inverseMetadata, bool notify = true}) {
    _addEdges(from,
        tos: {to},
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void _addEdges(String from,
      {required String metadata,
      required Set<String> tos,
      String? inverseMetadata,
      bool notify = true}) {
    if (tos.isEmpty) {
      return;
    }

    final edges = tos.map((to) =>
        Edge(from: from, name: metadata, to: to, inverseName: inverseMetadata));

    _isar.write((isar) {
      isar.edges.putAll(edges.toList());
    });

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...tos],
        metadata: metadata,
        type: DataGraphEventType.addEdge,
      );
    }
  }

  void _removeEdge(String from, String to,
      {required String metadata, String? inverseMetadata, bool notify = true}) {
    _removeEdges(from,
        tos: {to},
        metadata: metadata,
        inverseMetadata: inverseMetadata,
        notify: notify);
  }

  void _removeEdges(String from,
      {required String metadata,
      Set<String>? tos,
      String? inverseMetadata,
      bool notify = true}) {
    _isar.write((isar) {
      isar.edges
          .where()
          .group((q) => q
              .fromEqualTo(from)
              .and()
              .nameEqualTo(metadata)
              .and()
              .optional(tos != null,
                  (q) => q.allOf(tos!, (q3, String to) => q3.toEqualTo(to))))
          .or()
          .group((q) => q
              .toEqualTo(from)
              .and()
              .inverseNameEqualTo(metadata)
              .and()
              .optional(tos != null,
                  (q) => q.allOf(tos!, (q3, String to) => q3.fromEqualTo(to))))
          .deleteAll();
    });

    if (notify) {
      state = DataGraphEvent(
        keys: [from, ...?tos],
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

  Map<String, Map<String, List<String>>> _toMap() {
    final map = <String, Map<String, List<String>>>{};

    final edges = _isar.edges.where().findAll();
    for (final edge in edges) {
      map[edge.from] ??= {};
      map[edge.from]![edge.name] ??= [];
      map[edge.from]![edge.name]!.add(edge.to);
    }
    for (final edge in edges) {
      if (edge.inverseName != null) {
        map[edge.to] ??= {};
        map[edge.to]![edge.inverseName!] ??= [];
        map[edge.to]![edge.inverseName!]!.add(edge.from);
      }
    }

    return map;
  }

  static JsonEncoder _encoder = JsonEncoder.withIndent('  ');
  static void _prettyPrintJson(Map<String, dynamic> map) {
    final prettyString = _encoder.convert(map);
    prettyString.split('\n').forEach((element) => print(element));
  }
}

enum DataGraphEventType {
  addNode,
  removeNode,
  updateNode,
  clear,
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
    Provider<GraphNotifier>((ref) => GraphNotifier(ref));
