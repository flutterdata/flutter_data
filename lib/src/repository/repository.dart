part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  Repository(this.manager, {bool remote, bool verbose, Box<T> box})
      : _box = box,
        _remote = remote ?? true,
        _verbose = verbose ?? true;

  @protected
  @visibleForTesting
  final DataManager manager;

  @protected
  @visibleForTesting
  Box<T> get box => _box ??= manager.locator<Box<T>>();
  Box<T> _box; // waiting for `late` keyword

  final bool _remote;
  final bool _verbose;

  @nonVirtual
  @protected
  @visibleForTesting
  final type = getType<T>();

  // repo public API

  Future<Iterable<T>> findAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  DataStateNotifier<Iterable<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Future<T> findOne(dynamic id,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch});

  Future<T> save(T model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Future<void> delete(dynamic id,
      {bool remote,
      String orKey,
      Map<String, dynamic> params,
      Map<String, String> headers});

  Map<dynamic, T> get localBoxMap => box.toMap();

  // lifecycle hooks

  @mustCallSuper
  FutureOr<void> initialize() {}

  @mustCallSuper
  Future<void> dispose() async {
    await box?.close();
  }

  // generated model adapter API (metadata, relationships, serialization)

  @protected
  @visibleForTesting
  Map<String, Repository> get relatedRepositories;

  @protected
  @visibleForTesting
  Map<String, Map<String, Object>> relationshipsFor([T model]);

  @protected
  @visibleForTesting
  Map<String, dynamic> localSerialize(T model);

  @protected
  @visibleForTesting
  T localDeserialize(Map<String, dynamic> map);

  // local

  @protected
  @visibleForTesting
  Iterable<T> localFindAll() {
    return box.values.map(initModel);
  }

  @protected
  @visibleForTesting
  T localGet(String key, {bool init = true}) {
    if (key != null) {
      final model = box.get(key);
      if (init) {
        return initModel(model);
      } else {
        return model;
      }
    }
    return null;
  }

  @protected
  @visibleForTesting
  void localPut(String key, T model) {
    assert(key != null);
    box.put(key, model); // save in bg
  }

  @protected
  @visibleForTesting
  void localDelete(String key) {
    if (key != null) {
      box.delete(key); // delete in bg
      // id will become orphan & purged
      manager.removeKey(key);
    }
  }

  // protected & private

  @protected
  @visibleForTesting
  T initModel(T model, {String key, bool save = false, bool notify = true}) {
    if (model == null) {
      return null;
    }

    final wasInitialized = keyFor(model) != null;
    final existingKey = manager.getKeyForId(type, model.id);

    // ensure we have a key, searching in the correct priority
    key = keyFor(model) ?? existingKey ?? key ?? Repository.generateKey<T>();

    if (!wasInitialized) {
      _assertManager();
      model._repository = this;
      if (existingKey == null) {
        save = true;
      }
    }

    if (save) {
      localPut(key, model);
    }

    if (!wasInitialized) {
      // model.id could be null, that's okay
      model._flutterDataMetadata['_key'] =
          existingKey ?? manager.getKeyForId(type, model.id, keyIfAbsent: key);

      // set model as "owner" in its relationships
      for (final metadata in relationshipsFor(model).entries) {
        final relationship = metadata.value['instance'] as Relationship;
        relationship?.setOwner(
            type, keyFor(model), metadata.key, metadata.value, manager);
      }
    }

    // all done, notify listeners
    if (save && notify) {
      manager.graph.notify(
          [key],
          existingKey != null
              ? DataGraphEventType.updateNode
              : DataGraphEventType.addNode);
    }

    return model;
  }

  void _assertManager() {
    final modelAutoInit = _autoModelInitDataManager != null;
    if (modelAutoInit) {
      assert(manager == _autoModelInitDataManager, '''\n
This app has been configured with autoModelInit: true at boot,
which means that model initialization is managed internally.

You supplied an instance of Repository whose manager is NOT the
internal manager.

Either:
 - supply NO repository at all (RECOMMENDED)
 - supply an internally managed repository

If you wish to manually initialize your models, please make
sure $T (and ALL your other models) mix in DataSupportMixin
and you configure Flutter Data to do so, via:

FlutterData.init(autoModelInit: false);
''');
    }
  }

  // static helper methods

  static Future<Box<E>> getBox<E extends DataSupport<E>>(DataManager manager,
      {List<int> encryptionKey}) async {
    final boxName = getType<E>();
    if (!manager._hive.isBoxOpen(boxName)) {
      manager._hive.registerAdapter(_HiveTypeAdapter<E>(manager));
    }
    return await manager._hive.openBox(boxName,
        encryptionCipher:
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null);
  }

  static String getType<T>([String type]) {
    if (T == dynamic && type == null) {
      return null;
    }
    return pluralize((type ?? T.toString()).toLowerCase());
  }

  static String generateKey<T>([String type]) {
    final ts = getType<T>(type);
    if (ts == null) {
      return null;
    }
    return '${getType<T>(type)}#${DataManager._uuid.v1().substring(0, 8)}';
  }
}
