part of flutter_data;

class DataManager {
  @visibleForTesting
  DataManager.delegate();

  factory DataManager({bool autoManager = true}) {
    if (autoManager) {
      return _autoManager ??= DataManager.delegate();
    }
    return DataManager.delegate();
  }

  static final _uuid = Uuid();

  @visibleForTesting
  @protected
  DataGraphNotifier graph;

  final _hive = Hive;

  Locator _locator;

  Locator get locator {
    assert(_locator != null, _assertMessage);
    return _locator;
  }

  Box<Map<String, List<String>>> _metaBox;

  @visibleForTesting
  Box<Map<String, List<String>>> get metaBox {
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
    graph = DataGraphNotifier(_metaBox);
    return this;
  }

  Future<void> dispose() async {
    await _metaBox?.close();
  }

  // identity

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    return graph.getKeyForId(type, id, keyIfAbsent: keyIfAbsent);
  }

  String getId(String key) => graph.getId(key);

  void removeKey(String key) => graph.removeNode(key);

  void removeId(String type, dynamic id) => graph.removeNode('$type#$id');

  Map<String, Object> dumpGraph() => graph.toMap();

  //

  final _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}
