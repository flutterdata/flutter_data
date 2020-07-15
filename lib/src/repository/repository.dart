part of flutter_data;

class Repository<T extends DataSupport<T>> with _Lifecycle<Repository<T>> {
  @override
  @mustCallSuper
  FutureOr<Repository<T>> initialize(
      {bool remote, bool verbose, Map<String, RemoteAdapter> adapters}) async {
    if (isInitialized) return this;
    if (!isInitialized) {
      for (final e in adapters.entries) {
        _adapters[e.key] = await e.value
            .initialize(remote: remote, verbose: verbose, adapters: adapters);
      }
    }
    await super.initialize();
    return this;
  }

  @override
  @mustCallSuper
  Future<void> dispose() async {
    await super.dispose();
    await adapter?.dispose();
  }

  // adapters

  @protected
  RemoteAdapter<T> get adapter =>
      _adapters[DataHelpers.getType<T>()] as RemoteAdapter<T>;

  final _adapters = <String, RemoteAdapter>{};

  // repo public API

  Future<List<T>> findAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return (await adapter.findAll(
            remote: remote, params: params, headers: headers))
        ._initModels(_adapters, save: true);
  }

  Future<T> findOne(final dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    final result = await adapter.findOne(model,
        remote: remote, params: params, headers: headers);
    return result?._initModel(_adapters, save: true);
  }

  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    assert(model != null);
    model._initModel(_adapters);

    final result = await adapter.save(model,
        remote: remote, params: params, headers: headers);
    result._initModel(_adapters, key: model._key);

    // in the unlikely case where supplied key couldn't be used
    // ensure "old" copy of model carries the updated key
    if (model._key != null && model._key != result._key) {
      adapter._graph.removeKey(model._key);
      model._key = result._key;
    }
    return result;
  }

  Future<void> delete(dynamic model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    assert(model != null);
    if (model is T) {
      model._initModel(_adapters);
    }
    return adapter.delete(model,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watchOne(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    return adapter.watchOne(model,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }

  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return adapter.watchAll(remote: remote, params: params, headers: headers);
  }
}

// annotation

class DataRepository {
  final List<Type> adapters;
  final List<Type> repositoryFor;
  const DataRepository(this.adapters, {this.repositoryFor = const []});
}
