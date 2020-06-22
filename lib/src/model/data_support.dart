part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<T>> {
  Object get id;
  Repository<T> _repository;
  String _key;
}

String keyFor<T extends DataSupportMixin<T>>(T model) => model?._key;

// ignore_for_file: unused_element
extension DataSupportMixinExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  /// Only pass in a manager if you know what you're doing.
  T init([DataManager manager]) {
    manager ??= _autoManager;
    assert(manager != null);
    return manager.locator<Repository<T>>()._initModel(_this, save: true);
  }

  bool get _isInitialized => _key != null;

  //

  DataManager get _manager => _repository?.manager;

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
    _assertRepository();
    return await _repository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertRepository();
    await _repository.delete(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<T> reload(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    _assertRepository();
    return _repository.findOne(_this,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    _assertRepository();
    return _repository.watchOne(_this,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }

  bool get isNew => _this.id == null;

  void _assertRepository() {
    assert(
      _repository != null,
      '''\n
Tried to call a method on $this (of type $T), but it is not initialized.

This app has been configured with autoManager: false at boot,
which means that you must initialize your models with your own manager:

model.init(manager);

Or start Flutter Data with autoManager: true which allows you to do:

model.init();
''',
    );
  }
}

// auto

// TODO remove and name the mixin DataSupport

abstract class DataSupport<T extends DataSupport<T>> with DataSupportMixin<T> {}
