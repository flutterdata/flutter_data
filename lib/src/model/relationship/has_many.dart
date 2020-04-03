part of flutter_data;

class HasMany<E extends DataSupport<E>> extends Relationship<E>
    with ListMixin<E> {
  @protected
  @visibleForTesting
  final List<DataId<E>> dataIds;

  HasMany._(this.dataIds,
      [DataManager manager, List<ResourceObject> included]) {
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

  factory HasMany.fromToMany(dynamic rel, DataManager manager,
      {List<ResourceObject> included}) {
    // if rel has no data, it is always of type ToOne ({data: null})
    if (rel == null || (rel is ToOne && rel.unwrap() == null)) {
      return HasMany<E>._(const [], manager);
    }
    return HasMany._(
      (rel as ToMany).linkage.map((i) => manager.dataId<E>(i.id)).toList(),
      manager,
      included,
    );
  }

  factory HasMany.fromKeys(dynamic keys, DataManager manager) =>
      HasMany._(_keysToDataIds<E>(keys, manager), manager);

  static List<DataId<E>> _keysToDataIds<E extends DataSupport<E>>(
      keys, DataManager manager) {
    if (keys == null) return [];
    var _keys = List<String>.from(keys as Iterable);
    return DataId.byKeys(_keys, manager);
  }

  factory HasMany.fromJson(Map<String, dynamic> map) {
    return map['HasMany'] as HasMany<E>;
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

  ToMany get toMany => ToMany(dataIds.map((d) => d.identifierObject));

  @override
  Map<String, dynamic> toJson() => toMany.toJson();

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataIds == other.dataIds;

  @override
  int get hashCode => runtimeType.hashCode ^ dataIds.hashCode;
}
