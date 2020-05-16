part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>, N> with SetMixin<E> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  RelNotifier _relNotifier;
  DataId _owner;

  // list of models waiting for a repository
  // to get initialized (and obtain a key)
  final Set<E> _uninitializedModels;
  final Set<String> _uninitializedKeys;
  final bool _save;
  final bool _wasOmitted;

  DataStateNotifier<N> _notifier;

  final String type = DataId.getType<E>();
  Repository<E> get _repository => manager?.locator<Repository<E>>();

  Relationship([Set<E> models, this.manager, this._save])
      : _uninitializedModels = models ?? {},
        _uninitializedKeys = {},
        _wasOmitted = models == null {
    initializeModels();
  }

  Relationship._(Iterable<String> keys, this.manager, this._wasOmitted)
      : _uninitializedModels = {},
        _uninitializedKeys = keys.toSet(),
        _save = true;

  //

  @protected
  @visibleForTesting
  void initializeModels() {
    if (_repository != null) {
      addAll(_uninitializedModels);
      _uninitializedModels.clear();
    }
  }

  @protected
  @visibleForTesting
  void initializeKeys() {
    _relNotifier = manager.graphNotifier.notifierFor(_owner.key);
    if (!_wasOmitted) {
      // if it wasn't omitted, we overwrite
      _relNotifier.removeAll();
      _relNotifier.addAll(_uninitializedKeys);
      _uninitializedKeys.clear();
    }
  }

  set owner(DataId owner) {
    _owner = owner;
    manager = owner.manager;
    initializeModels();
    initializeKeys();
  }

  //

  // implement set

  @override
  bool add(E value) {
    if (value == null) {
      return false;
    }
    _repository != null
        ? _relNotifier
            ?.add(_repository.initModel(value, save: _save)._dataId.key)
        : _uninitializedModels.add(value);

    // _notifier?.state = DataState(model: this);
    return true;
  }

  @override
  bool contains(Object element) {
    if (element is E && _relNotifier != null) {
      return _relNotifier.relationshipKeys.contains(element?._dataId?.key) ||
          _uninitializedModels.contains(element);
    }
    return false;
  }

  Iterable<E> get _iterable => [
        ..._relNotifier?.relationshipKeys
            ?.map((key) => _repository.box.safeGet(key)),
        ..._uninitializedModels
      ].where((model) => model != null);

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
      _relNotifier?.remove(value?._dataId?.key);
      _uninitializedModels.remove(value);
      // _notifier?.state = DataState(model: this);
      return true;
    }
    return false;
  }

  @override
  int get length => _iterable.length;

  @override
  Set<E> toSet() {
    return _iterable.toSet();
  }

  Set<String> get keys => _relNotifier?.relationshipKeys ?? {};

  // abstract

  DataStateNotifier<N> watch();

  dynamic toJson();

  @override
  String toString();

  // equality

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || keys == other.keys;

  @override
  int get hashCode => runtimeType.hashCode ^ keys.hashCode;
}
