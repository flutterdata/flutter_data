part of flutter_data;

class InMemoryLocalStorage extends LocalStorage {
  InMemoryLocalStorage() : super(baseDirFn: () => '');

  Future<LocalStorage> initialize() async {
    if (isInitialized) return this;

    try {
      db = sqlite3.openInMemory();
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
