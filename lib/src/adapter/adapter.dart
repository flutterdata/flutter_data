part of flutter_data;

/// An adapter base class for all operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_SerializationAdapter.serializeAsync]
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

  Database get db => storage.db;

  bool _stopInitialization = false;

  // None of these fields below can be late finals as they might be re-initialized
  Ref? _ref;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, Adapter> get adapters => _internalAdapters!;

  /// Give access to the dependency injection system
  @nonVirtual
  Ref get ref => _ref!;

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
  Future<Adapter<T>> initialize({required Ref ref}) async {
    if (isInitialized) return this as Adapter<T>;

    _ref = ref;

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
    return _deserializeFromResult(result);
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
    return _deserializeFromResult(result);
  }

  List<T> _deserializeFromResult(ResultSet result) {
    return result.map((r) {
      final map = Map<String, dynamic>.from(jsonDecode(r['data']));
      return deserialize(map,
          key: r['key'].toString().typifyWith(internalType));
    }).toList();
  }

  /// Finds model of type [T] by [key] in local storage.
  T? findOneLocal(String? key) {
    if (key == null) return null;
    return findManyLocal([key]).safeFirst;
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

  /// Saves model of type [T] in local storage.
  ///
  /// By default notifies this modification to the associated [CoreNotifier].
  T saveLocal(T model, {bool notify = true}) {
    if (model._key == null) {
      throw Exception("Model must be initialized:\n\n$model");
    }
    final key = model._key!.detypifyKey();
    final map = serialize(model, withRelationships: false);
    final data = jsonEncode(map);
    db.execute(
        'REPLACE INTO $internalType (key, data) VALUES (?, ?)', [key, data]);
    return model;
  }

  Future<R> _runInIsolate<R>(
      FutureOr<R> fn(ProviderContainer container)) async {
    final ppath = Directory(storage.path).parent.path;
    final ip = _internalProviders!;

    return await Isolate.run(() async {
      late final ProviderContainer container;
      try {
        container = ProviderContainer(
          overrides: [
            localStorageProvider.overrideWith(
              (ref) => LocalStorage(baseDirFn: () => ppath),
            ),
          ],
        );

        await container.read(initializeWith(ip).future);

        return fn(container);
      } finally {
        container.read(localStorageProvider).db.dispose();
      }
    });
  }

  Future<void> saveManyLocal(Iterable<DataModelMixin> models,
      {bool notify = true}) async {
    final savedKeys = await _runInIsolate((container) async {
      final db = container.read(localStorageProvider).db;
      final savedKeys = <String>[];

      final grouped = models.groupSetsBy((e) => e._adapter);
      for (final e in grouped.entries) {
        final adapter = e.key;
        // TODO use prepareMultiple
        final ps = db.prepare(
            'REPLACE INTO ${adapter.internalType} (key, data) VALUES (?, ?) RETURNING key;');
        for (final model in e.value) {
          final key = model._key!.detypifyKey();
          final map = adapter.serialize(model, withRelationships: false);
          final data = jsonEncode(map);
          final result = ps.select([key, data]);
          savedKeys.add(
              result.first['key'].toString().typifyWith(adapter.internalType));
        }
        ps.dispose();
      }
      return savedKeys;
    });

    if (notify) {
      core._notify(savedKeys, type: DataGraphEventType.updateNode);
    }
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
    core.deleteKeys(keys);
    if (notify) {
      core._notify([...keys], type: DataGraphEventType.removeNode);
    }
  }

  /// Deletes all models of type [T] in local storage.
  Future<void> clearLocal() async {
    // TODO SELECT name FROM sqlite_master WHERE type='table' AND name='your_table_name';
    // leave async in case some impls need to remove files
    for (final adapter in adapters.values) {
      db.execute('DELETE FROM ${adapter.internalType}');
    }
    core._notify([internalType], type: DataGraphEventType.clear);
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
        .map((r) => r['key'].toString().typifyWith(internalType))
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

    // // (before -> after remote save)
    // // (1) if noid -> noid => `key` is the key we want to keep
    // // (2) if id -> noid => use autogenerated key (`key` should be the previous (derived))
    // // so we can migrate rels
    // // (3) if noid -> id => use derived key (`key` should be the previous (autogen'd))
    // // so we can migrate rels

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

  Set<String> _edgesFor(String fromKey, String name) {
    final result = db.select(
        'SELECT src, dest FROM _edges WHERE (src = ? AND name = ?) OR (dest = ? AND inverse = ?)',
        [fromKey, name, fromKey, name]);
    return {for (final r in result) r['dest']};
  }

  void _initializeRelationships(T model, {String? fromKey}) {
    final metadatas = relationshipMetas.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(model);
      if (relationship != null) {
        // if rel was omitted, fill with info of previous key
        // TODO optimize: put outside loop and query edgesFor just once
        if (fromKey != null && relationship._uninitializedKeys == null) {
          relationship._uninitializedKeys = _edgesFor(fromKey, metadata.name);
        }
        relationship.initialize(
          ownerKey: model._key!,
          name: metadata.name,
          inverseName: metadata.inverseName,
        );
      }
    }
  }

  Map<String, dynamic> serialize(T model, {bool withRelationships = true});

  T deserialize(Map<String, dynamic> map, {String? key});

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
