part of flutter_data;

abstract class Relationship<E extends DataSupport<E>> {
  DataManager _manager;

  Repository<E> get _repository => _manager.locator<Repository<E>>();
  Box<E> get _box => _repository.localAdapter.box;

  DataId _owner;

  @visibleForTesting
  DataId get debugOwner => _owner;

  Future<List<E>> load([Map<String, String> params]) {
    // TODO should be filtered by inverse id
    return _repository.findAll();
  }

  DataStateNotifier<List<E>> watch() {
    // TODO should be filtered by inverse id
    return _repository.watchAll();
  }

  Map<String, dynamic> toJson();

  // utils

  // of all the included, only saves those linked in this relationship
  List<E> _saveIncluded(List<ResourceObject> included, List<DataId> _dataIds) {
    return (included ?? const []).where((i) {
      return _dataIds.contains(DataId(i.id, _manager, type: i.type));
    }).map((i) {
      return _repository.internalDeserialize(i)._init(_repository);
    }).toList();
  }
}
