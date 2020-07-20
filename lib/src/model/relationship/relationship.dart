part of flutter_data;

abstract class Relationship<E extends DataSupport<E>, N>
    with SetMixin<E>, _Lifecycle<Relationship<E, N>> {
  @protected
  Relationship([Set<E> models])
      : _uninitializedKeys =
            models?.map((model) => model._key)?.filterNulls?.toSet() ?? {},
        _uninitializedModels =
            models?.where((model) => model._key == null)?.toSet() ?? {},
        _wasOmitted = models == null;

  Relationship._(Iterable<String> keys, this._wasOmitted)
      : _uninitializedKeys = keys.toSet(),
        _uninitializedModels = {};

  String _ownerKey;
  String _name;
  String _inverseName;
  Map<String, RemoteAdapter> _adapters;
  RemoteAdapter<E> _adapter;
  GraphNotifier get _graph => _adapter.localAdapter.graph;

  final Set<String> _uninitializedKeys;
  final Set<E> _uninitializedModels;
  bool _wasOmitted;

  @protected
  String get type => DataHelpers.getType<E>();

  @override
  @mustCallSuper
  Future<Relationship<E, N>> initialize(
      {final Map<String, RemoteAdapter> adapters,
      final DataSupport owner,
      final String name,
      final String inverseName}) async {
    if (isInitialized) return this;

    _adapters = adapters;
    _adapter = adapters[type] as RemoteAdapter<E>;

    assert(owner != null && _adapter != null);
    _ownerKey = owner._key;
    _name = name;
    _inverseName = inverseName;

    // initialize uninitialized models and get keys
    final newKeys = _uninitializedModels.map((model) {
      return model._initialize(_adapters, save: true)._key;
    });
    _uninitializedKeys..addAll(newKeys);

    // initialize keys
    if (!_wasOmitted) {
      // if it wasn't omitted, we overwrite
      _graph._removeEdges(_ownerKey,
          metadata: _name, inverseMetadata: _inverseName);
      _graph._addEdges(
        _ownerKey,
        tos: _uninitializedKeys,
        metadata: _name,
        inverseMetadata: _inverseName,
      );
      _uninitializedKeys.clear();
    }

    await super.initialize();
    return this;
  }

  @override
  bool get isInitialized => _ownerKey != null;

  /// Implement [Set]

  @override
  bool add(E value, {bool notify = true}) {
    if (value == null) {
      return false;
    }

    // try to ensure value is initialized
    if (!value._isInitialized && _adapters != null) {
      value._initialize(_adapters, save: true);
    }

    if (value._isInitialized && _adapters != null) {
      _graph._addEdge(_ownerKey, value._key,
          metadata: _name, inverseMetadata: _inverseName);
    } else {
      // if it can't be initialized, add to the models queue
      _uninitializedModels.add(value);
      // set wasOmitted to false so that it's processed
      _wasOmitted = false;
    }
    return true;
  }

  @override
  bool contains(Object element) {
    if (element is E && _graph != null) {
      return _graph._getEdge(_ownerKey, metadata: _name).contains(element._key);
    }
    return false;
  }

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
    if (value is E && _graph != null) {
      assert(value._key != null);
      _graph._removeEdge(
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

  // support methods

  Iterable<E> get _iterable => keys
      .map((key) =>
          _adapter.localAdapter.findOne(key)?._initialize(_adapters, key: key))
      .filterNulls;

  @protected
  @visibleForTesting
  Set<String> get keys {
    // if not null return, else return empty set
    if (_ownerKey != null) {
      return _graph?._getEdge(_ownerKey, metadata: _name)?.toSet() ?? {};
    }
    return {};
  }

  // notifier

  StateNotifier<List<DataGraphEvent>> get _graphEvents {
    assert(_adapter != null);
    return _adapter.throttledGraph.map((events) {
      final appliesToRelationship = (DataGraphEvent event) {
        return event.type.isEdge &&
            event.metadata == _name &&
            event.keys.containsFirst(_ownerKey);
      };
      return events.where(appliesToRelationship).toImmutableList();
    });
  }

  // abstract methods

  StateNotifier<N> watch();

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

extension IterableRelationshipExtension<T extends DataSupport<T>> on Set<T> {
  HasMany<T> get asHasMany => HasMany<T>(this);
}

extension DataSupportRelationshipExtension<T extends DataSupport<T>>
    on DataSupport<T> {
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}

// annotation

class DataRelationship {
  final String inverse;
  const DataRelationship({@required this.inverse});
}
