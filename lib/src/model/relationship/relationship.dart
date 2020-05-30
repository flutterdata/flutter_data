part of flutter_data;

abstract class Relationship<E extends DataSupportMixin<E>, N> with SetMixin<E> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  GraphNotifier get _graphNotifier => manager._graphNotifier;
  String _ownerKey;
  String _name;
  String _inverseName;

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
      if (keyFor(model) != null) {
        _uninitializedKeys.add(keyFor(model));
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
      _graphNotifier.removeAll(_ownerKey, metadata: _name);
      _graphNotifier.addAll(_ownerKey, _uninitializedKeys,
          metadata: _name, inverseMetadata: _inverseName);
      _uninitializedKeys.clear();
    }
  }

  void setOwner(String ownerType, String ownerKey, String name,
      Map<String, Object> relationshipMetadata, DataManager manager) {
    assert(ownerKey != null);
    this.manager = manager;
    _ownerKey = ownerKey;
    _name = name;

    _inverseName = relationshipMetadata['inverse'] as String;

    if (_inverseName == null &&
        _repository.relatedRepositories[ownerType] != null) {
      final relType = relationshipMetadata['type'] as String;
      final entries = _repository
          .relatedRepositories[ownerType].relatedRepositories[relType]
          .relationshipsFor(null)
          .entries
          .where((e) => e.value['type'] == ownerType);
      if (entries.length > 1) {
        throw UnsupportedError('''
Too many possible inverses for '$name': ${entries.map((e) => e.key)}

Please specify the correct inverse in the ${singularize(ownerType)} class annotating '$name' with, for example:

@DataRelationship(inverse: '${entries.first.key}')

and trigger a code generation build again.
''');
      }
      _inverseName = entries.isNotEmpty ? entries.first.key : null;
    }

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
    if (_repository != null) {
      final model = _repository.initModel(value, save: _save);
      _graphNotifier.add(_ownerKey, keyFor(model),
          metadata: _name, inverseMetadata: _inverseName);
    } else {
      _uninitializedModels.add(value);
    }
    return true;
  }

  @override
  bool contains(Object element) {
    if (element is E && _graphNotifier != null) {
      return _graphNotifier
              .get(_ownerKey, metadata: _name)
              .contains(keyFor(element)) ||
          _uninitializedModels.contains(element);
    }
    return false;
  }

  Iterable<E> get _iterable => [
        ...keys.map((key) => _repository.box.get(key)),
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
      _graphNotifier?.removeNode(keyFor(value));
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

  Set<String> get keys => _graphNotifier?.get(_ownerKey, metadata: _name) ?? {};

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
