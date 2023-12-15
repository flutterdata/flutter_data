// ignore_for_file: comment_references

part of flutter_data;

/// Used to notify events.
///
/// Watchers like [Repository.watchAllNotifier] or [BelongsTo.watch]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class CoreNotifier extends DelayedStateNotifier<DataGraphEvent>
    with _Lifecycle {
  final Ref ref;
  @protected
  CoreNotifier(this.ref);

  ObjectboxLocalStorage get _localStorage => ref.read(localStorageProvider);

  @override
  bool isInitialized = false;

  final List<_KeyOperation> _keyOperations = [];

  late final Map<int, String> _keyCache;

  Store? __store;

  @protected
  @visibleForTesting
  Store get store => __store!;
  late Box<StoredModel> _storedModelBox;
  late Box<Edge> _edgeBox;

  /// Initializes storage systems
  Future<CoreNotifier> initialize() async {
    if (isInitialized) return this;
    await _localStorage.initialize();

    try {
      final dirPath = path_helper.join(_localStorage.path, 'flutter_data');
      if (Store.isOpen(dirPath)) {
        __store = Store.attach(getObjectBoxModel(), dirPath);
      } else {
        __store = openStore(
          directory: dirPath,
          queriesCaseSensitiveDefault: false,
        );
      }
      _storedModelBox = store.box<StoredModel>();
      _edgeBox = store.box<Edge>();
    } catch (e, stackTrace) {
      print('[flutter_data] Objectbox failed to open:\n$e\n$stackTrace');
    }

    if (_localStorage.clear == LocalStorageClearStrategy.always) {
      // TODO no way of removing everything? maybe remove file before openStore?
      // _localStorage.destroy();

      _storedModelBox.removeAll();
      _edgeBox.removeAll();
    }

    // initialize/populate key-ID mapping cache
    late List<String> typeIds;
    late List<int> keys;
    _readTxn(() {
      typeIds =
          _storedModelBox.query().build().property(StoredModel_.typeId).find();
      keys = _storedModelBox.query().build().property(StoredModel_.key).find();
    });

    final entries =
        typeIds.mapIndexed((i, typeId) => MapEntry(keys[i], typeId));
    _keyCache = Map<int, String>.fromEntries(entries);

    isInitialized = true;
    return this;
  }

  @override
  void dispose() {
    if (isInitialized) {
      store.close();
      isInitialized = false;
      super.dispose();
    }
  }

  // Transactions

  R _readTxn<R>(R Function() fn) => store.runInTransaction(TxMode.read, fn);

  Future<R> _readTxnAsync<R, P>(R Function(Store, P) fn, P param) async =>
      store.runInTransactionAsync(
          TxMode.read, (store, param) => fn(store, param), param);

  R _writeTxn<R>(R Function() fn) => store.runInTransaction(TxMode.write, fn);

  Future<R> _writeTxnAsync<R, P>(R Function(Store, P) fn, P param) =>
      store.runInTransactionAsync<R, P>(
          TxMode.write, (store, param) => fn(store, param), param);

  // Key-related methods

  /// Finds a model's key.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  String? getKeyForId(String type, Object? id, {String? keyIfAbsent}) {
    if (id == null) {
      return keyIfAbsent;
    }

    type = DataHelpers.internalTypeFor(type);
    final typeId = id.typifyWith(type);

    print('--- [read] key for given id');

    final entry = _keyCache.entries.firstWhereOrNull((e) => e.value == typeId);

    if (entry == null) {
      if (keyIfAbsent != null) {
        _keyCache[keyIfAbsent.detypify() as int] = typeId;
        _keyOperations.add(AddKeyOperation(keyIfAbsent, typeId));
        return keyIfAbsent;
      }
      return null;
    }

    return entry.key.typifyWith(type);
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    return _keyCache[key.detypify() as int]?.detypify();
  }

  /// Removes type-ID mapping for [key]
  void removeIdForKey(String key, {bool notify = true}) {
    _keyCache.remove(key.detypify() as int);
    _keyOperations.add(RemoveKeyOperation(key));
  }

  // utils

  /// Returns a [Map] representation of the internal ID db
  Map<int, String> toIdMap() {
    return _keyCache;
  }

  void _notify(List<String> keys,
      {String? metadata, required DataGraphEventType type}) {
    if (mounted) {
      state = DataGraphEvent(type: type, metadata: metadata, keys: keys);
    }
  }
}

enum DataGraphEventType {
  removeNode,
  updateNode,
  clear,
  addEdge,
  removeEdge,
  updateEdge,
  doneLoading,
}

extension DataGraphEventTypeX on DataGraphEventType {
  bool get isNode => [
        DataGraphEventType.updateNode,
        DataGraphEventType.removeNode,
      ].contains(this);
  bool get isEdge => [
        DataGraphEventType.addEdge,
        DataGraphEventType.updateEdge,
        DataGraphEventType.removeEdge,
      ].contains(this);
}

class DataGraphEvent {
  const DataGraphEvent({
    required this.keys,
    required this.type,
    this.metadata,
  });
  final List<String> keys;
  final DataGraphEventType type;
  final String? metadata;

  @override
  String toString() {
    return '${type.toShortString()}: $keys';
  }
}

extension _DataGraphEventX on DataGraphEventType {
  String toShortString() => toString().split('.').last;
}

final coreNotifierProvider = Provider<CoreNotifier>((ref) => CoreNotifier(ref));
