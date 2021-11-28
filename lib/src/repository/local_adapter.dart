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
  List<T> findAll();

  /// Finds model of type [T] by [key] in local storage.
  T? findOne(String key);

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

  Map<String, dynamic> serialize(T model);

  T deserialize(Map<String, dynamic> map);

  Map<String, Map<String, Object?>> relationshipsFor([T model]);
}
