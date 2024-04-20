part of flutter_data;

class LocalStorage {
  LocalStorage({
    required this.baseDirFn,
    this.encryptionKey,
    LocalStorageClearStrategy? clear,
  }) : clear = clear ?? LocalStorageClearStrategy.never;

  var isInitialized = false;

  final String? encryptionKey;
  final FutureOr<String> Function() baseDirFn;
  final LocalStorageClearStrategy clear;

  late final String path;
  late final Database db;

  Future<LocalStorage> initialize() async {
    if (isInitialized) return this;

    final baseDirPath = await baseDirFn();
    path = path_helper.join(baseDirPath, 'flutter_data.db');

    try {
      if (clear == LocalStorageClearStrategy.always) {
        await destroy();
      }

      db = sqlite3.open(path);

      db.execute('''
          PRAGMA journal_mode = WAL;
          VACUUM;
          
          CREATE TABLE IF NOT EXISTS _edges (
            src INTEGER NOT NULL,
            name TEXT NOT NULL,
            dest INTEGER NOT NULL,
            inverse TEXT
          );
          CREATE INDEX src_name_idx ON _edges(src, name);
          CREATE INDEX dest_inverse_idx ON _edges(dest, inverse);

          CREATE TABLE IF NOT EXISTS _keys (
            key INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            id TEXT,
            is_int INTEGER DEFAULT 0
          );
          CREATE INDEX id_idx ON _keys(id);

          CREATE TABLE IF NOT EXISTS _offline_operations (
            label TEXT PRIMARY KEY,
            request TEXT NOT NULL,
            timestamp DATETIME,
            headers TEXT,
            body TEXT,
            key TEXT
          );
        ''');
    } catch (e, stackTrace) {
      print('[flutter_data] Failed to open:\n$e\n$stackTrace');
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
