part of flutter_data;

abstract class Repository<T extends DataSupport<T>> {
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

  Future<List<T>> findAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Future<T> findOne(dynamic model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  DataStateNotifier<T> watchOne(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch});

  Future<T> save(T model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Future<void> delete(dynamic model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Map<dynamic, T> get dumpBox;

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
    return box.values.map(_initModel);
  }

  @protected
  @visibleForTesting
  T localGet(String key) {
    if (key != null) {
      final model = box.get(key);
      return _initModel(model);
    }
    return null;
  }

  @protected
  @visibleForTesting
  void localPut(String key, T model, {bool notify = true}) {
    assert(key != null);
    final keyExisted = box.containsKey(key);
    box.put(key, model); // save in bg
    if (notify) {
      manager.graph.notify(
        [key],
        keyExisted ? DataGraphEventType.updateNode : DataGraphEventType.addNode,
      );
    }
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

  // private

  T _initModel(T model, {String key, bool save = false}) {
    if (model == null) return null;
    if (model._isInitialized) return model;

    _assertManager();
    model._repository = this;

    // model.id could be null, that's okay
    model._key = manager.getKeyForId(type, model.id,
        keyIfAbsent: key ?? Repository.generateKey<T>());

    // initialize relationships
    for (final metadata in relationshipsFor(model).entries) {
      final relationship = metadata.value['instance'] as Relationship;
      relationship?.initialize(
          manager,
          model,
          metadata.key,
          metadata.value['inverse'] as String,
          metadata.value['type'] as String);
    }

    if (save) {
      localPut(model._key, model);
    }

    return model;
  }

  void _assertManager() {
    final auto = _autoManager != null;
    if (auto) {
      assert(manager == _autoManager, '''\n
Flutter Data has been configured with autoManager: true
at boot time. This means that the manager required for
model initialization is provided by the framework.

You supplied a DataManager which is NOT the internal manager.

Please initialize your models with no manager at all. Example:

model.init();
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
