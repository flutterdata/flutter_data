part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<dynamic>> {
  String get id;
  DataManager _manager;

  T get _this => this as T;

  Repository<T> _repository;

  T _init(Repository<T> repository, {bool save = true, String key}) {
    assert(repository != null, 'Please provide an instance of Repository<$T>');
    _repository = repository;
    _manager = repository.manager;

    final dataId = _manager.dataId<T>(id, key: key);
    // sync relationships
    _repository.setOwnerInRelationships(dataId, _this);
    if (save) {
      _repository.localAdapter.save(dataId.key, _this);
    }
    return _this;
  }

  // asserts

  _assertRepo(String method) {
    assert(
      _repository != null,
      '''\n
Tried to call $method but this instance of $T is not initialized.

Please use:

 - `$T(...).init()`
 - `$T(...).init(repository)` (if booted with autoModelInit: false)

or otherwise make $T extend `DataSupport` which doesn't require
explicit initialization.
''',
    );
  }

  _assertCorrectRepo(Repository<T> repository) {
    final modelAutoInit = _autoModelInitDataManager != null;
    if (modelAutoInit) {
      assert(
          repository == null || repository.manager == _autoModelInitDataManager,
          '''\n
This app has been configured with autoModelInit: true at boot,
which means that model initialization is managed internally.

You supplied an instance of Repository whose manager is NOT the
internal manager.

Either:
 - supply NO repository at all (RECOMMENDED)
 - supply an internally managed repository

If you wish to manually initialize your models, please make
sure $T (and ALL your other models) mix in DataSupportMixin
and you configure Flutter Data to do so, via:

FlutterData.init(autoModelInit: false);
''');
    } else {
      assert(repository != null, '''\n
This app has been configured with autoModelInit: false at boot,
which means that model initialization is managed by you.

You called init() but supplied no repository.

If you wish Flutter Data to auto-initialize your models,
ensure you configure it at boot:

FlutterData.init(autoModelInit: true);

or simply

FlutterData.init();
''');
    }
  }
}

extension DataSupportExtension<T extends DataSupportMixin<dynamic>>
    on DataSupportMixin<T> {
  T init([Repository<T> repository, bool save = true]) {
    _assertCorrectRepo(repository);
    repository ??= _autoModelInitDataManager?.locator<Repository<T>>();
    return _init(repository, save: save);
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

abstract class DataSupport<T extends DataSupport<dynamic>>
    with DataSupportMixin<T> {
  DataSupport() {
    init();
  }
}
