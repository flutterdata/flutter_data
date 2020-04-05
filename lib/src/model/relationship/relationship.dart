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
  void _saveIncluded(
      List<Map<String, dynamic>> included, List<DataId> _dataIds) {
    if (included != null) {
      for (var i in included) {
        if (_dataIds.contains(_manager.dataId<E>(i.id))) {
          _repository.deserialize(i)._init(_repository);
        }
      }
    }
  }
}
