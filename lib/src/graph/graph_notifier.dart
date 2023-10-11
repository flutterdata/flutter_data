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

  IsarLocalStorage get _localStorage => ref.read(localStorageProvider);

  bool _doAssert = true;

  @override
  bool isInitialized = false;

  late Isar _isar;

  /// Initializes storage systems
  Future<GraphNotifier> initialize() async {
    if (isInitialized) return this;
    await _localStorage.initialize();

    try {
      _isar = Isar.open(
        name: 'flutter_data',
        schemas: [EdgeSchema, StoredModelSchema],
        directory: _localStorage.path,
      );
    } catch (e, stackTrace) {
      print('[flutter_data] Isar failed to open:\n$e\n$stackTrace');
    }

    if (_localStorage.clear == LocalStorageClearStrategy.always) {
      _isar.write((isar) => isar.clear());
    }

    isInitialized = true;
    return this;
  }

  @override
  void dispose() {
    if (isInitialized) {
      // _isar.close();
      isInitialized = false;
      super.dispose();
    }
  }

  void clear() {
    _isar.write((isar) => isar.edges.clear());
  }

  String generateKey<T>([String? type]) {
    if (type != null) {
      type = DataHelpers.internalTypeFor(type);
    } else {
      type = DataHelpers.getInternalType<T>();
    }
    return _isar.storedModels.autoIncrement().toString().typifyWith(type);
  }

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
      final key = _isar.storedModels
          .where()
          .typeEqualTo(type)
          .idEqualTo(id.toString())
          .keyProperty()
          .findFirst();
      if (key != null) {
        return key.toString().typifyWith(type);
      }
      if (keyIfAbsent != null) {
        final storedModel = StoredModel(
            key: intKey(keyIfAbsent),
            id: id.toString(),
            type: type,
            isIdInt: id is int);
        _isar.write((isar) => isar.storedModels.put(storedModel));
        return storedModel.key.toString().typifyWith(type);
      }
    } else if (keyIfAbsent != null) {
      return keyIfAbsent;
    }
    return null;
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    final tuple = _isar.storedModels
        .where()
        .keyEqualTo(intKey(key))
        .idProperty()
        .isIdIntProperty()
        .findFirst();
    if (tuple == null || tuple.$1 == null) {
      return null;
    }
    final (id, isInt) = tuple;
    return isInt ? int.parse(id!) : id;
  }

  /// Removes [type]/[id] mapping
  void removeId(String type, Object id, {bool notify = true}) {
    _isar.write((isar) => isar.storedModels
        .where()
        .typeEqualTo(type)
        .idEqualTo(id.toString())
        .updateAll(id: null));
    final typeId = id.toString().typifyWith(type);
    state = DataGraphEvent(keys: [typeId], type: DataGraphEventType.removeNode);
  }

  int intKey(String key) {
    return int.parse(key.detypify());
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
    final triples = _isar.storedModels
        .where()
        .idIsNotNull()
        .keyProperty()
        .typeProperty()
        .idProperty()
        .findAll();
    return {
      for (final t in triples)
        t.$1.toString().typifyWith(t.$2): t.$3.toString().typifyWith(t.$2)
    };
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

extension PackerX on Packer {
  void packJson(Map<String, dynamic> map) {
    packMapLength(map.length);
    map.forEach((key, v) {
      packString(key);
      packDynamic(v);
    });
  }

  void packIterableDynamic(Iterable iterable) {
    packListLength(iterable.length);
    for (final v in iterable) {
      packDynamic(v);
    }
  }

  void packDynamic(dynamic value) {
    if (value is Map) {
      packInt(5);
      return packJson(Map<String, dynamic>.from(value));
    }

    final type = value.runtimeType;
    if (type == Null) {
      packInt(0);
      return packNull();
    }
    if (type == String) {
      packInt(1);
      return packString(value);
    }
    if (type == int) {
      // WORKAROUND: for some reason negative ints are not working
      // so we save it as a special string (prefixed with $__fd_n:)
      if ((value as int).isNegative) {
        packInt(1);
        return packString('\$__fd_n:$value');
      }
      packInt(2);
      return packInt(value);
    }
    if (type == double) {
      packInt(3);
      return packDouble(value);
    }
    if (type == bool) {
      packInt(4);
      return packBool(value);
    }
    // List of any type
    if (value is Iterable) {
      packInt(6);
      return packIterableDynamic(value.toList());
    }
    throw Exception('missing type $type ($value)');
  }
}

extension UnpackerX on Unpacker {
  Map<String, dynamic> unpackJson() {
    final map = <String, dynamic>{};
    final length = unpackMapLength();
    for (var i = 0; i < length; i++) {
      final key = unpackString();
      map[key!] = unpackDynamic();
    }
    return map;
  }

  List unpackListDynamic() {
    final list = [];
    final length = unpackListLength();
    for (var i = 0; i < length; i++) {
      list.add(unpackDynamic());
    }
    return list;
  }

  dynamic unpackDynamic() {
    final type = unpackInt();
    switch (type) {
      case 0:
        return unpackString();
      case 1:
        final str = unpackString();
        // WORKAROUND: we unpack a negative int (encoded with the $__fd_n: prefix)
        if (str != null && str.startsWith('\$__fd_n:-')) {
          return int.parse(str.split(':').last);
        }
        return str;
      case 2:
        return unpackInt();
      case 3:
        return unpackDouble();
      case 4:
        return unpackBool();
      case 5:
        return unpackJson();
      case 6:
        return unpackListDynamic();
      default:
        throw Exception('missing type $type');
    }
  }
}
