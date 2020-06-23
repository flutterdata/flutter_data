part of flutter_data;

abstract class DataSupport<T extends DataSupport<T>> {
  Object get id;
  Repository<T> _repository;
  String _key;
}

String keyFor<T extends DataSupport<T>>(T model) => model?._key;

// ignore_for_file: unused_element
extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  /// Only pass in a `DataManager` if you initialized
  /// Flutter Data with `autoManager: false`
  T init([DataManager manager]) {
    manager ??= _autoManager;
    assert(manager != null);
    return manager.locator<Repository<T>>()._initModel(_this, save: true);
  }

  bool get _isInitialized => _key != null;

  DataManager get _manager => _repository?.manager;

  Repository<T> get _fallbackRepository =>
      _repository ?? _autoManager?.locator<Repository<T>>();

  T get _this => this as T;

  T was(T model) {
    assert(model._isInitialized,
        'Please call `model.init` before passing it to `was`');
    // initialize this model with existing model's repo & key
    return model._repository?._initModel(_this, key: model._key, save: true);
  }

  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return await _fallbackRepository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    await _fallbackRepository.delete(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<T> reload(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    return _fallbackRepository.findOne(_this,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    return _fallbackRepository.watchOne(_this,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }

  bool get isNew => _this.id == null;
}
