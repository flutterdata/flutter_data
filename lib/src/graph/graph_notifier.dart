// ignore_for_file: comment_references

part of flutter_data;

/// Used to notify events.
///
/// Watchers like [Repository.watchAllNotifier] or [BelongsTo.watch]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class GraphNotifier extends DelayedStateNotifier<DataGraphEvent>
    with _Lifecycle {
  final Ref ref;
  @protected
  GraphNotifier(this.ref);

  ObjectboxLocalStorage get _localStorage => ref.read(localStorageProvider);

  @override
  bool isInitialized = false;

  // key: (typeId?), we use a record to indicate removal with (null,)
  final Map<String, (String?,)> _mappingBuffer = {};

  late Store _store;
  writeTxn(dynamic Function() fn) => _store.runInTransaction(TxMode.write, fn);

  late Box<StoredModel> _storedModelBox;
  late Box<Edge> _edgeBox;

  /// Initializes storage systems
  Future<GraphNotifier> initialize() async {
    if (isInitialized) return this;
    await _localStorage.initialize();

    try {
      _store = openStore(
        directory: path_helper.join(_localStorage.path, 'flutter_data'),
        queriesCaseSensitiveDefault: false,
      );
      _storedModelBox = _store.box<StoredModel>();
      _edgeBox = _store.box<Edge>();
    } catch (e, stackTrace) {
      print('[flutter_data] Objectbox failed to open:\n$e\n$stackTrace');
    }

    if (_localStorage.clear == LocalStorageClearStrategy.always) {
      // TODO no way of removing everything?
      _storedModelBox.removeAll();
      _edgeBox.removeAll();
    }

    isInitialized = true;
    return this;
  }

  @override
  void dispose() {
    if (isInitialized) {
      _store.close();
      isInitialized = false;
      super.dispose();
    }
  }

  // Key-related methods

  /// Finds a model's key.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [keyIfAbsent]
  ///    (if provided)
  ///  - It associates [keyIfAbsent] with the supplied [type]/[id]
  ///    (if both [keyIfAbsent] & [type]/[id] were provided)
  String? getKeyForId(String type, Object? id, {String? keyIfAbsent}) {
    type = DataHelpers.internalTypeFor(type);

    if (id != null) {
      var entry = _mappingBuffer.entries
          .firstWhereOrNull((e) => e.value.$1 == id.typifyWith(type));
      if (entry?.value != null) {
        if (entry!.value.$1 == null) {
          return null;
        }
        return entry.key;
      }

      // if it wasn't found fall back to DB (for reads)
      final keys = _storedModelBox
          .query(StoredModel_.typeId.equals(id.typifyWith(type)))
          .build()
          .property(StoredModel_.key)
          .find();
      if (keys.isNotEmpty) {
        return keys.first.typifyWith(type);
      }
      if (keyIfAbsent != null) {
        // Buffer write
        final typeId = id.typifyWith(type);
        _mappingBuffer[keyIfAbsent] = (typeId,);
        return keyIfAbsent;
      }
    } else if (keyIfAbsent != null) {
      return keyIfAbsent;
    }
    return null;
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    final mapping = _mappingBuffer[key];
    if (mapping != null) {
      if (mapping.$1 == null) {
        return null;
      }
      return mapping.$1!.detypify();
    }

    final typeIds = _storedModelBox
        .query(StoredModel_.key.equals(key.detypify() as int))
        .build()
        .property(StoredModel_.typeId)
        .find();

    if (typeIds.isNotEmpty) {
      return typeIds.first.detypify();
    }
    return null;
  }

  /// Adds type-ID mapping for [key]
  void setIdForKey(String key,
      {required String type, required Object id, bool notify = true}) {
    _mappingBuffer[key] = (id.typifyWith(type),);
  }

  /// Removes type-ID mapping for [key]
  void removeIdForKey(String key, {bool notify = true}) {
    _mappingBuffer[key] = (null,);
  }

  // utils

  /// Returns a [Map] representation of the internal ID db
  Map<String, String> toIdMap() {
    final models = _storedModelBox.getAll();
    return {
      for (final e in _mappingBuffer.entries)
        if (e.value.$1 != null) e.key: e.value.$1!,
      for (final m in models) m.key.typifyWith(m.type): m.typeId
    };
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

final graphNotifierProvider =
    Provider<GraphNotifier>((ref) => GraphNotifier(ref));
