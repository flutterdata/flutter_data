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

  R _writeTxn<R>(R Function() fn, {String? log}) {
    return logTime(log, () => store.runInTransaction(TxMode.write, fn));
  }

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
  String getKeyForId(String type, Object? id, {String? orElse}) {
    if (id == null || id.toString().isEmpty) {
      return orElse ?? DataHelpers.generateTempKey(type);
    }
    type = DataHelpers.internalTypeFor(type);
    return DataHelpers.fastHashId(type, id.toString());
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    return logTime(null, () {
      final internalKey = key.detypifyKey();
      if (internalKey == null) {
        return null;
      }
      final model = store.box<StoredModel>().get(internalKey);
      // NOTE: might bring in data for now - until we switch to multi-box
      if (model?.id == null) {
        return null;
      }
      if (model!.isInt) {
        return int.parse(model.id!);
      }
      return model.id;
    });
  }

  // utils

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
