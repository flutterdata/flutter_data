part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<T>> {
  String get id;
  DataManager _manager;
  DataId<T> _dataId;
  bool _saveLocal = true;

  T get _this => this as T;

  Repository<T> _repository;

  T _init(Repository<T> repository, {bool saveLocal = true}) {
    _assertCorrectRepo(repository);
    _repository =
        repository ?? _autoModelInitDataManager?.locator<Repository<T>>();
    _manager = _repository.manager;

    final originalKey = this.key;
    this._dataId = _manager.dataId<T>(id, key: originalKey);

    // if the existing key is different to the resulting key
    // the original key for this ID has been found-
    // therefore we need to delete the stray record
    if (originalKey != null && originalKey != this.key) {
      _repository.localAdapter.delete(originalKey);
    }

    _repository.setOwnerInRelationships(_dataId, _this);

    _saveLocal = saveLocal;
    if (saveLocal) {
      _repository.localAdapter.save(_dataId.key, _this);
    }
    return _this;
  }

  // asserts

  _assertRepo() {
    assert(
      _repository != null,
      '''\n
Tried to call a method on $this (of type $T), but it is not initialized.

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

extension DataSupportMixinExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  T init(Repository<T> repository, {bool saveLocal = true}) {
    return _init(repository, saveLocal: saveLocal);
  }

  DataId<T> get dataId => _dataId;
  String get key => _dataId?.key;

  Future<T> save(
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    _assertRepo();
    return await _repository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  void saveLocal() {
    _assertRepo();
    _repository.localAdapter.save(key, _this);
    return;
  }

  Future<void> delete(
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    _assertRepo();
    await _repository.delete(id,
        remote: remote, params: params, headers: headers);
  }

  Future<T> load(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    _assertRepo();
    return _repository.findOne(id,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    _assertRepo();
    return _repository.watchOne(id,
        remote: remote, params: params, headers: headers);
  }

  bool get isNew {
    _assertRepo();
    return _repository.localAdapter.isNew(_this);
  }
}

// auto

abstract class DataSupport<T extends DataSupport<T>> with DataSupportMixin<T> {
  DataSupport({bool saveLocal = true}) {
    _init(null, saveLocal: saveLocal);
  }
}

extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  @Deprecated('Do not call init() when this model extends DataSupport')
  // ignore: missing_return
  T init() {}
}
