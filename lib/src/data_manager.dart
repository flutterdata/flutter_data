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

  GraphNotifier _graphNotifier;
  void Function() _disposeListener;

  final _hive = Hive;

  Locator _locator;

  Locator get locator {
    assert(_locator != null, _assertMessage);
    return _locator;
  }

  Box _metaBox;

  @visibleForTesting
  Box get metaBox {
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
    initGraphNotifier(Map.from(_metaBox.toMap()));
    return this;
  }

  void initGraphNotifier(Map<String, Map<String, Set<String>>> source) {
    // TODO do we need to exclude other "non-keys" like _type#posts for type adapter?
    _graphNotifier = GraphNotifier(DataGraph.fromMap(source));

    _graphNotifier.onError = (err, trace) {
      throw err;
    };

    _disposeListener = _graphNotifier.addListener((event) {
      for (final key in event.keys) {
        final edges = event.graph.getAll(key);
        if (edges == null) {
          // node was deleted
          metaBox.delete(key);
        } else {
          metaBox.put(key, edges);
        }
      }
    });
  }

  Future<void> dispose() async {
    _disposeListener?.call();
    await _metaBox?.close();
  }

  // identity

  String getKeyForId(String type, dynamic id, {String keyIfAbsent}) =>
      _graphNotifier.getKeyForId(type, id, keyIfAbsent: keyIfAbsent);

  String getId(String key) => _graphNotifier.getId(key);

  void removeKey(String key) => _graphNotifier.removeKey(key);

  // utils

  Map<String, Object> dumpGraph({bool withKeys = true}) =>
      _graphNotifier.debugState.graph.toMap(withKeys: withKeys);

  final _assertMessage = '''\n
This manager has not been initialized.

Please ensure you call DataManager#init(),
either directly or through FlutterData.init().
''';
}
