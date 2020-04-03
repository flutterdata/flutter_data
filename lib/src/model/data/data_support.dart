part of flutter_data;

abstract class DataSupport<T extends DataSupport<T>> {
  String get id;
  DataManager _manager;

  T get _this => this as T;

  Repository<T> _initRepository;
  Repository<T> get _repository {
    if (_initRepository != null) {
      _assertAuto();
      return _initRepository;
    }
    _init(_autoModelInitDataManager.locator<Repository<T>>());
    _assertAuto();
    return _initRepository;
  }

  T _init(Repository<T> repository) {
    _initRepository ??= repository;
    _manager ??= repository.manager;
    _repository.setOwnerInRelationships(_manager.dataId<T>(id), _this);
    _repository.localAdapter.save(_this.key, _this);
    return _this;
  }

  // asserts

  _assertRepo(String method) {
    assert(
      _manager != null && _repository != null,
      '''\n
Tried to call $method but this instance of $T is not initialized.

Please use: `$T(...).init(repository)`

or, instead of extending `DataSupportInit`, make your $T model mix
in `DataSupport` which doesn't require initialization.
''',
    );
  }

  _assertAuto() {
    final modelAutoInit = this is! DataSupportInit;
    if (modelAutoInit) {
      assert(_manager.autoModelInit, '''\n
This $T model mixes in DataSupport but you initialized
Flutter Data with autoModelInit: false.

If you wish to manually initialize your models, please make
sure $T extends DataSupportInit.

If you wish Flutter Data to auto-initialize, call:

FlutterData.init(autoModelInit: true);

or simply

FlutterData.init();
''');
    } else {
      assert(!_manager.autoModelInit, '''\n
This $T model extends DataSupportInit but you initialized
Flutter Data with autoModelInit: true (the default).

If you wish to automatically initialize your models, please make
sure $T mixes in DataSupport.

If you wish to manually initialize your models, call:

FlutterData.init(autoModelInit: false);
''');
    }
  }
}

extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  DataId get dataId {
    _assertRepo('get dataId');
    return _manager.dataId<T>(id, model: _this);
  }

  String get key {
    _assertRepo('get key');
    return dataId?.key;
  }

  Future<T> save(
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    _assertRepo('save()');
    return await _repository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    _assertRepo('delete()');
    await _repository.delete(id,
        remote: remote, params: params, headers: headers);
  }

  Future<T> load(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    _assertRepo('load()');
    return _repository.findOne(id,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    _assertRepo('watch()');
    return _repository.watchOne(id,
        remote: remote, params: params, headers: headers);
  }

  bool get isNew {
    _assertRepo('isNew');
    return _repository.localAdapter.isNew(_this);
  }
}

// unmanaged

abstract class DataSupportInit<T extends DataSupport<T>>
    extends DataSupport<T> {}

extension DataSupportInitExtension<T extends DataSupport<T>>
    on DataSupportInit<T> {
  T init(Repository<T> repository) {
    return _init(repository);
  }
}
