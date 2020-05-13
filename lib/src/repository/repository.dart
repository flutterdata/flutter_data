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
  Box<T> get box => _box ??= manager.locator<Box<T>>();
  Box<T> _box; // waiting for `late` keyword

  final bool _remote;
  final bool _verbose;
  String get type => DataId.getType<T>();

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
  void initialize() {
    box; // at this point box is init'd & assigned
  }

  @mustCallSuper
  Future<void> dispose() async {
    await box?.close();
  }

  // generated model adapter API (metadata, relationships, serialization)

  @protected
  @visibleForTesting
  Repository repositoryFor(String type);

  @protected
  @visibleForTesting
  Map<String, dynamic> get relationshipMetadata;

  @visibleForTesting
  @protected
  void setOwnerInRelationships(DataId<T> owner, T model);

  @visibleForTesting
  @protected
  void setInverseInModel(DataId inverse, T model);

  void syncRelationships(T model) {
    // set model as "owner" in its relationships
    setOwnerInRelationships(model._dataId, model);
  }

  @protected
  @visibleForTesting
  Map<String, dynamic> localSerialize(T model);

  @protected
  @visibleForTesting
  T localDeserialize(Map<String, dynamic> map, {Map<String, dynamic> metadata});

  // protected & private

  @protected
  T initModel(T model, {String key, bool save = false}) {
    if (model == null) {
      return null;
    }

    _assertManager();
    model._repository ??= this;

    // only init dataId if
    //  - it hasn't been set
    //  - there's an updated key to set
    if (model._dataId == null || (key != null && key != model._dataId.key)) {
      // (1) establish key
      model._dataId = DataId<T>(model.id, manager, useKey: key);

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
      box?.put(model._dataId.key, model);
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
    final boxName = DataId.getType<E>();
    if (!manager._hive.isBoxOpen(boxName)) {
      manager._hive.registerAdapter(_HiveTypeAdapter<E>(manager));
    }
    return await manager._hive.openBox(boxName,
        encryptionCipher:
            encryptionKey != null ? HiveAesCipher(encryptionKey) : null);
  }
}
