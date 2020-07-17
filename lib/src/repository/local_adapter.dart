part of flutter_data;

abstract class LocalAdapter<T extends DataSupport<T>>
    with _Lifecycle<LocalAdapter<T>> {
  @protected
  LocalAdapter(this.graph);

  @protected
  final DataGraphNotifier graph;

  @override
  @mustCallSuper
  FutureOr<LocalAdapter<T>> initialize() async {
    await super.initialize();
    await graph.initialize();
    return this;
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await super.dispose();
    await graph.dispose();
  }

  // protected API

  @protected
  @visibleForTesting
  List<T> findAll();

  @protected
  @visibleForTesting
  T findOne(String key);

  @protected
  @visibleForTesting
  void save(String key, T model, {bool notify = true});

  @protected
  @visibleForTesting
  void delete(String key);

  // public abstract methods

  Map<String, dynamic> serialize(T model);

  T deserialize(Map<String, dynamic> map);

  Map<String, Map<String, Object>> relationshipsFor([T model]);
}
