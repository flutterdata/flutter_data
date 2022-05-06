part of flutter_data;

/// An adapter interface to access local storage
///
/// See also: [HiveLocalAdapter]
abstract class LocalAdapter<T extends DataModel<T>> with _Lifecycle {
  @protected
  LocalAdapter(Reader read) : graph = read(graphNotifierProvider);

  @protected
  final GraphNotifier graph;

  FutureOr<LocalAdapter<T>> initialize();

  // protected API

  /// Returns all models of type [T] in local storage.
  List<T>? findAll();

  /// Finds model of type [T] by [key] in local storage.
  T? findOne(String? key);

  /// Saves model of type [T] with [key] in local storage.
  ///
  /// By default notifies this modification to the associated [GraphNotifier].
  @protected
  @visibleForTesting
  Future<T> save(String key, T model, {bool notify = true});

  /// Deletes model of type [T] with [key] from local storage.
  ///
  /// By default notifies this modification to the associated [GraphNotifier].
  @protected
  @visibleForTesting
  Future<void> delete(String key);

  /// Deletes all models of type [T] in local storage.
  @protected
  @visibleForTesting
  Future<void> clear();

  // public abstract methods

  Map<String, dynamic> serialize(T model, {bool withRelationships = true});

  T deserialize(Map<String, dynamic> map);

  Map<String, Map<String, Object?>> relationshipsFor([T model]);

  // helpers

  Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true}) {
    for (final e in relationshipsFor().entries) {
      final key = e.key;
      if (withRelationships) {
        if (map[key] is HasMany) {
          map[key] = (map[key] as HasMany).ids.toList();
        } else if (map[key] is BelongsTo) {
          map[key] = map[key].id;
        }
        final ignored = e.value['serialize'] == 'false';
        if (map[key] == null || ignored) map.remove(key);
      } else {
        map.remove(key);
      }
    }
    return map;
  }

  Map<String, dynamic> transformDeserialize(Map<String, dynamic> map) {
    map = Map<String, dynamic>.from(map);
    for (final e in relationshipsFor().entries) {
      final key = e.key;
      final keyset = map[key] is Iterable
          ? {...(map[key] as Iterable)}
          : {if (map[key] != null) map[key].toString()};
      final ignored = e.value['serialize'] == 'false';
      map[key] = {
        '_': (map.containsKey(key) && !ignored) ? keyset : null,
      };
    }
    return map;
  }

  // private

  // ignore: unused_element
  bool get _isLocalStorageTouched;

  void _touchLocalStorage();
}
