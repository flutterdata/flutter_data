part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>, N> with SetMixin<E> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  RelNotifier _relNotifier;
  String _owner;

  // list of models waiting for a repository
  // to get initialized (and obtain a key)
  final Set<E> _uninitializedModels;
  final Set<String> _uninitializedKeys;
  final bool _save;
  final bool _wasOmitted;

  DataStateNotifier<N> _notifier;

  @protected
  final String type = Repository.getType<E>();
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
    // loop over a copy of the _uninitializedModels set
    for (var model in _uninitializedModels.toSet()) {
      // attempt to initialize
      // if it doesn't work in the (first) constructor call
      // it will work in the (second) setOwner call
      if (_repository != null) {
        _repository.initModel(model);
      }
      if (model.key != null) {
        _uninitializedKeys.add(model.key);
        _uninitializedModels.remove(model);
      }
      if (_repository != null) {
        assert(_uninitializedModels.isEmpty == true);
      }
    }
  }

  @protected
  @visibleForTesting
  void initializeKeys() {
    _relNotifier = manager._graphNotifier.notifierFor(_owner);
    if (!_wasOmitted) {
      // if it wasn't omitted, we overwrite
      _relNotifier.removeAllFor(type);
      _relNotifier.addAll(_uninitializedKeys);
      _uninitializedKeys.clear();
    }
  }

  void setOwner(String key, DataManager manager) {
    assert(key != null);
    _owner = key;
    this.manager = manager;
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
        ? _relNotifier?.add(_repository.initModel(value, save: _save).key)
        : _uninitializedModels.add(value);
    return true;
  }

  @override
  bool contains(Object element) {
    if (element is E && _relNotifier != null) {
      return _relNotifier.relationshipKeys(type).contains(element?.key) ||
          _uninitializedModels.contains(element);
    }
    return false;
  }

  Iterable<E> get _iterable => [
        ..._relNotifier
            ?.relationshipKeys(type)
            ?.map((key) => _repository.box.get(key)),
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
      _relNotifier?.remove(value?.key);
      _uninitializedModels.remove(value);
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

  Set<String> get keys => _relNotifier?.relationshipKeys(type) ?? {};

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
