// ignore_for_file: comment_references

part of flutter_data;

/// Used to notify events.
///
/// Watchers like [Repository.watchAllNotifier] or [BelongsTo.watch]
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
      // TODO rethink this when doing multi-box (it's pulling in `data` right now)
      final model = (storage as ObjectboxLocalStorage)
          .store
          .box<StoredModel>()
          .get(internalKey);
      if (model?.id == null) {
        return null;
      }
      if (model!.isInt) {
        return int.parse(model.id!);
      }
      return model.id;
    });
  }

  @protected
  @visibleForTesting
  @nonVirtual
  String keyForModelOrId(String type, Object model, {bool save = false}) {
    final id = model is DataModelMixin ? model.id : model;
    final key =
        model is DataModelMixin ? model._key! : getKeyForId(type, model);
    if (id != null) {
      final box = (storage as ObjectboxLocalStorage).store.box<StoredModel>();
      final intKey = key.detypifyKey()!;
      final model = box.get(intKey);

      box.put(
        StoredModel(
            internalKey: intKey,
            type: type,
            data: model?.data,
            id: id.toString(),
            isInt: id is int),
      );
    }
    return key;
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
