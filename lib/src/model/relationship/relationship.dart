part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>, N> with SetMixin<E> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  GraphNotifier get _graphNotifier => manager._graphNotifier;
  String _owner;
  String _propertyName;

  // list of models waiting for a repository
  // to get initialized (and obtain a key)
  final Set<E> _uninitializedModels;
  final Set<String> _uninitializedKeys;
  final bool _save;
  final bool _wasOmitted;

  DataStateNotifier<N> _notifier;

  @protected
  String get type => Repository.getType<E>();
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
      if (model._key != null) {
        _uninitializedKeys.add(model._key);
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
    if (!_wasOmitted) {
      // if it wasn't omitted, we overwrite
      _graphNotifier.removeAllFor(_owner, type);
      _graphNotifier.addAll(_owner, _uninitializedKeys);
      _uninitializedKeys.clear();
    }
  }

  void setOwner(String key, DataManager manager) {
    assert(key != null);
    _owner = key;
    _propertyName = null; // TODO how this relationship is named in the owner
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
        ? _graphNotifier?.add(_repository.initModel(value, save: _save)._key)
        : _uninitializedModels.add(value);
    return true;
  }

  @override
  bool contains(Object element) {
    if (element is E && _graphNotifier != null) {
      return _graphNotifier
              .relationshipKeysFor(_owner, type)
              .contains(element?._key) ||
          _uninitializedModels.contains(element);
    }
    return false;
  }

  Iterable<E> get _iterable => [
        ..._graphNotifier
            ?.relationshipKeysFor(_owner, type)
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
      _graphNotifier?.remove(value?._key);
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

  Set<String> get keys =>
      _graphNotifier?.relationshipKeysFor(_owner, type) ?? {};

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
