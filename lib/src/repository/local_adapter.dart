part of flutter_data;

/// An adapter interface to access local storage
///
/// See also: [HiveLocalAdapter]
abstract class LocalAdapter<T extends DataModel<T>>
    with _Lifecycle<LocalAdapter<T>> {
  @protected
  LocalAdapter(this.graph);

  @protected
  final GraphNotifier graph;

  @override
  @mustCallSuper
  FutureOr<LocalAdapter<T>> initialize() async {
    await super.initialize();
    await graph.initialize();
    return this;
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    graph.dispose();
  }

  // protected API

  /// Returns all models of type [T] in local storage.
  @protected
  @visibleForTesting
  List<T> findAll();

  /// Finds model of type [T] by [key] in local storage.
  @protected
  @visibleForTesting
  T findOne(String key);

  /// Saves model of type [T] with [key] in local storage.
  ///
  /// By default notifies this modification to the associated [GraphNotifier].
  @protected
  @visibleForTesting
  Future<void> save(String key, T model, {bool notify = true});

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

  /// Deletes all models of all types in local storage.
  @protected
  @visibleForTesting
  Future<void> clearAll();

  // public abstract methods

  Map<String, dynamic> serialize(T model);

  T deserialize(Map<String, dynamic> map);

  Map<String, Map<String, Object>> relationshipsFor([T model]);
}
