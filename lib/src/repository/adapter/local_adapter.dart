part of flutter_data;

// ignore: must_be_immutable
mixin LocalAdapter<T extends DataSupportMixin<T>>
    on Repository<T>, TypeAdapter<T> {
  Box<T> _box;

  // final HiveInterface _hive;
  // final Box<String> _keysBox;
  // final HiveAesCipher _hiveEncryptionCipher;

  // static const _oneFrameDuration = Duration(milliseconds: 16);

  // LocalAdapter(this.manager, {List<int> encryptionKey, box})
  //     : _keysBox = manager.keysBox,
  //       _hive = manager._hive,
  //       _box = box as Box<T>,
  //       _hiveEncryptionCipher =
  //           encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  // Future<LocalAdapter<T>> init() async {
  //   if (_box == null) {
  //     _hive.registerAdapter(this);
  //     _box = await _hive.openBox(DataId.getType<T>(),
  //         encryptionCipher: _hiveEncryptionCipher);
  //   }
  //   return this;
  // }

  // internal

  @override
  String get type => DataId.getType<T>();

  // hive serialization

  @override
  int get typeId {
    final type = DataId.getType<T>();
    final key = '_type_$type';
    final id = manager._keysBox
        .get(key, defaultValue: manager._keysBox.keys.length.toString());
    manager._keysBox.put(key, id);
    return int.parse(id);
  }

  @override
  T read(reader) {
    var n = reader.readByte();
    var fields = <String, dynamic>{
      for (var i = 0; i < n; i++) reader.read().toString(): reader.read(),
    };
    return deserialize(fixMap(fields));
  }

  @override
  void write(writer, T obj) {
    final _map = serialize(obj);
    writer.writeByte(_map.keys.length);
    for (var k in _map.keys) {
      writer.write(k);
      writer.write(_map[k]);
    }
  }

  // metadata

  @override
  void syncRelationships(T model) {
    // set model as "owner" in its relationships
    setOwnerInRelationships(model._dataId, model);
  }

  @override
  Repository repositoryFor(String type);

  @protected
  Map<String, dynamic> get relationshipMetadata;

  @visibleForTesting
  @protected
  void setOwnerInRelationships(DataId<T> owner, T model);

  @visibleForTesting
  @protected
  void setInverseInModel(DataId inverse, T model);

  // methods

  List<String> get keys => List<String>.from(_box.keys);

  @protected
  @visibleForTesting
  List<T> localFindAll() {
    return List<T>.from(_box.values);
  }

  @protected
  @visibleForTesting
  T localFindOne(String key) {
    if (key == null) {
      return null;
    }
    return _box.get(key);
  }

  @protected
  @visibleForTesting
  Future<void> localSave(String key, T model) async {
    if (key == null) {
      return null;
    }
    await _box.put(key, model);
  }

  @protected
  @visibleForTesting
  Future<void> localDelete(String key) async {
    await _box.delete(key);
  }

  @protected
  @visibleForTesting
  Future<void> localClear() async {
    await _box?.deleteFromDisk();
  }

  @override
  Future<void> dispose() async {
    await _box?.close();
    await super.dispose();
  }

  // initialization

  @override
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
        localDelete(key);
        DataId.byKey<T>(key, manager)?.delete();
      }

      // (2) sync relationships
      syncRelationships(model);
    }

    // (3) save locally
    if (save) {
      localSave(model._dataId.key, model);
    }

    return model;
  }

  @override
  Map<dynamic, T> dumpLocal() => _box.toMap();

  // utils

  @visibleForTesting
  @protected
  Map<String, dynamic> fixMap(Map<String, dynamic> map) {
    // Hive deserializes maps as Map<dynamic, dynamic>
    // but we *know* we serialized them as Map<String, dynamic>

    for (var e in map.entries) {
      if (e.value is Map && e.value is! Map<String, dynamic>) {
        map[e.key] = Map<String, dynamic>.from(e.value as Map);
      }
      if (e.value is List<Map>) {
        map[e.key] = List<Map<String, dynamic>>.from(e.value as List);
      }
    }
    return map;
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
}
