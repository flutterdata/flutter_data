part of flutter_data;

class DataManager {
  @visibleForTesting
  DataManager.delegate();

  factory DataManager({bool autoModelInit = true}) {
    if (autoModelInit) {
      return _autoModelInitDataManager = DataManager.delegate();
    }
    return DataManager.delegate();
  }

  final graphNotifier = GraphNotifier(DirectedGraph<String, String>());

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
      {bool clear, bool verbose}) async {
    clear ??= true;
    verbose ??= true;
    assert(locator != null);
    _locator = locator;

    // init hive + box
    final path = path_helper.join((await baseDir).path, 'flutter_data');

    final dirPath = Directory(path);
    final exists = await dirPath.exists();
    if (clear && exists) {
      if (verbose) {
        print('[flutter_data] Destroying all boxes');
      }
      await dirPath.delete(recursive: true);
    }

    _hive.init(path);
    _keysBox = await _hive.openBox<String>('_keys');
    return this;
  }

  Future<void> dispose() async {
    await keysBox.close();
  }

  // utils

  final _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}
