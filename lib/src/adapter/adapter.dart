part of flutter_data;

/// An adapter base class for all operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_SerializationAdapter.serialize]
///  - Watch methods such as [_WatchAdapter.watchOneNotifier]
///  - Access to the [_BaseAdapter.core] for subclasses or mixins
///
/// This class is meant to be extended via mixing in new adapters.
/// This can be done with the [DataAdapter] annotation on a [DataModelMixin] class:
///
/// ```
/// @JsonSerializable()
/// @DataAdapter([MyAppAdapter])
/// class Todo with DataModel<Todo> {
///   @override
///   final int? id;
///   final String title;
///   final bool completed;
///
///   Todo({this.id, required this.title, this.completed = false});
/// }
/// ```
///
/// Identity in this layer is enforced by IDs.
// ignore: library_private_types_in_public_api
abstract class Adapter<T extends DataModelMixin<T>> = _BaseAdapter<T>
    with _SerializationAdapter<T>, _RemoteAdapter<T>, _WatchAdapter<T>;

abstract class _BaseAdapter<T extends DataModelMixin<T>> with _Lifecycle {
  @protected
  _BaseAdapter(Ref ref, [this._internalHolder])
      : core = ref.read(_coreNotifierProvider),
        storage = ref.read(localStorageProvider);

  @protected
  @visibleForTesting
  final CoreNotifier core;

  @protected
  @visibleForTesting
  final LocalStorage storage;

  @protected
  @visibleForTesting
  Database get db => storage.db;

  bool _stopInitialization = false;

  // None of these fields below can be late finals as they might be re-initialized
  Ref? _ref;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, Adapter> get adapters => _internalAdaptersMap!;

  /// Give access to the dependency injection system
  @nonVirtual
  Ref get ref => _ref!;
  bool inIsolate = false;

  @visibleForTesting
  @protected
  @nonVirtual
  String get internalType => DataHelpers.internalTypeFor(T.toString());

  /// The pluralized and downcased [DataHelpers.getType<T>] version of type [T]
  /// by default.
  ///
  /// Example: [T] as `Post` has a [type] of `posts`.
  String get type => internalType;

  /// ONLY FOR FLUTTER DATA INTERNAL USE
  Watcher? internalWatch;
  final InternalHolder<T>? _internalHolder;

  /// Set log level.
  // ignore: prefer_final_fields
  int logLevel = 0;

  // lifecycle methods

  @override
  var isInitialized = false;

  @mustCallSuper
  Future<void> onInitialized() async {
    db.execute('''
      CREATE TABLE IF NOT EXISTS $internalType (
        key INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      );
    ''');
  }

  @mustCallSuper
  @nonVirtual
  Future<Adapter<T>> initialize(
      {required Ref ref, bool inIsolate = false}) async {
    if (isInitialized) return this as Adapter<T>;

    _ref = ref;
    this.inIsolate = inIsolate;

    // hook for clients
    await onInitialized();

    isInitialized = true;

    return this as Adapter<T>;
  }

  @override
  void dispose() {
    isInitialized = false;
  }

  // local methods

  /// Returns all models of type [T] in local storage.
  List<T> findAllLocal() {
    final result = db.select('SELECT key, data FROM $internalType');
    return deserializeFromResult(result);
  }

  /// Finds many models of type [T] by [keys] in local storage.
  List<T> findManyLocal(Iterable<String> keys) {
    if (keys.isEmpty) {
      return [];
    }
    final intKeys = keys.map((key) => key.detypifyKey()).toList();

    final result = db.select(
        'SELECT key, data FROM $internalType WHERE key IN (${intKeys.map((_) => '?').join(', ')})',
        intKeys);
    return deserializeFromResult(result);
  }

  // TODO test
  /// Finds many models of type [T] by [ids] in local storage.
  List<T> findManyLocalByIds(Iterable<Object> ids) {
    final result = db.select(
        'SELECT $internalType.key, data FROM $internalType JOIN _keys ON _keys.key = $internalType.key WHERE id IN (${ids.map((_) => '?').join(', ')})',
        ids.map((id) => id.toString()).toList());
    return deserializeFromResult(result);
  }

  @protected
  List<T> deserializeFromResult(ResultSet result) {
    return result.map((r) {
      final map = Map<String, dynamic>.from(jsonDecode(r['data']));
      return deserializeLocal(map,
          key: (r['key'] as int).typifyWith(internalType));
    }).toList();
  }

  /// Finds model of type [T] by [key] in local storage.
  T? findOneLocal(String? key) {
    if (key == null) return null;
    return findManyLocal([key]).firstOrNull;
  }

  T? findOneLocalById(Object id) {
    final key = core.getKeyForId(internalType, id);
    return findOneLocal(key);
  }

  /// Whether [key] exists in local storage.
  bool exists(String key) {
    final result = db.select(
        'SELECT EXISTS(SELECT 1 FROM $internalType WHERE key = ?) AS e;',
        [key.detypifyKey()]);
    return result.first['e'] == 1;
  }

  /// Whether [id] exists in local storage.
  bool existsId(Object id) {
    return exists(core.getKeyForId(internalType, id));
  }

  /// Saves model of type [T] in local storage.
  ///
  /// By default notifies this modification to the associated [CoreNotifier].
  T saveLocal(T model, {bool notify = true}) {
    if (model._key == null) {
      throw Exception("Model must be initialized:\n\n$model");
    }
    final key = model._key!.detypifyKey();
    final map = serializeLocal(model, withRelationships: false);
    final data = jsonEncode(map);
    db.execute(
        'REPLACE INTO $internalType (key, data) VALUES (?, ?)', [key, data]);
    if (notify) {
      core._notify([model._key!], type: DataGraphEventType.updateNode);
    }
    return model;
  }

  @protected
  Future<R> runInIsolate<R>(FutureOr<R> fn(Adapter adapter)) async {
    final storagePath = Directory(storage.path).parent.path;
    final internalProvidersMap = _internalProvidersMap!;
    final _internalType = internalType;

    final _refProvider = Provider((ref) => ref);

    return await Isolate.run(() async {
      late final ProviderContainer container;
      try {
        container = ProviderContainer(
          overrides: [
            localStorageProvider.overrideWith(
              (ref) => LocalStorage(baseDirFn: () => storagePath),
            ),
          ],
        );

        final _ref = container.read(_refProvider);
        _internalProvidersMap = internalProvidersMap;
        _internalAdaptersMap = internalProvidersMap
            .map((key, value) => MapEntry(key, _ref.read(value)));

        await container.read(localStorageProvider).initialize(inIsolate: true);

        // initialize and register
        for (final adapter in _internalAdaptersMap!.values) {
          adapter.dispose();
          await adapter.initialize(ref: _ref, inIsolate: true);
        }

        final adapter = internalProvidersMap[_internalType]!;
        return fn(container.read(adapter));
      } finally {
        for (final provider in internalProvidersMap.values) {
          container.read(provider).dispose();
        }
        container.read(localStorageProvider).dispose();
      }
    });
  }

  List<String> _saveManyLocal(
      Adapter adapter, Iterable<DataModelMixin> models) {
    final db = adapter.db;

    final savedKeys = <int>[];
    final pssMap = <PreparedStatement, List<(int, String)>>{};
    final keyMap = <int, String>{};

    // per adapter, create prepared statements for each type and serialize models
    final grouped = models.groupSetsBy((e) => e._adapter);
    for (final e in grouped.entries) {
      final adapter = e.key;

      final ps = db.prepare(
          'REPLACE INTO ${adapter.internalType} (key, data) VALUES (?, ?) RETURNING key;');
      pssMap[ps] = [];

      for (final model in e.value) {
        final [type, _key] = model._key!.split('#');
        final intKey = int.parse(_key);
        keyMap[intKey] = type;
        final map = adapter.serializeLocal(model, withRelationships: false);
        final data = jsonEncode(map);
        pssMap[ps]!.add((intKey, data));
      }
    }

    // with everything ready, execute transaction
    db.execute('BEGIN');
    for (final MapEntry(key: ps, value: record) in pssMap.entries) {
      for (final (key, data) in record) {
        final result = ps.select([key, data]);
        savedKeys.add(result.first['key'] as int);
      }
      ps.dispose();
    }
    db.execute('COMMIT');

    // read keys returned by queries and typify with their original type
    return savedKeys.map((key) => key.typifyWith(keyMap[key]!)).toList();
  }

  Future<List<String>?> saveManyLocal(Iterable<DataModelMixin> models,
      {bool notify = true, bool async = true}) async {
    final savedKeys = async
        ? await runInIsolate(
            (adapter) => adapter._saveManyLocal(adapter, models))
        : _saveManyLocal(this as Adapter, models);
    if (async) {
      if (notify) {
        core._notify(savedKeys, type: DataGraphEventType.updateNode);
        return null;
      }
    }
    return savedKeys;
  }

  /// Deletes model of type [T] from local storage.
  void deleteLocal(T model, {bool notify = true}) {
    deleteLocalByKeys([model._key!], notify: notify);
  }

  /// Deletes model with [id] from local storage.
  void deleteLocalById(Object id, {bool notify = true}) {
    final key = core.getKeyForId(type, id);
    deleteLocalByKeys([key], notify: notify);
  }

  /// Deletes models with [keys] from local storage.
  void deleteLocalByKeys(Iterable<String> keys, {bool notify = true}) {
    final intKeys = keys.map((k) => k.detypifyKey()).toList();
    db.execute(
        'DELETE FROM $internalType WHERE key IN (${keys.map((_) => '?').join(', ')})',
        intKeys);
    core.deleteKeysWithEdges(keys);
    if (notify) {
      core._notify([...keys], type: DataGraphEventType.removeNode);
    }
  }

  /// Deletes all models of type [T] in local storage.
  ///
  /// Async in case some implementations need to remove files.
  Future<void> clearLocal({bool notify = true}) async {
    final _ = db.select('DELETE FROM $internalType RETURNING key;');
    final keys =
        _.map((e) => (e['key'] as int).typifyWith(internalType)).toList();
    await core.deleteKeysWithEdges(keys);

    if (notify) {
      core._notify([internalType], type: DataGraphEventType.clear);
    }
  }

  /// Counts all models of type [T] in local storage.
  int get countLocal {
    final result = db.select('SELECT count(*) FROM $internalType');
    return result.first['count(*)'];
  }

  /// Gets all keys of type [T] in local storage.
  Set<String> get keys {
    final result =
        db.select('SELECT key FROM _keys WHERE type = ?', [internalType]);
    return result
        .map((r) => (r['key'] as int).typifyWith(internalType))
        .toSet();
  }

  void log(DataRequestLabel label, String message, {int logLevel = 1}) {
    if (this.logLevel >= logLevel) {
      final now = DateTime.now();
      final timestamp =
          '${now.second.toString().padLeft(2, '0')}:${now.millisecond.toString().padLeft(3, '0')}';
      print('$timestamp ${' ' * label.indentation * 2}[$label] $message');
    }
  }

  /// After model initialization hook
  @protected
  void onModelInitialized(T model) {}

  // offline

  /// Determines whether [error] was an offline error.
  @protected
  @visibleForTesting
  bool isOfflineError(Object? error) {
    final commonExceptions = [
      // timeouts via http's `connectionTimeout` are also socket exceptions
      'SocketException',
      'HttpException',
      'HandshakeException',
      'TimeoutException',
    ];

    // we check exceptions with strings to avoid importing `dart:io`
    final err = error.runtimeType.toString();
    return commonExceptions.any(err.contains);
  }

  @protected
  @visibleForTesting
  @nonVirtual
  Set<OfflineOperation<T>> get offlineOperations {
    final result = db.select('SELECT * FROM _offline_operations');
    return result.map((r) {
      return OfflineOperation<T>(
          label: DataRequestLabel.parse(r['label']),
          httpRequest: r['request'],
          timestamp: r['timestamp'],
          headers: Map<String, String>.from(jsonDecode(r['headers'])),
          body: r['body'],
          key: r['key'],
          adapter: this as Adapter<T>);
    }).toSet();
  }

  Object? _resolveId(Object obj) {
    return obj is T ? obj.id : obj;
  }

  //

  @protected
  @nonVirtual
  T internalWrapStopInit(Function fn, {String? key}) {
    _stopInitialization = true;
    late T model;
    try {
      model = fn();
    } finally {
      _stopInitialization = false;
    }
    return initModel(model, key: key);
  }

  @protected
  @nonVirtual
  T initModel(T model, {String? key, Function(T)? onModelInitialized}) {
    if (_stopInitialization) {
      return model;
    }

    if (model._key == null) {
      model._key = key ?? core.getKeyForId(internalType, model.id);
      if (model._key != key && key != null) {
        _initializeRelationships(model, fromKey: key);
      } else {
        _initializeRelationships(model);
      }

      onModelInitialized?.call(model);
    }
    return model;
  }

  Set<String> _keysFor(String key, String name) {
    final result = db.select(
        'SELECT key_, _key FROM _edges WHERE (key_ = ? AND name_ = ?) OR (_key = ? AND _name = ?)',
        [key, name, key, name]);
    return {for (final r in result) r['key_'] == key ? r['_key'] : r['key_']};
  }

  void _initializeRelationships(T model, {String? fromKey}) {
    final metadatas = relationshipMetas.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(model);
      if (relationship != null) {
        // if rel was omitted, fill with info of previous key
        // TODO optimize: put outside loop and query edgesFor just once
        if (fromKey != null && relationship._uninitializedKeys == null) {
          relationship._uninitializedKeys = _keysFor(fromKey, metadata.name);
        }
        relationship.initialize(
          ownerKey: model._key!,
          name: metadata.name,
          inverseName: metadata.inverseName,
        );
      }
    }
  }

  Map<String, dynamic> serializeLocal(T model, {bool withRelationships = true});

  T deserializeLocal(Map<String, dynamic> map, {String? key});

  Map<String, RelationshipMeta> get relationshipMetas;

  Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true}) {
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      if (withRelationships) {
        final ignored = e.value.serialize == false;
        if (ignored) map.remove(key);

        if (map[key] is HasMany) {
          map[key] = (map[key] as HasMany).keys;
        } else if (map[key] is BelongsTo) {
          map[key] = map[key].key;
        }

        if (map[key] == null) map.remove(key);
      } else {
        map.remove(key);
      }
    }
    return map;
  }

  Map<String, dynamic> transformDeserialize(Map<String, dynamic> map) {
    // ensure value is dynamic (argument might come in as Map<String, String>)
    map = Map<String, dynamic>.from(map);
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      final keyset = map[key] is Iterable
          ? {...(map[key] as Iterable)}
          : {if (map[key] != null) map[key].toString()};
      final ignored = e.value.serialize == false;
      map[key] = {
        '_': (map.containsKey(key) && !ignored) ? keyset : null,
      };
    }
    return map;
  }
}
