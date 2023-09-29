part of flutter_data;

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
      name: '_graph',
      schemas: [EdgeSchema, InternalIdSchema],
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

  // Key-related methods

  /// Finds a model's key.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  String? getKeyForId(String type, Object? id, {String? keyIfAbsent}) {
    type = DataHelpers.internalTypeFor(type);
    if (id != null) {
      final idMapping = _isar.idMappings
          .where()
          .idEqualTo(id.toString().typifyWith(type))
          .findFirst();
      if (idMapping != null) {
        return idMapping.key;
      }
      if (keyIfAbsent != null) {
        final idMapping = IdMapping(
            key: keyIfAbsent,
            id: id.toString().typifyWith(type),
            isInt: id is int);
        _isar.write((isar) => isar.idMappings.put(idMapping));
        return idMapping.key;
      }
    } else if (keyIfAbsent != null) {
      return keyIfAbsent;
    }
    return null;
  }

  /// Removes key
  void removeKey(String key) {
    _isar.write((isar) => isar.idMappings.delete(Isar.fastHash(key)));
    state = DataGraphEvent(keys: [key], type: DataGraphEventType.removeNode);
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    final idMapping = _isar.idMappings.get(Isar.fastHash(key));
    if (idMapping == null) {
      return null;
    }
    final id = idMapping.id.detypify();
    return idMapping.isInt ? int.parse(id) : id;
  }

  /// Removes [type]/[id] mapping
  void removeId(String type, Object id, {bool notify = true}) {
    final typeId = id.toString().typifyWith(type);
    _isar
        .write((isar) => isar.idMappings.where().idEqualTo(typeId).deleteAll());
    state = DataGraphEvent(keys: [typeId], type: DataGraphEventType.removeNode);
  }

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
    return _removeEdges(from, metadata: metadata, notify: notify);
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
    return _removeEdge(from, to, metadata: metadata, notify: notify);
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

  /// Returns a [Map] representation of the internal ID db
  Map<String, String> toIdMap() {
    final iids = _isar.idMappings.where().findAll();
    return {for (final iid in iids) iid.key: iid.id};
  }

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
      bool clearExisting = false,
      bool notify = true}) {
    if (tos.isEmpty) {
      if (clearExisting) {
        _isar.write((isar) {
          _getRemoveEdgesQuery(isar, from, metadata: metadata).deleteAll();
        });
      }
      return;
    }

    final edges = tos.map(
      (to) => Edge(
          id: _isar.edges.autoIncrement(),
          from: from,
          name: metadata,
          to: to,
          inverseName: inverseMetadata),
    );

    _isar.write((isar) {
      if (clearExisting) {
        _getRemoveEdgesQuery(isar, from, metadata: metadata).deleteAll();
      }
      isar.edges.putAll(edges.toList());
    });

    if (notify) {
      if (clearExisting) {
        state = DataGraphEvent(
          keys: [from, ...tos],
          metadata: metadata,
          type: DataGraphEventType.removeEdge,
        );
      }
      state = DataGraphEvent(
        keys: [from, ...tos],
        metadata: metadata,
        type: DataGraphEventType.addEdge,
      );
    }
  }

  void _removeEdge(String from, String to,
      {required String metadata, bool notify = true}) {
    _removeEdges(from, tos: {to}, metadata: metadata, notify: notify);
  }

  QueryBuilder<Edge, Edge, QAfterFilterCondition> _getRemoveEdgesQuery(
      Isar isar, String from,
      {required String metadata, Set<String>? tos}) {
    return isar.edges
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
                (q) => q.allOf(tos!, (q3, String to) => q3.fromEqualTo(to))));
  }

  void _removeEdges(String from,
      {required String metadata, Set<String>? tos, bool notify = true}) {
    _isar.write((isar) {
      _getRemoveEdgesQuery(isar, from, metadata: metadata, tos: tos)
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
