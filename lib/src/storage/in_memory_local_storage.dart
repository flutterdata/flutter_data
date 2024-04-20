part of flutter_data;

class InMemoryLocalStorage extends LocalStorage {
  InMemoryLocalStorage() : super(baseDirFn: () => '');

  Future<LocalStorage> initialize() async {
    if (isInitialized) return this;

    try {
      db = sqlite3.openInMemory();

      db.execute('''
        CREATE TABLE IF NOT EXISTS _edges (
          src INTEGER NOT NULL,
          name TEXT NOT NULL,
          dest INTEGER NOT NULL,
          inverse TEXT
        );

        CREATE TABLE IF NOT EXISTS _keys (
          key INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          id TEXT,
          is_int INTEGER DEFAULT 0
        );
      ''');
    } catch (e, stackTrace) {
      print('[flutter_data] Failed to open:\n$e\n$stackTrace');
    }

    isInitialized = true;
    return this;
  }

  Future<void> destroy() async {
    db.dispose();
  }
}
