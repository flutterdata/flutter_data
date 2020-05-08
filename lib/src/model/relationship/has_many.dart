part of flutter_data;

class HasMany<E extends DataSupportMixin<E>> extends Relationship<E>
    with SetMixin<E> {
  @protected
  @visibleForTesting
  final LinkedHashSet<DataId<E>> dataIds;
  final Set<E> _uninitializedModels;
  final bool _save;
  final _notifier = DataStateNotifier<Set<E>>(DataState(model: {}));

  HasMany([Set<E> models, DataManager manager, this._save = true])
      : dataIds = LinkedHashSet.from({}),
        _uninitializedModels = models ?? {},
        super(manager) {
    initializeModels();
  }

  HasMany._(this.dataIds, DataManager manager)
      : _uninitializedModels = {},
        _save = true,
        super(manager);

  factory HasMany.fromJson(Map<String, dynamic> map) {
    final manager = map['_'][1] as DataManager;
    if (map['_'][0] == null) {
      return HasMany._(LinkedHashSet(), manager);
    }
    final keys = List<String>.from(map['_'][0] as Iterable);
    return HasMany._(
        LinkedHashSet.from(DataId.byKeys<E>(keys, manager)), manager);
  }

  // ownership & init

  @protected
  @visibleForTesting
  void initializeModels() {
    if (_repository != null) {
      addAll(_uninitializedModels);
      _uninitializedModels.clear();
    }
  }

  set owner(DataId owner) {
    _owner = owner;
    manager = owner.manager;
    initializeModels();
  }

  set inverse(DataId<E> inverse) {
    if (!dataIds.contains(inverse)) {
      dataIds.add(inverse);
    }
  }

  // implement set

  @override
  bool add(E value) {
    final ok = _repository != null
        ? dataIds.add(_repository._init(value, save: _save)._dataId)
        : _uninitializedModels.add(value);
    _notifier.state = DataState(model: this);
    return ok;
  }

  @override
  bool contains(Object element) {
    if (element is E) {
      return dataIds.contains(element._dataId) ||
          _uninitializedModels.contains(element);
    }
    return false;
  }

  Iterable<E> get _iterable => [
        ...dataIds.map((dataId) {
          final model = _repository.box.safeGet(dataId.key);
          if (model != null) {
            _repository.setInverseInModel(_owner, model);
          }
          return model;
        }),
        ..._uninitializedModels
      ];

  @override
  Iterator<E> get iterator => _iterable.iterator;

  @override
  E lookup(Object element) {
    if (element is E &&
        (contains(element) || _uninitializedModels.contains(element))) {
      return element;
    }
    return null;
  }

  @override
  bool remove(Object value) {
    if (value is E) {
      final ok =
          dataIds.remove(value._dataId) || _uninitializedModels.remove(value);
      _notifier.state = DataState(model: this);
      return ok;
    }
    return false;
  }

  @override
  int get length => _iterable.length;

  @override
  Set<E> toSet() {
    return _iterable.toSet();
  }

  // watch

  @override
  DataStateNotifier<Set<E>> watch() {
    return _notifier;
  }

  // misc

  Set<String> get keys => dataIds.map((d) => d.key).toSet();

  @override
  dynamic toJson() => keys.toList();

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((dataId) => dataId.id)})';
}
