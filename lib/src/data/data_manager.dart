part of flutter_data;

class DataManager {
  @visibleForTesting
  DataManager.delegate();

  factory DataManager({bool autoModelInit = true}) {
    if (autoModelInit) {
      return _autoModelInitDataManager ??= DataManager.delegate();
    }
    return DataManager.delegate();
  }

  static final _uuid = Uuid();

  @visibleForTesting
  @protected
  GraphNotifier graphNotifier;

  final _hive = Hive;

  Locator _locator;

  Locator get locator {
    assert(_locator != null, _assertMessage);
    return _locator;
  }

  Box<Map<String, String>> _metaBox;

  @visibleForTesting
  Box<Map<String, String>> get metaBox {
    assert(_metaBox != null, _assertMessage);
    return _metaBox;
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
    _metaBox = await _hive.openBox('_meta');
    graphNotifier = GraphNotifier(_metaBox);
    return this;
  }

  Future<void> dispose() async {
    await _metaBox?.close();
  }

  // identity

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    return graphNotifier.getKeyForId(type, id, keyIfAbsent: keyIfAbsent);
  }

  String getId(String key) => graphNotifier.getId(key);

  void removeKey(String key) => graphNotifier.removeKey(key);

  Map<String, Object> dumpGraph() => graphNotifier.toMap();

  final _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}
