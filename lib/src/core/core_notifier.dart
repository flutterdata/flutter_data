// ignore_for_file: comment_references

part of flutter_data;

/// Used to notify events.
///
/// Watchers like [Adapter.watchAllNotifier] or [BelongsTo.watch]
/// make use of it.
///
/// Its public API requires all keys and metadata to be namespaced
/// i.e. `manager:key`
class CoreNotifier extends DelayedStateNotifier<DataGraphEvent> {
  final Ref ref;
  @protected
  CoreNotifier(this.ref);

  LocalStorage get storage => ref.read(localStorageProvider);

  // Key-related methods

  /// Finds a model's key.
  ///
  ///  - Attempts a lookup by [type]/[id]
  ///  - If the key was not found, it returns a default [orElse]
  ///    (if provided)
  String getKeyForId(String type, Object? id) {
    var result = storage.db.select(
        'SELECT key FROM _keys WHERE type = ? AND id = ?',
        [type, id?.toString()]);
    if (result.isEmpty) {
      result = storage.db.select(
          'INSERT INTO _keys (type, id, is_int) VALUES (?, ?, ?) RETURNING key;',
          [type, id?.toString(), id is int]);
    }
    return result.first['key'].toString().typifyWith(type);
  }

  /// Finds an ID, given a [key].
  Object? getIdForKey(String key) {
    final intKey = key.detypifyKey();
    if (intKey == null) {
      return null;
    }
    final result = storage.db
        .select('SELECT id, is_int FROM _keys WHERE key = ?', [intKey]);
    if (result.isEmpty) {
      return null;
    }
    final [id, isInt] = [result.first['id'], result.first['is_int'] == 1];
    if (isInt) {
      return int.parse(id);
    }
    return id;
  }

  void deleteKeys(Iterable<String> keys) {
    final intKeys = keys.map((k) => k.detypifyKey()).toList();
    storage.db.execute(
        'DELETE FROM _keys WHERE key IN (${keys.map((_) => '?').join(', ')})',
        intKeys);
  }

  @protected
  @visibleForTesting
  @nonVirtual
  String? getKeyForModelOrId(String type, Object model, {bool save = false}) {
    if (model is DataModelMixin) {
      return model._key ??
          (model.id == null ? null : getKeyForId(type, model.id));
    }
    return getKeyForId(type, model);
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

final _coreNotifierProvider =
    Provider<CoreNotifier>((ref) => CoreNotifier(ref));
