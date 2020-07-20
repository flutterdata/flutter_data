part of flutter_data;

/// Thin wrapper on the [RemoteAdapter] API
class Repository<T extends DataSupport<T>> with _Lifecycle<Repository<T>> {
  @override
  @mustCallSuper
  FutureOr<Repository<T>> initialize(
      {bool remote,
      bool verbose,
      Map<String, RemoteAdapter> adapters,
      ProviderReference ref}) async {
    if (isInitialized) return this;
    for (final e in adapters.entries) {
      _adapters[e.key] = await e.value.initialize(
          remote: remote, verbose: verbose, adapters: adapters, ref: ref);
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
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return adapter.findAll(
        remote: remote, params: params, headers: headers, init: true);
  }

  Future<T> findOne(final dynamic model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return adapter.findOne(model,
        remote: remote, params: params, headers: headers, init: true);
  }

  Future<T> save(T model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return adapter.save(model,
        remote: remote, params: params, headers: headers, init: true);
  }

  Future<void> delete(dynamic model,
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return adapter.delete(model,
        remote: remote, params: params, headers: headers);
  }

  Future<void> clear() => adapter.clear();

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
