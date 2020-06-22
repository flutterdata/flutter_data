part of flutter_data;

abstract class Relationship<E extends DataSupport<E>, N> with SetMixin<E> {
  // ignore: prefer_final_fields
  @protected
  @visibleForTesting
  DataManager manager;

  bool get _isInitialized => _ownerKey != null;

  String _ownerKey;
  String _name;
  String _inverseName;

  final Set<String> _uninitializedKeys;
  final Set<E> _uninitializedModels;
  final bool _wasOmitted;

  ValueStateNotifier<N> _notifier;

  @protected
  String get type => Repository.getType<E>();
  Repository<E> get _repository => manager?.locator<Repository<E>>();

  Relationship([Set<E> models, this.manager])
      : _uninitializedKeys =
            models?.map((model) => model._key)?.filterNulls?.toSet() ?? {},
        _uninitializedModels =
            models?.where((model) => model._key == null)?.toSet() ?? {},
        _wasOmitted = models == null;

  Relationship._(Iterable<String> keys, this.manager, this._wasOmitted)
      : _uninitializedKeys = keys.toSet(),
        _uninitializedModels = {};

  //

  void initialize(DataManager manager, DataSupport owner, String name,
      String inverseName, String inverseType) {
    if (_isInitialized) {
      return;
    }

    assert(owner != null);
    this.manager = manager;
    _ownerKey = owner._key;
    _name = name;
    _inverseName = inverseName;

    final ownerType = owner._repository.type;

    if (_inverseName == null &&
        _repository.relatedRepositories[ownerType] != null) {
      final entries = _repository
          .relatedRepositories[ownerType].relatedRepositories[inverseType]
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

    // initialize uninitialized models and get keys
    final newKeys = _uninitializedModels.map((model) {
      return _repository._initModel(model, save: true)._key;
    });
    _uninitializedKeys..addAll(newKeys);

    // initialize keys
    if (!_wasOmitted) {
      // if it wasn't omitted, we overwrite
      manager.graph.removeEdges(_ownerKey,
          metadata: _name, inverseMetadata: _inverseName);
      manager.graph.addEdges(
        _ownerKey,
        tos: _uninitializedKeys,
        metadata: _name,
        inverseMetadata: _inverseName,
      );
      _uninitializedKeys.clear();
    }
  }

  // implement set

  @override
  bool add(E value, {bool notify = true}) {
    if (value == null) {
      return false;
    }

    if (_repository != null) {
      _repository._initModel(value, save: true);
      manager.graph.addEdge(_ownerKey, value._key,
          metadata: _name, inverseMetadata: _inverseName);
      return true;
    } else if (value._key != null) {
      _uninitializedKeys.add(value._key);
      return true;
    } else {
      return false;
    }
  }

  @override
  bool contains(Object element) {
    if (element is E && manager?.graph != null) {
      return manager.graph
          .getEdge(_ownerKey, metadata: _name)
          .contains(element._key);
    }
    return false;
  }

  Iterable<E> get _iterable =>
      keys.map((key) => _repository.localGet(key)).filterNulls;

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
  bool remove(Object value, {bool notify = true}) {
    if (value is E) {
      assert(value._key != null);
      manager.graph.removeEdge(
        _ownerKey,
        value._key,
        metadata: _name,
        inverseMetadata: _inverseName,
        notify: notify,
      );
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

  @protected
  @visibleForTesting
  Set<String> get keys {
    // if not null return, else return empty set
    final graph = manager?.graph;
    if (graph != null && _ownerKey != null) {
      return graph.getEdge(_ownerKey, metadata: _name)?.toSet() ?? {};
    }
    return {};
  }

  // notifier

  @protected
  @visibleForTesting
  StateNotifier<DataGraphEvent> get graphEventNotifier =>
      manager?.graph?.where((event) {
        return [
              DataGraphEventType.addEdge,
              DataGraphEventType.updateEdge,
              DataGraphEventType.removeEdge
            ].contains(event.type) &&
            event.metadata == _name &&
            event.keys.containsFirst(_ownerKey);
      });

  // abstract

  ValueStateNotifier<N> watch();

  dynamic toJson();

  @override
  String toString();

  // equality

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || other is Relationship && keys == other.keys;

  @override
  int get hashCode => runtimeType.hashCode ^ keys.hashCode;
}

class ValueStateNotifier<E> extends StateNotifier<E> {
  ValueStateNotifier([E state]) : super(state);
  E get value => state;
  set value(E value) => state = value;
}
