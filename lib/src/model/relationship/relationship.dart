part of flutter_data;

/// A `Set` that models a relationship between one or more [DataModelMixin] objects
/// and their a [DataModelMixin] owner. Backed by a [GraphNotifier].
abstract class Relationship<E extends DataModelMixin<E>, N>
    with EquatableMixin {
  @protected
  Relationship(Set<E>? models) : this._(models?.map((m) => m._key!).toSet());

  Relationship._(this._uninitializedKeys);

  Relationship._remove() : _uninitializedKeys = {};

  String? _ownerKey;
  String? _name;
  String? _inverseName;

  RemoteAdapter<E> get _adapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<E>;
  GraphNotifier get _graph => _adapter.localAdapter.graph;

  Set<String>? _uninitializedKeys;
  String get _internalType => DataHelpers.getInternalType<E>();

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModelMixin]) by supplying the owner, and related metadata.
  Relationship<E, N> initialize(
      {required final String ownerKey,
      required final String name,
      final String? inverseName}) {
    // If the relationship owner key is same as previous, return
    if (_ownerKey != null && _ownerKey == ownerKey) return this;

    final previousOwnerKey = _ownerKey;
    _ownerKey = ownerKey;
    _name = name;
    _inverseName = inverseName;

    if (previousOwnerKey != null && previousOwnerKey != ownerKey) {
      // new owner key, we need to reinitialize
      _uninitializedKeys = _keysFor(ownerKey, name);
    }

    if (_uninitializedKeys == null) {
      // This means it was omitted (remote-omitted, or loaded locally)
      // so return as-is
      return this;
    }

    _graph._unsavedEdges.removeWhere((e) =>
        (e.from == _ownerKey! && e.name == _name!) ||
        (e.to == _ownerKey! && e.inverseName == _name!));
    _graph._unsavedRemovedEdges.removeWhere((e) =>
        (e.from == _ownerKey! && e.name == _name!) ||
        (e.to == _ownerKey! && e.inverseName == _name!));

    _graph._unsavedEdges.addAll(_uninitializedKeys!.map(_createEdgeTo));

    _uninitializedKeys!.clear();

    return this;
  }

  _sync() {
    // process buffer queue here

    // Try to find ownerKey/name combo from either side of the edge
    final q1 = Edge_.from.equals(_ownerKey!) & Edge_.name.equals(_name!);
    final q2 = Edge_.to.equals(_ownerKey!) & Edge_.inverseName.equals(_name!);
    _graph._edgeBox.query(q1 | q2).build().remove();
  }

  Edge _createEdgeTo(String to) => _createEdgesTo(to).$1;

  (Edge, Edge) _createEdgesTo(String to) {
    return (
      Edge(
        id: 0, // autoincrement
        from: _ownerKey!,
        to: to,
        name: _name!,
        inverseName: _inverseName,
      ),
      Edge(
        id: 0, // autoincrement
        from: to,
        to: _ownerKey!,
        name: _inverseName ?? '', // OK as we only use this for matching
        inverseName: _name,
      )
    );
  }

  Set<Edge> get _localUnsavedEdges => _graph._unsavedEdges
      .where((e) =>
          (e.from == _ownerKey && e.name == _name) ||
          (e.to == _ownerKey && e.inverseName == _name))
      .toSet();

  // implement collection-like methods

  bool _add(E value, {bool notify = true}) {
    final (edge, inverseEdge) = _createEdgesTo(value._key!);

    if (_graph._unsavedEdges.contains(edge) ||
        _graph._unsavedEdges.contains(inverseEdge)) {
      return false;
    }

    // Add to edges, remove from removed edges
    _graph._unsavedEdges.add(edge);
    _graph._unsavedRemovedEdges.remove(edge);
    _graph._unsavedRemovedEdges.remove(inverseEdge);

    if (notify) {
      _graph._notify(
        [_ownerKey!, value._key!],
        metadata: _name,
        type: DataGraphEventType.addEdge,
      );
    }

    return true;
  }

  bool _contains(E? element) {
    return _iterable.contains(element);
  }

  bool _remove(E value, {bool notify = true}) {
    final (edge, inverseEdge) = _createEdgesTo(value._key!);

    // Remove from edges, add to removed edges
    final removed = _graph._unsavedEdges.remove(edge) ||
        _graph._unsavedEdges.remove(inverseEdge);
    _graph._unsavedRemovedEdges.add(edge);

    if (!removed) {
      return false;
    }

    if (notify) {
      _graph._notify(
        [_ownerKey!, value._key!],
        metadata: _name,
        type: DataGraphEventType.removeEdge,
      );
    }
    return true;
  }

  // support methods

  Iterable<E> get _iterable {
    return _adapter.localAdapter.findMany(_keys);
  }

  Query<Edge> _getPersistedEdgesQuery(String key, String name) {
    return _graph._edgeBox
        .query((Edge_.from.equals(key) & Edge_.name.equals(name)) |
            (Edge_.to.equals(key) & Edge_.inverseName.equals(name)))
        .build();
  }

  Set<String> _keysFor(String key, String name) {
    final persistedEdges = _getPersistedEdgesQuery(key, name).find();
    return {
      for (final e in {..._localUnsavedEdges, ...persistedEdges})
        e.from == key ? e.to : e.from
    };
  }

  Set<String> get _keys {
    if (_ownerKey == null) return {};
    return _keysFor(_ownerKey!, _name!);
  }

  Set<Object> get _ids {
    return _keys.map((key) => _graph.getIdForKey(key)).nonNulls.toSet();
  }

  DelayedStateNotifier<DataGraphEvent> get _relationshipEventNotifier {
    return _adapter.graph.where((event) {
      return event.type.isEdge &&
          event.metadata == _name &&
          event.keys.containsFirst(_ownerKey!);
    });
  }

  DelayedStateNotifier<N> watch();

  /// This is used to make `json_serializable`'s `explicitToJson` transparent.
  ///
  /// For internal use. Does not return valid JSON.
  dynamic toJson() => this;

  int get length {
    return _graph._store.runInTransaction(
        TxMode.read,
        () => _keys
            .map(_adapter.localAdapter.exists)
            .where((e) => e == true)
            .length);
  }

  /// Whether the relationship has a value.
  bool get isPresent => length > 0;

  @override
  List<Object?> get props => [_ownerKey, _name, _inverseName];

  @override
  String toString() {
    final keysWithoutId =
        _keys.where((k) => _graph.getIdForKey(k) == null).map((k) => '[$k]');
    return {..._ids, ...keysWithoutId}.join(', ');
  }
}

// annotation

class DataRelationship {
  final String? inverse;
  final bool serialize;
  const DataRelationship({this.inverse, this.serialize = true});
}
