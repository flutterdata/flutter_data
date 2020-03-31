part of flutter_data;

class DataManager {
  final FutureOr<Directory> _baseDir;
  Locator locator;
  final _hive = Hive;

  @visibleForTesting
  Box<String> keysBox;

  DataManager(this._baseDir, {this.locator});

  // initialize shared resources
  // clear is true by default during alpha releases
  Future<DataManager> init({bool clear = true}) async {
    _hive.init(path_helper.join((await _baseDir).path, 'flutter_data'));
    keysBox = await _openBox<String>('_keys', clear: clear);
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
}
