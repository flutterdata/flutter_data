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
    _assertLocator();
    _init(_autoModelInitDataManager.locator<Repository<T>>());
    _assertAuto();
    return _initRepository;
  }

  set _repository(Repository<T> repository) {
    _initRepository = repository;
  }

  T _init(Repository<T> repository) {
    _repository = repository;
    _manager = repository.manager;
    _repository.setOwnerInRelationships(_manager.dataId<T>(id), _this);
    _this.save(remote: false);
    return _this;
  }

  // asserts

  _assertRepo(String method) {
    assert(
      _repository != null,
      '''\n
Tried to call $method but this instance of $T is not initialized.

Please use: `$T(...).init(repository)`

or, instead of extending `DataSupportInit`, make your $T model mix
in `DataSupport` which doesn't require initialization.
''',
    );
  }

  _assertLocator() {
    assert(
      _manager?.locator != null,
      '''\n
Manager hasn't been initialized.

Please ensure you are calling DataManager().init().
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

  Future<T> save({bool remote = true}) async {
    _assertRepo('save()');
    return await _repository.save(_this, remote: remote);
  }

  Future<void> delete({bool remote = true}) async {
    _assertRepo('delete()');
    await _repository.delete(id, remote: remote);
  }

  Future<T> load([Map<String, String> params]) {
    _assertRepo('load()');
    return _repository.findOne(id, params: params);
  }

  DataStateNotifier<T> watch([Map<String, String> params]) {
    _assertRepo('watch()');
    return _repository.watchOne(id, params: params);
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
