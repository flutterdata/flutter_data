part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  Repository(this.manager, this.box, {bool remote, bool verbose})
      : _remote = remote ?? true,
        _verbose = verbose ?? true;

  @protected
  @visibleForTesting
  final DataManager manager;
  @protected
  @visibleForTesting
  final Box<T> box;

  final bool _remote;
  final bool _verbose;
  String get type => DataId.getType<T>();

  static Future<Box<E>> getBox<E extends DataSupport<E>>(DataManager manager,
      {List<int> encryptionKey}) async {
    final boxName = DataId.getType<E>();
    if (!manager._hive.isBoxOpen(boxName)) {
      manager._hive.registerAdapter(_HiveTypeAdapter<E>(manager));
    }
    return await manager._hive.openBox(boxName,
        encryptionCipher:
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null);
  }

  // metadata

  @protected
  @visibleForTesting
  Repository repositoryFor(String type);

  @protected
  @visibleForTesting
  Map<String, dynamic> get relationshipMetadata;

  void syncRelationships(T model) {
    // set model as "owner" in its relationships
    setOwnerInRelationships(model._dataId, model);
  }

  @visibleForTesting
  @protected
  void setOwnerInRelationships(DataId<T> owner, T model);

  @visibleForTesting
  @protected
  void setInverseInModel(DataId inverse, T model);

  // remote

  String get baseUrl;

  @protected
  @visibleForTesting
  Map<String, dynamic> get params;

  @protected
  @visibleForTesting
  Map<String, dynamic> get headers;

  @protected
  @visibleForTesting
  String urlForFindAll(params);

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindAll(params);

  Future<List<T>> findAll(
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  @protected
  @visibleForTesting
  String urlForFindOne(id, params);

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindOne(id, params);

  Future<T> findOne(dynamic id,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers,
      AlsoWatch<T> alsoWatch});

  @protected
  @visibleForTesting
  String urlForSave(id, params);

  @protected
  @visibleForTesting
  DataRequestMethod methodForSave(id, params);

  Future<T> save(T model,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  @protected
  @visibleForTesting
  String urlForDelete(id, params);

  @protected
  @visibleForTesting
  DataRequestMethod methodForDelete(id, params);

  Future<void> delete(dynamic id,
      {bool remote, Map<String, dynamic> params, Map<String, dynamic> headers});

  // serialization

  @protected
  @visibleForTesting
  Map<String, dynamic> serialize(T model) => localSerialize(model);

  @protected
  @visibleForTesting
  Map<String, dynamic> localSerialize(T model);

  @protected
  @visibleForTesting
  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models);

  @protected
  @visibleForTesting
  T deserialize(dynamic object, {String key, bool initialize = true}) =>
      localDeserialize(object as Map<String, dynamic>);

  @protected
  @visibleForTesting
  T localDeserialize(Map<String, dynamic> map);

  @protected
  @visibleForTesting
  Iterable<T> deserializeCollection(object);

  @protected
  @visibleForTesting
  String fieldForKey(String key);

  @protected
  @visibleForTesting
  String keyForField(String field);

  // initialization

  T _init(T model, {String key, bool save = false}) {
    if (model == null) {
      return null;
    }

    _assertManager();
    model._repository ??= this;
    model._save = save;

    // only init dataId if
    //  - it hasn't been set
    //  - there's an updated key to set
    if (model._dataId == null || (key != null && key != model._dataId.key)) {
      // (1) establish key
      model._dataId = DataId<T>(model.id, manager, key: key);

      // if key was already linked to ID
      // delete the "temporary" local record
      if (key != null && key != model._dataId.key) {
        box.delete(key);
        DataId.byKey<T>(key, manager)?.delete();
      }

      // (2) sync relationships
      syncRelationships(model);
    }

    // (3) save locally
    if (save) {
      box.put(model._dataId.key, model);
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

  Map<dynamic, T> dumpLocal() => box.toMap();

  @mustCallSuper
  Future<void> dispose() async {
    await box?.close();
  }
}
