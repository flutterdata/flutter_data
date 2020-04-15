part of flutter_data;

class HasMany<E extends DataSupportMixin<E>> extends Relationship<E>
    with ListMixin<E> {
  @protected
  @visibleForTesting
  final List<DataId<E>> dataIds;
  final List<E> _uninitializedModels;
  final bool _save;

  HasMany([List<E> models, DataManager manager, this._save = true])
      : dataIds = [],
        _uninitializedModels = models ?? [],
        super(manager) {
    initializeModels();
  }

  HasMany._(this.dataIds, DataManager manager)
      : _uninitializedModels = [],
        _save = true,
        super(manager);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    final manager = map['_'][1] as DataManager;
    if (map['_'][0] == null) {
      return HasMany._([], manager);
    }
    final keys = List<String>.from(map['_'][0] as Iterable);
    return HasMany._(DataId.byKeys(keys, manager), manager);
  }

  // ownership & init

  initializeModels() {
    if (_manager != null) {
      addAll(_uninitializedModels);
      _uninitializedModels.clear();
    }
  }

  set owner(DataId owner) {
    _owner = owner;
    _manager = owner.manager;
    initializeModels();
  }

  set inverse(DataId<E> inverse) {
    if (!dataIds.contains(inverse)) {
      dataIds.add(inverse);
    }
  }

  // array methods

  @override
  E operator [](int index) {
    final value = _repository.localAdapter.findOne(dataIds[index].key);
    if (value != null) {
      _repository.localAdapter.setInverseInModel(_owner, value);
    }
    return value;
  }

  @override
  operator []=(int index, E value) {
    if (value != null) {
      dataIds[index] =
          _repository.localAdapter._init(value, save: _save)._dataId;
    }
  }

  @override
  int get length => dataIds.length;

  @override
  set length(int newLength) => dataIds.length = newLength;

  // misc

  List<String> get keys => dataIds.map((d) => d.key).toList();

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataIds == other.dataIds;

  @override
  int get hashCode => runtimeType.hashCode ^ dataIds.hashCode;

  @override
  toJson() => keys;

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';
}
