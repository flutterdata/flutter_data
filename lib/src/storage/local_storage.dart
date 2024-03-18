part of flutter_data;

abstract class LocalStorage {
  var isInitialized = false;

  Future<LocalStorage> initialize();
  Future<void> destroy();
  void dispose();

  Set<Edge> edgesFor(Iterable<(String, String?)> pairs);
  int removeEdgesFor(Iterable<(String, String?)> pairs);
  void addEdge(Edge edge);

  void runOperations(Iterable<_EdgeOperation> operations);

  R readTxn<R>(R Function() fn);
  Future<R> readTxnAsync<R, P>(R Function(Store, P) fn, P param);
  R writeTxn<R>(R Function() fn, {String? log});
  Future<R> writeTxnAsync<R, P>(R Function(Store, P) fn, P param);
}

enum LocalStorageClearStrategy {
  always,
  never,
  whenError,
}

// Objectbox is the default implementation, but can be overridden
final localStorageProvider = Provider<LocalStorage>(
  (ref) {
    print('returning new copy objectboxlocalstorage');
    return ObjectboxLocalStorage(baseDirFn: () => '');
  },
);
