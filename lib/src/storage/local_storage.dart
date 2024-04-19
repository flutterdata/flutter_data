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
      configureRepositoryLocalStorage()
    ],
    child: MaterialApp(
''');
    }
    final baseDirPath = await baseDirFn!();
    dirPath = path_helper.join(baseDirPath, 'flutter_data');

    if (clear == LocalStorageClearStrategy.always) {
      destroy();
    }

    // try {
    //   if (Store.isOpen(dirPath)) {
    //     __store = Store.attach(getXXXBoxModel(), dirPath);
    //   } else {
    //     if (!Directory(dirPath).existsSync()) {
    //       Directory(dirPath).createSync(recursive: true);
    //     }
    //     __store = openStore(
    //       directory: dirPath,
    //       queriesCaseSensitiveDefault: false,
    //     );
    //   }
    // } catch (e, stackTrace) {
    //   print('[flutter_data] Failed to open:\n$e\n$stackTrace');
    // }

    isInitialized = true;
    return this;
  }

  Future<void> destroy() async {
    // Store.removeDbFiles(dirPath);
  }

  void dispose() {
    // store.close();
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
