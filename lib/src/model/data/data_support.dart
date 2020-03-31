part of flutter_data;

abstract class DataSupport<T extends DataSupport<T>> {
  String get id;
  DataManager _manager;
}

extension DataSupportExtension<T extends DataSupport<T>> on DataSupport<T> {
  Repository<T> get _repository => _manager.locator<Repository<T>>();
  T get _this => this as T;

  DataId get dataId {
    _assertOk('dataId');
    return DataId<T>(id, _manager);
  }

  String get key => dataId.key;

  T createFrom(Repository<T> repository) {
    return repository.create(_this);
  }

  Future<T> save({bool remote = true}) async {
    _assertOk('save()');
    return await _repository.save(_this, remote: remote);
  }

  Future<void> delete({bool remote = true}) async {
    _assertOk('delete()');
    await _repository.delete(id, remote: remote);
  }

  Future<T> load([Map<String, String> params]) {
    _assertOk('load()');
    return _repository.findOne(id, params: params);
  }

  DataStateNotifier<T> watch([Map<String, String> params]) {
    _assertOk('watch()');
    return _repository.watchOne(id, params: params);
  }

  bool get isNew {
    _assertOk('isNew');
    return _repository.localAdapter.isNew(_this);
  }

  _assertOk(String method) {
    assert(
      _manager != null,
      '''\n
Tried to call $method but this instance of $T is not
initialized in Flutter Data.

Please use either
 - `repository.create($T(...))`, or
 - `$T(...).createFrom(repository)`

for your models to work with Flutter Data.
''',
    );
  }
}
