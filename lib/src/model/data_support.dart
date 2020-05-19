part of flutter_data;

abstract class DataSupportMixin<T extends DataSupportMixin<T>> {
  Object get id;
  final Map<String, dynamic> _flutterDataMetadata = {};
}

// ignore_for_file: unused_element
extension DataSupportMixinExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  T init(Repository<T> repository, {String key, bool save = true}) {
    return repository?.initModel(_this, key: key, save: save);
  }

  // temp get/set while we figure out the new Metadata class
  Map<String, dynamic> get flutterDataMetadata => _flutterDataMetadata;

  Repository<T> get _repository =>
      flutterDataMetadata['_repository'] as Repository<T>;
  set _repository(Repository<T> value) =>
      flutterDataMetadata['_repository'] ??= value;

  String get key => flutterDataMetadata['_key'] as String;
  set key(String value) => flutterDataMetadata['_key'] ??= value;

  bool get _save => flutterDataMetadata['_save'] as bool;
  set _save(bool value) => flutterDataMetadata['_save'] = value;

  //

  DataManager get _manager => _repository?.manager;

  T get _this => this as T;

  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertRepo();
    return await _repository.save(_this,
        remote: remote, params: params, headers: headers);
  }

  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertRepo();
    await _repository.delete(id,
        remote: remote, params: params, headers: headers);
  }

  Future<T> find(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    _assertRepo();
    return _repository.findOne(id,
        remote: remote, params: params, headers: headers);
  }

  DataStateNotifier<T> watch(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
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
        ?.initModel(_this, save: save);
  }
}
