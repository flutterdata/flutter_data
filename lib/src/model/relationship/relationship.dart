part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>> {
  // ignore: prefer_final_fields
  DataManager _manager;

  Relationship(this._manager);

  Repository<E> get _repository => _manager.locator<Repository<E>>();

  DataId _owner;

  DataStateNotifier watch();

  @visibleForTesting
  DataId get debugOwner => _owner;

  dynamic toJson();
}
