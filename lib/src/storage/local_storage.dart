part of flutter_data;

class LocalStorage {
  LocalStorage({
    this.baseDirFn,
    this.encryptionKey,
    LocalStorageClearStrategy? clear,
  }) : clear = clear ?? LocalStorageClearStrategy.never;

  var isInitialized = false;

  final String? encryptionKey;
  final FutureOr<String> Function()? baseDirFn;
  final LocalStorageClearStrategy clear;
  late final String dirPath;

  late final Database db;

  Future<LocalStorage> initialize() async {
    if (isInitialized) return this;

    if (baseDirFn == null) {
      throw UnsupportedError('''
A base directory path MUST be supplied to
the localStorageProvider via the `baseDirFn`
callback.

In Flutter, `baseDirFn` will be supplied automatically if
the `path_provider` package is in `pubspec.yaml` AND
Flutter Data is properly configured:

Did you supply the override?

Widget build(context) {
  return ProviderContainer(
    overrides: [
      configureAdapterLocalStorage()
    ],
    child: MaterialApp(
''');
    }
    final baseDirPath = await baseDirFn!();
    dirPath = path_helper.join(baseDirPath, 'flutter_data');

    if (clear == LocalStorageClearStrategy.always) {
      destroy();
    }

    try {
      db = sqlite3.open('/tmp/test.db');

      db.execute('''
        PRAGMA journal_mode = WAL;
        
        CREATE TABLE IF NOT EXISTS edges (
          src INTEGER NOT NULL,
          name TEXT NOT NULL,
          dest INTEGER NOT NULL,
          inverse TEXT
        );

        CREATE TABLE IF NOT EXISTS keys (
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
    final directory = Directory('/tmp');
    final files = await directory.list().toList();
    for (final file in files) {
      if (file is File && file.path.startsWith('/tmp/test.db')) {
        await file.delete();
      }
    }
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
