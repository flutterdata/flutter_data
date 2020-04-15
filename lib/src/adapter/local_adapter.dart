part of flutter_data;

@sealed
// ignore: must_be_immutable
abstract class LocalAdapter<T extends DataSupportMixin<T>> with TypeAdapter<T> {
  @visibleForTesting
  @protected
  final DataManager manager;

  Box<T> _box;
  final HiveInterface _hive;
  final Box<String> _keysBox;

  static const _oneFrameDuration = Duration(milliseconds: 16);

  LocalAdapter(this.manager, {box})
      : _keysBox = manager.keysBox,
        _hive = manager._hive,
        _box = box as Box<T>;

  Future<LocalAdapter<T>> init() async {
    if (_box == null) {
      _hive.registerAdapter(this);
      _box = await _hive.openBox(DataId.getType<T>());
    }
    return this;
  }

  // abstract

  @visibleForTesting
  @protected
  Map<String, dynamic> serialize(T model);

  @visibleForTesting
  @protected
  T deserialize(Map<String, dynamic> map);

  @visibleForTesting
  @protected
  void setOwnerInRelationships(DataId<T> owner, T model);

  @visibleForTesting
  @protected
  void setInverseInModel(DataId inverse, T model);

  // hive serialization

  @override
  int get typeId {
    final type = DataId.getType<T>();
    final key = '_type_$type';
    final id = _keysBox.get(key, defaultValue: _keysBox.keys.length.toString());
    _keysBox.put(key, id);
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

  // methods

  T _init(T model, {String key, bool save = true}) {
    if (model == null) {
      return null;
    }

    // (1) establish key
    final originalKey = key ?? model.key;
    model._dataId = manager.dataId<T>(model.id, key: originalKey);

    // if the existing key is different to the resulting key
    // the original key for this ID has been found-
    // therefore we need to delete the stray record
    if (originalKey != null && originalKey != model.key) {
      // ignore: unawaited_futures
      delete(originalKey);
    }

    // (2) set owner
    setOwnerInRelationships(model._dataId, model);

    if (save) {
      this.save(model);
    }

    return model;
  }

  List<String> get keys => List<String>.from(_box.keys);

  List<T> findAll() {
    return keys.map(findOne).toList();
  }

  Stream<List<T>> watchAll() {
    return _box.watch().map((_) {
      return findAll();
    }).debounceTime(_oneFrameDuration);
  }

  @visibleForTesting
  @protected
  T findOne(String key) {
    if (key == null) {
      return null;
    }
    return _init(_box.get(key), key: key, save: false);
  }

  Stream<T> watchOne(String key) {
    return _box
        .watch(key: key)
        .map((_) => findOne(key))
        .debounceTime(_oneFrameDuration);
  }

  Future<void> save(T model, {String key}) async {
    if (model.key == null) {
      model = _init(model, key: key, save: false);
    }
    await _box.put(model.key, model);
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  bool isNew(T model) => model.id == null;

  Future<void> clear() async {
    await _box?.deleteFromDisk();
  }

  Future<void> dispose() async {
    await _box?.close();
  }

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
}
