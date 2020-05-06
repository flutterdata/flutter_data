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

  void initializeModels() {
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
    final localAdapter = _repository as LocalAdapter<E>;
    final value = localAdapter.localFindOne(dataIds[index].key);
    if (value != null) {
      localAdapter.setInverseInModel(_owner, value);
    }
    return value;
  }

  @override
  operator []=(int index, E value) {
    dataIds[index] = _repository._init(value, save: _save)._dataId;
  }

  @override
  int get length => dataIds.length;

  @override
  set length(int newLength) => dataIds.length = newLength;

  // watch

  @override
  DataStateNotifier<List<E>> watch() {
    return _repository.watchAll().map(
        (state) => state.copyWith(model: state.model.where(contains).toList()));
  }

  // misc

  List<String> get keys => dataIds.map((d) => d.key).toList();

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || dataIds == other.dataIds;

  @override
  int get hashCode => runtimeType.hashCode ^ dataIds.hashCode;

  @override
  dynamic toJson() => keys;

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';
}
