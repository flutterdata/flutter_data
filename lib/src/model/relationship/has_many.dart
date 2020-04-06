part of flutter_data;

class HasMany<E extends DataSupportMixin<E>> extends Relationship<E>
    with ListMixin<E> {
  @protected
  @visibleForTesting
  final List<DataId<E>> dataIds;

  HasMany._(this.dataIds, [DataManager manager]) {
    super._manager = manager;
  }

  HasMany([List<E> list = const [], DataManager manager])
      : this._(
            list
                .map((model) => manager.dataId<E>(model.id, model: model))
                .toList(),
            manager);

  // serialization constructors

  factory HasMany.fromJson(Map<String, dynamic> map) {
    final keys = List<String>.from(map['_'][0] as Iterable);
    final manager = map['_'][1] as DataManager;
    return HasMany._(
        keys != null ? DataId.byKeys(keys, manager) : const [], manager);
  }

  // end constructors

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    for (int i = 0; i < length; i++) {
      if (dataIds[i] != null) {
        dataIds[i].model?._init(_repository);
        // trigger re-run DataId
        dataIds[i] = _manager.dataId<E>(dataIds[i].id);
      }
    }
  }

  // array methods

  @override
  E operator [](int index) =>
      _repository.localAdapter.findOne(dataIds[index].key);

  @override
  operator []=(int index, E value) {
    dataIds[index] = _manager.dataId<E>(value.id);
    _repository.setOwnerInModel(_owner, value);
  }

  @override
  int get length => dataIds.length;

  @override
  set length(int newLength) => dataIds.length = newLength;

  // misc

  List<String> get keys => dataIds.map((d) => d.key).toList();

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataIds == other.dataIds;

  @override
  int get hashCode => runtimeType.hashCode ^ dataIds.hashCode;
}
