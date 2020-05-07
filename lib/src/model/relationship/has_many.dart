part of flutter_data;

class HasMany<E extends DataSupportMixin<E>> extends Relationship<E>
    with SetMixin<E> {
  @protected
  @visibleForTesting
  final LinkedHashSet<DataId<E>> dataIds;
  final List<E> _uninitializedModels;
  final bool _save;

  HasMany([List<E> models, DataManager manager, this._save = true])
      : dataIds = LinkedHashSet.from({}),
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
      return HasMany._(LinkedHashSet(), manager);
    }
    final keys = List<String>.from(map['_'][0] as Iterable);
    return HasMany._(
        LinkedHashSet.from(DataId.byKeys<E>(keys, manager)), manager);
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

  @override
  bool add(E value) {
    return dataIds.add(_repository._init(value, save: _save)._dataId);
  }

  @override
  bool contains(Object element) {
    if (element is E) {
      return dataIds.contains(element._dataId);
    }
    return false;
  }

  Iterable<E> get _iterable => dataIds.map((dataId) {
        final model = _repository.box.safeGet(dataId.key);
        if (model != null) {
          _repository.setInverseInModel(_owner, model);
        }
        return model;
      });

  @override
  Iterator<E> get iterator => _iterable.iterator;

  @override
  E lookup(Object element) {
    if (element is E && contains(element)) {
      return element;
    }
    return null;
  }

  @override
  bool remove(Object value) {
    if (value is E) {
      return dataIds.remove(value._dataId);
    }
    return false;
  }

  @override
  int get length => dataIds.length;

  @override
  Set<E> toSet() {
    return _iterable.toSet();
  }

  // watch

  @override
  DataStateNotifier<Set<E>> watch() {
    const oneFrameDuration = Duration(milliseconds: 16);
    final _notifier = DataStateNotifier<Set<E>>(DataState(model: this));
    _repository.box
        .watch()
        .buffer(Stream.periodic(oneFrameDuration))
        .forEach((events) {
      // check if there are event keys in our keys
      final hasKeys = events
          .map((e) => e.key.toString())
          .toSet()
          .intersection(keys)
          .isNotEmpty;
      if (hasKeys) {
        _notifier.state = _notifier.state.copyWith(model: this);
      }
    });
    return _notifier;
  }

  // misc

  Set<String> get keys => dataIds.map((d) => d.key).toSet();

  @override
  dynamic toJson() => keys;

  @override
  String toString() => 'HasMany<$E>(${dataIds.map((dataId) => dataId.id)})';
}
