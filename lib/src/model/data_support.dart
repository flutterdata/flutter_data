part of flutter_data;

abstract class DataSupport<T extends DataSupport<T>> {
  Object get id;

  // "late" finals
  String _key;
  Map<String, RemoteAdapter> _adapters;

  // computed
  RemoteAdapter<T> get _adapter =>
      _adapters[DataHelpers.getType<T>()] as RemoteAdapter<T>;
  bool get _isInitialized => _key != null && _adapters != null;

  // initializers

  @protected
  T debugInit(dynamic repository) {
    assert(repository is Repository<T>);
    return _initialize((repository as Repository<T>)._adapters, save: true);
  }

  T _initialize(final Map<String, RemoteAdapter> adapters,
      {final String key, final bool save = false}) {
    if (_isInitialized) return _this;

    _this._adapters = adapters;

    // model.id could be null, that's okay
    _this._key = _adapter._graph.getKeyForId(_this._adapter.type, _this.id,
        keyIfAbsent: key ?? DataHelpers.generateKey<T>());

    // initialize relationships
    for (final metadata
        in _adapter._localAdapter.relationshipsFor(_this).entries) {
      final relationship = metadata.value['instance'] as Relationship;

      relationship?.initialize(
        adapters: adapters,
        owner: _this,
        name: metadata.key,
        inverseName: metadata.value['inverse'] as String,
      );
    }

    if (save) {
      _adapter._localAdapter.save(_this._key, _this);
    }

    return _this;
  }
}

// ignore_for_file: unused_element
extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  T get _this => this as T;

  T was(T model) {
    assert(model != null && model._isInitialized,
        'Please initialize model before passing it to `was`');
    // initialize this model with existing model's repo & key
    return _this._initialize(model._adapters, key: model._key, save: true);
  }

  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return await _adapter.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    await _adapter.delete(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<T> reload(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return await _adapter.findOne(_this,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    return _adapter.watchOne(_this,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }
}

extension IterableDataSupportX<T extends DataSupport<T>> on Iterable<T> {
  List<T> _initModels(Map<String, RemoteAdapter> adapters,
      {String key, bool save = false}) {
    if (length == 1) {
      // key argument only makes sense when dealing with one model
      return [first._initialize(adapters, key: key, save: save)]
          .toImmutableList();
    }
    return map((m) => m._initialize(adapters, save: save)).toImmutableList();
  }
}

@visibleForTesting
String keyFor<T extends DataSupport<T>>(T model) => model?._key;
