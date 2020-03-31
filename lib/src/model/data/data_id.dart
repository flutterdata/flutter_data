part of flutter_data;

final _uuid = Uuid();

@optionalTypeArgs
class DataId<T> extends IdentifierObject {
  final DataManager manager;
  // can temporarily hold a model
  // (useful when DataManager is not yet available)
  final T model;

  DataId(String id, this.manager, {String key, String type, T model})
      : assert(id != null),
        this.model = (manager == null ? model : null),
        super(getType<T>(type), id.toString()) {
    if (key != null) {
      this.key = key;
    }
  }

  String get key {
    var _key = manager.keysBox.get('$type#$id');
    if (_key == null) {
      key = _key = '$type#${_uuid.v1().substring(0, 8)}';
    }
    return _key;
  }

  set key(String key) {
    manager.keysBox.put('$type#$id', key);
  }

  // utils

  static String getType<T>([String type]) =>
      pluralize((type ?? T.toString()).toLowerCase());

  static List<DataId<E>> byKeys<E extends DataSupport<E>>(
      List<String> keys, DataManager manager) {
    assert(keys != null);
    return manager.keysBox
        .toMap()
        .entries
        .where((e) => keys.contains(e.value))
        .map((e) => (e.key.toString().split('#')..removeAt(0))
            .join('#')) // (map keys are ids)
        .map((id) => DataId<E>(id, manager))
        .toList();
  }

  static DataId<E> byKey<E extends DataSupport<E>>(
      String key, DataManager manager) {
    final list = byKeys<E>([key], manager);
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
