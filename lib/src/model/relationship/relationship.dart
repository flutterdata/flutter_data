part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>> {
  // ignore: prefer_final_fields
  DataManager _manager;

  Relationship(this._manager);

  Repository<E> get _repository => _manager.locator<Repository<E>>();

  DataId _owner;

  @visibleForTesting
  DataId get debugOwner => _owner;

  Future<List<E>> load([Map<String, dynamic> params]) {
    // TODO should be filtered by inverse id
    return _repository.findAll();
  }

  DataStateNotifier<List<E>> watch() {
    // TODO should be filtered by inverse id
    return _repository.watchAll();
  }

  dynamic toJson();
}
