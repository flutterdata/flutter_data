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

  DataGraphNotifier _graph;

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
    _graph = DataGraphNotifier(_metaBox);
    return this;
  }

  Future<void> dispose() async {
    await _metaBox?.close();
  }

  // graph

  StateNotifier<List<DataGraphEvent>> get throttledGraph =>
      _graph.throttle(Duration.zero);

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) {
    return _graph.getKeyForId(type, id, keyIfAbsent: keyIfAbsent);
  }

  String getId(String key) => _graph.getId(key);

  void removeKey(String key) => _graph.removeNode(key);

  void removeId(String type, dynamic id) => _graph.removeNode('$type#$id');

  Map<String, Object> dumpGraph() => _graph.toMap();

  void clearGraph() => _graph.clear();

  @visibleForTesting
  @protected
  set debugGraph(DataGraphNotifier value) => _graph = value;

  final _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}
