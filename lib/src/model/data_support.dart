part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<T>> {
  dynamic get id;

  Repository<T> _repository;
  DataId<T> _dataId;
  // ignore: prefer_final_fields
  bool _save = true;

  DataManager get _manager => _repository?.manager;
}

extension DataSupportMixinExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  T init(Repository<T> repository, {String key, bool save = true}) {
    return repository?._init(_this, key: key, save: save);
  }

  T get _this => this as T;

  String get key => _dataId?.key;

  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    _assertRepo();
    return await _repository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    _assertRepo();
    await _repository.delete(id,
        remote: remote, params: params, headers: headers);
  }

  Future<T> find(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    _assertRepo();
    return _repository.findOne(id,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    _assertRepo();
    return _repository.watchOne(id,
        remote: remote, params: params, headers: headers);
  }

  bool get isNew => _this.id == null;

  void _assertRepo() {
    assert(
      _repository != null,
      '''\n
Tried to call a method on $this (of type $T), but it is not initialized.

This app has been configured with autoModelInit: false at boot,
which means that model initialization is managed by you.

If you wish Flutter Data to auto-initialize your models,
ensure you configure it at boot:

FlutterData.init(autoModelInit: true);

or simply

FlutterData.init();
''',
    );
  }
}

// auto

abstract class DataSupport<T extends DataSupport<T>> with DataSupportMixin<T> {
  DataSupport({bool save = true}) {
    _autoModelInitDataManager
        .locator<Repository<T>>()
        ?._init(_this, save: save);
  }
}

extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  @Deprecated('Do not call init() when this model extends DataSupport')
  // ignore: missing_return
  T init({String key, bool save = true}) {
    return _repository._init(_this, key: key, save: save);
  }
}

mixin IdDataSupportMixin<ID, T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  @override
  ID get id;
}

abstract class IdDataSupport<ID, T extends DataSupport<T>>
    extends DataSupport<T> {
  IdDataSupport({bool save = true}) : super(save: save);
  @override
  ID get id;
}
