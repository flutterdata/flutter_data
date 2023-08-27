part of flutter_data;

/// Hive implementation of [LocalAdapter].
// ignore: must_be_immutable
abstract class HiveLocalAdapter<T extends DataModelMixin<T>>
    extends LocalAdapter<T> {
  HiveLocalAdapter(Ref ref)
      : _hiveLocalStorage = ref.read(hiveLocalStorageProvider),
        super(ref);

  final HiveLocalStorage _hiveLocalStorage;

  @protected
  @visibleForTesting
  Box<T>? get box => _box!;
  Box<T>? _box;

  @override
  Future<HiveLocalAdapter<T>> initialize() async {
    if (isInitialized) return this;

    Hive.registerAdapter<T>(
        internalType, (json) => deserialize(json as Map<String, dynamic>));

    try {
      if (_hiveLocalStorage.clear == LocalStorageClearStrategy.always) {
        Hive.box(name: internalType).deleteFromDisk();
      }
      _box = Hive.box(name: internalType);
    } catch (e, stackTrace) {
      print('[flutter_data] Box failed to open:\n$e\n$stackTrace');
    }

    return this;
  }

  @override
  bool get isInitialized => _box != null;

  @override
  void dispose() {
    _box?.close();
  }

  // protected API

  @override
  List<T> findAll() {
    final keys = _box?.keys ?? [];
    return _box?.getAll(keys).filterNulls.toList() ?? [];
  }

  @override
  T? findOne(String? key) {
    if (key == null) return null;
    return _box?.get(key);
  }

  @override
  Future<T> save(String key, T model, {bool notify = true}) async {
    if (_box == null) return model;

    final keyExisted = _box!.containsKey(key);
    _box!.put(key, model);
    if (notify) {
      graph._notify(
        [key],
        type: keyExisted
            ? DataGraphEventType.updateNode
            : DataGraphEventType.addNode,
      );
    }
    return model;
  }

  @override
  Future<void> delete(String key, {bool notify = true}) async {
    if (_box == null) return;
    _box!.delete(key);
    final id = graph.getIdForKey(key);
    if (id != null) {
      graph.removeId(internalType, id, notify: false);
    }
    graph.removeKey(key);
  }

  @override
  Future<void> clear() async {
    if (_box == null) return;
    _box!.clear();
    graph._notify([internalType], type: DataGraphEventType.clear);
  }
}
