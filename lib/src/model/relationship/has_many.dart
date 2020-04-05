part of flutter_data;

class HasMany<E extends DataSupport<E>> extends Relationship<E>
    with ListMixin<E> {
  @protected
  @visibleForTesting
  final List<DataId<E>> dataIds;

  HasMany._(this.dataIds,
      [DataManager manager, List<Map<String, dynamic>> included]) {
    super._manager = manager;
    _saveIncluded(included, dataIds);
  }

  HasMany([List<E> list = const [], DataManager manager])
      : this._(
            list
                .map((model) => manager.dataId<E>(model.id, model: model))
                .toList(),
            manager);

  // serialization constructors

  factory HasMany.fromKeys(List<String> keys, DataManager manager,
          {List<Map<String, dynamic>> included}) =>
      HasMany._(keys != null ? DataId.byKeys(keys, manager) : const [], manager,
          included);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    return HasMany.fromKeys(List<String>.from(map['HasMany'][0] as Iterable),
        map['HasMany'][1] as DataManager);
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
  E operator [](int index) => _box.get(dataIds[index].key);

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
  Map<String, dynamic> toJson() => {}; // toMany.toJson();

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataIds == other.dataIds;

  @override
  int get hashCode => runtimeType.hashCode ^ dataIds.hashCode;
}
