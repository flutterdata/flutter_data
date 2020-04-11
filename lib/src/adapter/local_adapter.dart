part of flutter_data;

// ignore: must_be_immutable
abstract class LocalAdapter<T extends DataSupportMixin<T>> with TypeAdapter<T> {
  @visibleForTesting
  @protected
  final DataManager manager;

  @visibleForTesting
  @protected
  final Box<T> box;

  final Box<String> _keysBox;

  static const _oneFrameDuration = Duration(milliseconds: 16);

  // dynamic so we don't expose the Box type to the .g files
  LocalAdapter(dynamic box, this.manager)
      : this.box = box as Box<T>,
        _keysBox = manager.keysBox;

  // abstract

  @visibleForTesting
  @protected
  Map<String, dynamic> serialize(T model);

  @visibleForTesting
  @protected
  T deserialize(Map<String, dynamic> map, {String key});

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

  // Repository methods

  List<T> findAll() {
    return List<T>.from(box.values);
  }

  Stream<List<T>> watchAll() {
    return box.watch().map((_) {
      return findAll();
    }).debounceTime(_oneFrameDuration);
  }

  T findOne(String key) => key != null ? box.get(key) : null;

  Stream<T> watchOne(String key) {
    return box
        .watch(key: key)
        .map((_) => findOne(key))
        .debounceTime(_oneFrameDuration);
  }

  Future<void> save(String key, T model) async {
    await box.put(key, model);
  }

  Future<void> delete(String key) async {
    await box.delete(key);
  }

  bool isNew(T model) => model.id == null;

  Future<void> clear() async {
    await box?.clear();
  }

  Future<void> dispose() async {
    await box?.close();
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
