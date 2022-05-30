part of flutter_data;

/// An adapter interface to access local storage.
///
/// Identity in this layer is enforced by keys.
///
/// See also: [IsarLocalAdapter]
abstract class LocalAdapter<T extends DataModel<T>> with _Lifecycle {
  @protected
  LocalAdapter(Reader? read) : _graph = read?.call(graphNotifierProvider);

  final GraphNotifier? _graph;

  @protected
  GraphNotifier get graph => _graph!;

  FutureOr<LocalAdapter<T>> initialize();

  // protected API

  /// Returns all models of type [T] in local storage.
  List<T>? findAll();

  /// Finds model of type [T] by [key] in local storage.
  T? findOne(int? key);

  /// Saves model of type [T] with its key in local storage.
  ///
  /// By default notifies this modification to the associated [GraphNotifier].
  @protected
  @visibleForTesting
  int save(T model, {bool notify = true});

  /// Deletes model of type [T] with [key] from local storage.
  ///
  /// By default notifies this modification to the associated [GraphNotifier].
  @protected
  @visibleForTesting
  Future<void> delete(int key);

  /// Deletes all models of type [T] in local storage.
  @protected
  @visibleForTesting
  Future<void> clear();

  // public abstract methods

  Map<String, dynamic> serialize(T model, {bool withRelationships = true});

  T deserialize(Map<String, dynamic> map);

  Map<String, FieldMeta> get fieldMetas;

  // helpers

  Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true}) {
    for (final e in fieldMetas.relationships.entries) {
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
    for (final e in fieldMetas.relationships.entries) {
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
