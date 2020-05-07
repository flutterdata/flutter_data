part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  Relationship(this.manager);

  Repository<E> get _repository => manager?.locator<Repository<E>>();

  DataId _owner;

  DataStateNotifier watch();

  @visibleForTesting
  DataId get debugOwner => _owner;

  dynamic toJson();
}
