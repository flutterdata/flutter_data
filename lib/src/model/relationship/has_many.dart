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
    final value = _repository.box.safeGet(dataIds[index].key);
    if (value != null) {
      _repository.setInverseInModel(_owner, value);
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
    const oneFrameDuration = Duration(milliseconds: 16);
    final _notifier = DataStateNotifier<List<E>>(DataState(model: this));
    _repository.box
        .watch()
        .buffer(Stream.periodic(oneFrameDuration))
        .forEach((events) {
      // check if there are event keys in our keys
      final hasKeys = keys
          .toSet()
          .intersection(events.map((e) => e.key.toString()).toSet())
          .isNotEmpty;
      if (hasKeys) {
        _notifier.state = _notifier.state.copyWith(model: this);
      }
    });
    return _notifier;
  }

  // misc

  List<String> get keys => dataIds.map((d) => d.key).toList();

  @override
  dynamic toJson() => keys;

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((d) => d.id)})';
}
