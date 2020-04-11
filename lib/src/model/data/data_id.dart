part of flutter_data;

final _uuid = Uuid();

@optionalTypeArgs
class DataId<T> {
  final DataManager manager;
  String id;
  final String type;
  final String key;

  DataId(this.id, this.manager, {String key, String type})
      : this.key = key ??
            manager?.keysBox?.get('${getType<T>(type)}#$id') ??
            '${getType<T>(type)}#${_uuid.v1().substring(0, 8)}',
        this.type = getType<T>(type) {
    if (id != null && manager != null && !exists) {
      manager.keysBox.put('${this.type}#$id', this.key);
    }
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
