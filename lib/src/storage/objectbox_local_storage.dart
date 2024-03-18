part of flutter_data;

class ObjectboxLocalStorage extends LocalStorage {
  ObjectboxLocalStorage({
    this.baseDirFn,
    this.encryptionKey,
    LocalStorageClearStrategy? clear,
  }) : clear = clear ?? LocalStorageClearStrategy.never;

  final String? encryptionKey;
  final FutureOr<String> Function()? baseDirFn;
  final LocalStorageClearStrategy clear;
  late final String dirPath;

  Store? __store;

  @protected
  @visibleForTesting
  Store get store => __store!;

  @override
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

    try {
      if (Store.isOpen(dirPath)) {
        __store = Store.attach(getObjectBoxModel(), dirPath);
      } else {
        if (!Directory(dirPath).existsSync()) {
          Directory(dirPath).createSync(recursive: true);
        }
        __store = openStore(
          directory: dirPath,
          queriesCaseSensitiveDefault: false,
        );
      }
    } catch (e, stackTrace) {
      print('[flutter_data] Objectbox failed to open:\n$e\n$stackTrace');
    }

    isInitialized = true;
    return this;
  }

  Future<void> destroy() async {
    Store.removeDbFiles(dirPath);
  }

  @override
  void dispose() {
    store.close();
  }

  //

  Set<Edge> edgesFor(Iterable<(String, String?)> pairs) {
    if (pairs.isEmpty) {
      return {};
    }
    return _queryEdgesFor(pairs).find().toSet();
  }

  @override
  void addEdge(Edge edge) {
    store.box<Edge>().put(edge);
  }

  @override
  int removeEdgesFor(Iterable<(String, String?)> pairs) {
    if (pairs.isEmpty) {
      return 0;
    }
    return _queryEdgesFor(pairs).remove();
  }

  Query<Edge> _queryEdgesFor(Iterable<(String, String?)> pairs) {
    final conditions = pairs.map((p) => _queryConditionTo(p.$1, p.$2));
    final condition = conditions.reduce((acc, e) => acc | e);
    return store.box<Edge>().query(condition).build();
  }

  Condition<Edge> _queryConditionTo(String from, String? name, [String? to]) {
    var left = Edge_.from.equals(from);
    if (name != null) {
      left = left & Edge_.name.equals(name);
    }
    if (to != null) {
      left = left & Edge_.to.equals(to);
    }
    var right = Edge_.to.equals(from);
    if (name != null) {
      right = right & Edge_.inverseName.equals(name);
    }
    if (to != null) {
      right = right & Edge_.from.equals(to);
    }
    return left | right;
  }

  //

  @override
  R readTxn<R>(R Function() fn) => store.runInTransaction(TxMode.read, fn);

  @override
  Future<R> readTxnAsync<R, P>(R Function(Store, P) fn, P param) async =>
      store.runInTransactionAsync(
          TxMode.read, (store, param) => fn(store, param), param);

  @override
  R writeTxn<R>(R Function() fn, {String? log}) {
    return logTime(log, () => store.runInTransaction(TxMode.write, fn));
  }

  @override
  Future<R> writeTxnAsync<R, P>(R Function(Store, P) fn, P param) =>
      store.runInTransactionAsync<R, P>(
          TxMode.write, (store, param) => fn(store, param), param);

  @override
  void runOperations(Iterable<_EdgeOperation> operations) {
    writeTxn(() => store.runOperations(operations));
  }
}

extension StoreX on Store {
  void runOperations(Iterable<_EdgeOperation> operations) {
    if (operations.isEmpty) return;
    final box = this.box<Edge>();
    for (final op in operations) {
      switch (op) {
        case RemoveEdgeOperation(edge: final edge):
          box.remove(edge.internalKey);
          break;
        case AddEdgeOperation(edge: final edge):
          box.put(edge);
          break;
        case UpdateEdgeOperation(edge: final edge, newTo: final newTo):
          box.remove(edge.internalKey);
          box.put(Edge(
              from: edge.from,
              name: edge.name,
              to: newTo,
              inverseName: edge.inverseName));
          break;
      }
    }
  }
}
