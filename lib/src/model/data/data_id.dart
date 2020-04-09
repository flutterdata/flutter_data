part of flutter_data;

final _uuid = Uuid();

@optionalTypeArgs
class DataId<T> {
  final DataManager manager;
  String id;
  final String type;
  // can temporarily hold a model
  // (useful when DataManager is not yet available)
  final T model;

  DataId(this.id, this.manager, {String key, String type, T model})
      : type = getType<T>(type),
        this.model = (manager == null ? model : null) {
    if (key != null) {
      this.key = key;
    }
  }

  String get key {
    String _key;
    if (id != null) {
      key = manager.keysBox.get('$type#$id');
    }
    if (_key == null) {
      key = _key = '$type#${_uuid.v1().substring(0, 8)}';
    }
    return _key;
  }

  set key(String key) {
    manager.keysBox.put('$type#$id', key);
  }

  bool get exists {
    return manager.keysBox.containsKey('$type#$id');
  }

  // utils

  static String getType<T>([String type]) =>
      pluralize((type ?? T.toString()).toLowerCase());

  @optionalTypeArgs
  static List<DataId<E>> byKeys<E>(List<String> keys, DataManager manager,
      {String type}) {
    assert(keys != null);
    return manager.keysBox
        .toMap()
        .entries
        .where((e) => keys.contains(e.value))
        .map((e) => (e.key.toString().split('#')..removeAt(0))
            .join('#')) // (map keys are ids)
        .map((id) => DataId<E>(id, manager, type: type))
        .toList();
  }

  @optionalTypeArgs
  static DataId<E> byKey<E>(String key, DataManager manager, {String type}) {
    final list = byKeys<E>([key], manager, type: type);
    return list.isNotEmpty ? list.first : null;
  }

  // identity functions

  @override
  bool operator ==(dynamic other) => identical(this, other) || key == other.key;

  @override
  int get hashCode => runtimeType.hashCode ^ key.hashCode;

  @override
  String toString() => key;
}
