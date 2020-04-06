part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<T>> {
  String get id;
  DataManager _manager;

  T get _this => this as T;

  Repository<T> _repository;

  T _init(Repository<T> repository, {String key}) {
    assert(repository != null, 'Please provide an instance of Repository<$T>');
    _repository = repository;
    _manager = repository.manager;

    _assertAuto();
    var dataId = _manager.dataId<T>(id, key: key);
    // sync relationships
    _repository.setOwnerInRelationships(dataId, _this);
    _repository.localAdapter.save(dataId.key, _this);
    return _this;
  }

  // asserts

  _assertRepo(String method) {
    assert(
      _repository != null,
      '''\n
Tried to call $method but this instance of $T is not initialized.

Please use: `$T(...).init(repository)`

or, instead of extending `DataSupportMixinInit`, make your $T model mix
in `DataSupportMixin` which doesn't require initialization.
''',
    );
  }

  _assertAuto() {
    final modelAutoInit = this is DataSupport;
    if (modelAutoInit) {
      assert(_manager.autoModelInit, '''\n
This $T model mixes in DataSupportMixin but you initialized
Flutter Data with autoModelInit: false.

If you wish to manually initialize your models, please make
sure $T extends DataSupportMixinInit.

If you wish Flutter Data to auto-initialize, call:

FlutterData.init(autoModelInit: true);

or simply

FlutterData.init();
''');
    } else {
      assert(!_manager.autoModelInit, '''\n
This $T model extends DataSupportMixinInit but you initialized
Flutter Data with autoModelInit: true (the default).

If you wish to automatically initialize your models, please make
sure $T mixes in DataSupportMixin.

If you wish to manually initialize your models, call:

FlutterData.init(autoModelInit: false);
''');
    }
  }
}

extension DataSupportExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  T init(Repository<T> repository, {String key}) {
    return _init(repository, key: key);
  }

  DataId<T> get dataId {
    _assertRepo('get dataId');
    return _manager.dataId<T>(id);
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

// auto

abstract class DataSupport<T extends DataSupport<T>> with DataSupportMixin<T> {
  DataSupport() {
    _init(_autoModelInitDataManager?.locator<Repository<T>>());
  }
}
