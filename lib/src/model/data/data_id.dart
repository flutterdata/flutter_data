part of flutter_data;

final _uuid = Uuid();

@optionalTypeArgs
class DataId<T> {
  final DataManager manager;
  dynamic id;
  final String type;
  final String key;

  // key will be assigned in this order
  // (1) if non-null ID is supplied, key will be found
  // (2) if ID was null or not found, use provided key
  // (3) if no key was provided, create one
  // ignore_for_file: unnecessary_this
  DataId(this.id, this.manager, {String key, String type})
      : this.key = manager?.keysBox?.get('${getType<T>(type)}#$id') ??
            key ??
            '${getType<T>(type)}#${_uuid.v1().substring(0, 8)}',
        this.type = getType<T>(type) {
    // key/ID association will only be made if
    // ID is not null and key does not already exist
    if (id != null && manager != null && !hasKey('${this.type}#$id')) {
      manager.keysBox.put('${this.type}#$id', this.key);
    }
  }

  bool hasKey(key) {
    // do not confuse key (map key) with this.key (fd key)
    return manager.keysBox.containsKey(key);
  }

  void delete() {
    // do not confuse key (map key) with this.key (fd key)
    final key = '${this.type}#$id';
    if (hasKey(key)) {
      manager.keysBox.delete(key);
    }
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
