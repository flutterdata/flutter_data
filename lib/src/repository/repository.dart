part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  Repository(this.manager,
      {bool remote, bool verbose, @visibleForTesting Box<T> box})
      : _box = box,
        _remote = remote ?? true,
        _verbose = verbose ?? true;

  @protected
  @visibleForTesting
  final DataManager manager;

  @protected
  @visibleForTesting
  GraphNotifier get graphNotifier => manager?.graphNotifier;

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

  @nonVirtual
  @protected
  @visibleForTesting
  final oneFrameDuration = Duration(milliseconds: 16);

  // repo public API

  Future<List<T>> findAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  DataStateNotifier<List<T>> watchAll(
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
      {bool remote, Map<String, dynamic> params, Map<String, String> headers});

  Map<dynamic, T> get localBoxMap => box.toMap();

  // lifecycle hooks

  @mustCallSuper
  FutureOr<void> initialize() {
    box; // at this point box is init'd & assigned
  }

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

  //

  void localDelete(String key) {
    if (key != null) {
      box.delete(key);
      // id will become orphan & purged
      manager.removeKey(key);
    }
  }

  // protected & private

  @protected
  T initModel(T model, {String key, bool save}) {
    if (model == null) {
      return null;
    }
    // already initialized
    if (keyFor(model) != null) {
      return model;
    }

    // initialize

    save = true;

    _assertManager();
    model._repository = this;

    // ensure key is linked to ID
    // if no ID, register key
    key ??= Repository.generateKey<T>();
    model._flutterDataMetadata['_key'] = model.id != null
        ? manager.getKeyForId(type, model.id, keyIfAbsent: key)
        : graphNotifier.addNode(key);
    assert(keyFor(model) != null);

    if (save) {
      box?.put(keyFor(model), model);
    }

    // set model as "owner" in its relationships
    for (var metadata in relationshipsFor(model).entries) {
      final relationship = metadata.value['instance'] as Relationship;
      relationship?.setOwner(
          type, keyFor(model), metadata.key, metadata.value, manager);
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
