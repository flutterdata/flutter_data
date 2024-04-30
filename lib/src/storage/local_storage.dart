part of flutter_data;

class LocalStorage {
  LocalStorage({
    required this.baseDirFn,
    LocalStorageClearStrategy? clear,
    this.busyTimeout = 5000,
  }) : clear = clear ?? LocalStorageClearStrategy.never;

  var isInitialized = false;

  final FutureOr<String> Function() baseDirFn;
  final LocalStorageClearStrategy clear;
  final int busyTimeout;

  late final String path;

  @protected
  late final Database db;

  Future<LocalStorage> initialize({bool inIsolate = false}) async {
    if (isInitialized) return this;

    final baseDirPath = await baseDirFn();
    path = path_helper.join(baseDirPath, 'flutter_data.db');

    try {
      if (clear == LocalStorageClearStrategy.always) {
        await destroy();
      }

      if (Platform.isWindows) {
        open.overrideFor(OperatingSystem.windows, _openOnWindows);
      }

      db = sqlite3.open(path, mutex: false);

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
      if (clear == LocalStorageClearStrategy.whenError) {
        dispose();
        await destroy();
        await initialize();
      }
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
    db.dispose();
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

// platforms

DynamicLibrary _openOnWindows() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final libraryNextToScript =
      File(path_helper.join(scriptDir.path, 'sqlite3.dll'));
  return DynamicLibrary.open(libraryNextToScript.path);
}
