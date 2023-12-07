part of flutter_data;

/// An adapter interface to access local storage.
///
/// Identity in this layer is enforced by keys.
///
/// See also: [ObjectboxLocalAdapter]
abstract class LocalAdapter<T extends DataModelMixin<T>> with _Lifecycle {
  @protected
  LocalAdapter(Ref ref) : core = ref.read(coreNotifierProvider);

  @protected
  @visibleForTesting
  final CoreNotifier core;

  String get internalType => DataHelpers.getInternalType<T>();

  // protected API

  /// Returns all models of type [T] in local storage.
  List<T> findAll();

  /// Finds model of type [T] by [key] in local storage.
  T? findOne(String? key);

  /// Finds model of type [T] by [id] in local storage.
  T? findOneById(Object? id);

  /// Finds many models of type [T] by [keys] in local storage.
  List<T> findMany(Iterable<String> keys);

  /// Whether [key] exists in local storage.
  bool exists(String key);

  /// Saves model of type [T] with [key] in local storage.
  ///
  /// By default notifies this modification to the associated [CoreNotifier].
  @protected
  @visibleForTesting
  T save(String key, T model, {bool notify = true});

  /// Deletes model of type [T] with [key] from local storage.
  ///
  /// By default notifies this modification to the associated [CoreNotifier].
  @protected
  @visibleForTesting
  void delete(String key, {bool notify = true});

  void deleteKeys(Iterable<String> keys, {bool notify = true});

  /// Deletes all models of type [T] in local storage.
  @protected
  @visibleForTesting
  Future<void> clear();

  /// Counts all models of type [T] in local storage.
  int get count;

  /// Gets all keys of type [T] in local storage.
  List<String> get keys;

  Future<void> saveMany(Iterable<DataModelMixin> models, {bool notify = true});

  // model initialization

  @protected
  @nonVirtual
  T initModel(T model, {Function(T)? onModelInitialized}) {
    if (model._key == null) {
      model._key = core.getKeyForId(internalType, model.id,
          keyIfAbsent: DataHelpers.generateKey<T>())!;
      _initializeRelationships(model);
      onModelInitialized?.call(model);
    }
    return model;
  }

  void _initializeRelationships(T model, {String? fromKey}) {
    final metadatas = relationshipMetas.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(model);
      relationship?.initialize(
        ownerKey: fromKey ?? model._key!,
        name: metadata.name,
        inverseName: metadata.inverseName,
      );
    }
  }

  // public abstract methods

  Map<String, dynamic> serialize(T model, {bool withRelationships = true});

  T deserialize(Map<String, dynamic> map);

  Map<String, RelationshipMeta> get relationshipMetas;

  // helpers

  Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true}) {
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      if (withRelationships) {
        final ignored = e.value.serialize == false;
        if (ignored) map.remove(key);

        if (map[key] is HasMany) {
          map[key] = (map[key] as HasMany).keys;
        } else if (map[key] is BelongsTo) {
          map[key] = map[key].key;
        }

        if (map[key] == null) map.remove(key);
      } else {
        map.remove(key);
      }
    }
    return map;
  }

  Map<String, dynamic> transformDeserialize(Map<String, dynamic> map) {
    // ensure value is dynamic (argument might come in as Map<String, String>)
    map = Map<String, dynamic>.from(map);
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      final keyset = map[key] is Iterable
          ? {...(map[key] as Iterable)}
          : {if (map[key] != null) map[key].toString()};
      final ignored = e.value.serialize == false;
      map[key] = {
        '_': (map.containsKey(key) && !ignored) ? keyset : null,
      };
    }
    return map;
  }
}
