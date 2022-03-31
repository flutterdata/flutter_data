part of flutter_data;

/// A `Set` that models a relationship between one or more [DataModel] objects
/// and their a [DataModel] owner. Backed by a [GraphNotifier].
abstract class Relationship<E extends DataModel<E>, N>
    with EquatableMixin, _Lifecycle {
  @protected
  Relationship([Set<E>? models])
      : _uninitializedKeys = {},
        _uninitializedModels = models ?? {},
        _wasOmitted = models == null,
        _shouldRemove = false;

  Relationship._(Iterable<String> keys, this._wasOmitted)
      : _uninitializedKeys = keys.toSet(),
        _uninitializedModels = {},
        _shouldRemove = false;

  Relationship._remove()
      : _uninitializedKeys = {},
        _uninitializedModels = {},
        _wasOmitted = false,
        _shouldRemove = true;

  late final String _ownerKey;
  late final String _name;
  late final String? _inverseName;
  late final Map<String, RemoteAdapter> _adapters;
  late final RemoteAdapter<E> _adapter;
  GraphNotifier get _graph => _adapter.localAdapter.graph;

  final Set<String> _uninitializedKeys;
  final Set<E> _uninitializedModels;
  final bool _wasOmitted;
  final bool _shouldRemove;

  @protected
  String get internalType => DataHelpers.getType<E>();

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModel]) by supplying the owner, and related [adapters] and metadata.
  Future<Relationship<E, N>> initialize(
      {required final Map<String, RemoteAdapter> adapters,
      required final DataModel owner,
      required final String name,
      final String? inverseName}) async {
    if (isInitialized) return this;

    _adapters = adapters;
    _adapter = adapters[internalType] as RemoteAdapter<E>;

    _ownerKey = owner._key!;
    _name = name;
    _inverseName = inverseName;

    if (_shouldRemove) {
      _graph._removeEdges(_ownerKey,
          metadata: _name, inverseMetadata: _inverseName);
    } else {
      // initialize uninitialized models and get keys
      final newKeys = _uninitializedModels.map((model) {
        return model._initialize(_adapters, save: true)._key!;
      });
      _uninitializedKeys.addAll(newKeys);
    }

    _uninitializedModels.clear();

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

    isInitialized = true;
    return this;
  }

  @override
  bool isInitialized = false;

  // implement collection-like methods

  /// Add a [value] to this [Relationship]
  ///
  /// Attempting to add an existing [value] has no effect as this is a [Set]
  bool add(E value, {bool notify = true}) {
    if (contains(value)) {
      return false;
    }

    // try to ensure value is initialized
    _ensureModelIsInitialized(value);

    if (value.isInitialized && isInitialized) {
      _graph._addEdge(_ownerKey, value._key!,
          metadata: _name, inverseMetadata: _inverseName);
    } else {
      // if it can't be initialized, add to the models queue
      _uninitializedModels.add(value);
    }
    return true;
  }

  bool contains(Object? element) {
    return _iterable.contains(element);
  }

  /// Removes a [value] from this [Relationship]
  bool remove(Object? value, {bool notify = true}) {
    assert(value is E);
    final model = value as E;
    if (isInitialized) {
      _ensureModelIsInitialized(model);
      _graph._removeEdge(
        _ownerKey,
        model._key!,
        metadata: _name,
        inverseMetadata: _inverseName,
        notify: notify,
      );
      return true;
    }
    return _uninitializedModels.remove(model);
  }

  Iterator<E> get iterator => _iterable.iterator;

  E? lookup(Object? element) => lookup(element);

  Set<E> toSet() => _iterable.toSet();

  List<E> toList() => _iterable.toList();

  int get length => _iterable.length;

  //

  E get first => _iterable.first;

  bool get isEmpty => _iterable.isEmpty;

  bool get isNotEmpty => _iterable.isNotEmpty;

  Iterable<E> where(bool Function(E) test) => _iterable.where(test);

  Iterable<T> map<T>(T Function(E) f) => _iterable.map(f);

  // support methods

  Iterable<E> get _iterable {
    if (isInitialized) {
      return keys
          .map((key) => _adapter.localAdapter
              .findOne(key)
              ?._initialize(_adapters, key: key))
          .filterNulls;
    }
    return _uninitializedModels;
  }

  /// Returns keys as [Set] in relationship if initialized, otherwise an empty set
  @protected
  @visibleForTesting
  Set<String> get keys {
    if (isInitialized) {
      return _graph._getEdge(_ownerKey, metadata: _name).toSet();
    }
    return _uninitializedKeys;
  }

  Set<String> get ids {
    return keys.map(_graph.getIdForKey).filterNulls.toSet();
  }

  E _ensureModelIsInitialized(E model) {
    if (!model.isInitialized && isInitialized) {
      model._initialize(_adapters, save: true);
    }
    return model;
  }

  DelayedStateNotifier<List<DataGraphEvent>> get _graphEvents {
    return _adapter.throttledGraph.map((events) {
      return events.where((event) {
        return event.type.isEdge &&
            event.metadata == _name &&
            event.keys.containsFirst(_ownerKey);
      }).toImmutableList();
    });
  }

  DelayedStateNotifier<N> watch();

  /// This is used to make `json_serializable`'s `explicitToJson` transparent.
  ///
  /// For internal use. Does not return valid JSON.
  dynamic toJson() => this;

  @override
  List<Object?> get props => [isInitialized, keys, _name];

  @override
  void dispose() {
    // relationships are not disposed
  }
}

// annotation

class DataRelationship {
  final String inverse;
  const DataRelationship({required this.inverse});
}
