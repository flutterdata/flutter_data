part of flutter_data;

class LocalStorage {
  LocalStorage({
    required this.baseDirFn,
    this.clear = LocalStorageClearStrategy.whenError,
    this.busyTimeout = 5000,
  });

  var isInitialized = false;

  final FutureOr<String> Function() baseDirFn;
  final LocalStorageClearStrategy clear;
  final int busyTimeout;

  String path = '';
  bool inIsolate = false;
  bool triedOnceAfterError = false;

  Database? _db;

  @protected
  Database get db => _db!;

  Future<LocalStorage> initialize({bool inIsolate = false}) async {
    if (isInitialized) return this;
    this.inIsolate = inIsolate;

    final baseDirPath = await baseDirFn();
    path = path_helper.join(baseDirPath, 'flutter_data.db');

    try {
      if (clear == LocalStorageClearStrategy.always) {
        await destroy();
      }

      _db = sqlite3.open(path, mutex: false);

      if (inIsolate) {
        db.execute('''
          PRAGMA journal_mode = WAL;
          PRAGMA busy_timeout = $busyTimeout;
        ''');
      } else {
        db.execute('''
          PRAGMA journal_mode = WAL;
          PRAGMA busy_timeout = $busyTimeout;
          VACUUM;
      
          CREATE TABLE IF NOT EXISTS _edges (
            key_ INTEGER NOT NULL,
            name_ TEXT,
            _key INTEGER NOT NULL,
            _name TEXT,
            UNIQUE (key_, name_, _key)
            UNIQUE (_key, _name, key_)
          );
          CREATE INDEX IF NOT EXISTS key_name_idx ON _edges(key_, name_);
          CREATE INDEX IF NOT EXISTS inv_key_name_idx ON _edges(_key, _name);

          CREATE TABLE IF NOT EXISTS _keys (
            key INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            id TEXT,
            is_int INTEGER DEFAULT 0
          );
          CREATE INDEX IF NOT EXISTS id_idx ON _keys(id);

          CREATE TABLE IF NOT EXISTS _offline_operations (
            label TEXT PRIMARY KEY,
            request TEXT NOT NULL,
            timestamp DATETIME,
            headers TEXT,
            body TEXT,
            key TEXT
          );
        ''');
      }
    } catch (e, stackTrace) {
      print('[flutter_data] Failed to open:\n$e\n$stackTrace');
      if (triedOnceAfterError == false &&
          clear == LocalStorageClearStrategy.whenError) {
        dispose();
        await destroy();
        await initialize();
      }
      triedOnceAfterError = true;
    }

    isInitialized = true;

    return this;
  }

  Future<void> destroy() async {
    final directory = Directory(path).parent;
    final files = await directory.list().toList();
    final futures = files
        .where((f) => f is File && f.path.startsWith(path))
        .map((f) => f.delete());
    await Future.wait(futures);
  }

  void dispose() {
    _db?.dispose();
    isInitialized = false;
  }
}

enum LocalStorageClearStrategy {
  always,
  never,
  whenError,
}

// sqlite is the default implementation, but can be overridden
final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(baseDirFn: () => ''),
);
