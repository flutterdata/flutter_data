part of flutter_data;

class DataManager {
  DataManager.delegate(this.autoModelInit);
  factory DataManager({bool autoModelInit = true}) {
    if (autoModelInit) {
      return _autoModelInitDataManager = DataManager.delegate(true);
    }
    return DataManager.delegate(false);
  }

  @visibleForTesting
  final bool autoModelInit;

  final _hive = Hive;

  Locator _locator;

  Locator get locator {
    assert(_locator != null, _assertMessage);
    return _locator;
  }

  Box<String> _keysBox;

  @visibleForTesting
  Box<String> get keysBox {
    assert(_keysBox != null, _assertMessage);
    return _keysBox;
  }

  // initialize shared resources
  // clear is true by default during alpha releases
  Future<DataManager> init(FutureOr<Directory> baseDir, Locator locator,
      {bool clear = true}) async {
    assert(locator != null);
    _locator = locator;

    // init hive + box
    _hive.init(path_helper.join((await baseDir).path, 'flutter_data'));
    _keysBox = await _openBox<String>('_keys', clear: clear);
    return this;
  }

  //

  Future<Box<T>> _openBox<T>(String name, {bool clear = false}) async {
    if (clear) {
      print('[flutter_data] Destroying box: $name');
      await _hive.deleteBoxFromDisk(name);
    }
    return await _hive.openBox<T>(name);
  }

  Future<LocalAdapter<T>> initAdapter<T extends DataSupport<T>>(
      bool clear, LocalAdapter<T> Function(Box<T>) callback) async {
    Box<T> box;
    final boxName = DataId.getType<T>();
    if (_hive.isBoxOpen(boxName)) {
      box = _hive.box(boxName);
    } else {
      box = await _openBox<T>(boxName, clear: clear);
    }
    final adapter = callback(box);
    _hive.registerAdapter(adapter);
    return adapter;
  }

  Future<void> dispose() async {
    await keysBox.close();
  }

  // utils

  String _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}

extension ManagerDataId on DataManager {
  DataId<T> dataId<T extends DataSupport<T>>(String id,
          {String key, String type, T model}) =>
      DataId<T>(id, this, key: key, type: type, model: model);
}
