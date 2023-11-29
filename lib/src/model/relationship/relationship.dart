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

  bool get isInitialized => _ownerKey != null;

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModelMixin]) by supplying the owner, and related metadata.
  /// [overrideKeys] ignores if the relationship was previously initialized.
  Relationship<E, N> initialize(
      {required final DataModelMixin owner,
      required final String name,
      final String? inverseName,
      Set<String>? overrideKeys}) {
    if (overrideKeys == null && isInitialized) return this;

    _ownerKey = owner._key;
    _name = name;
    _inverseName = inverseName;

    if (overrideKeys != null) {
      _uninitializedKeys = overrideKeys;
    } else if (_uninitializedKeys == null) {
      // means it was omitted (remote-omitted, or loaded locally), so skip
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

    // clear existing
    final q1 = Edge_.from.equals(_ownerKey!) & Edge_.name.equals(_name!);
    final q2 = Edge_.to.equals(_ownerKey!) &
        Edge_.inverseName.equals(_name!); // not inverseName!
    _graph._edgeBox.query(q1 | q2).build().remove();
  }

  Edge _createEdgeTo(String to) {
    return Edge(
      id: 0, // autoincrement
      from: _ownerKey!,
      to: to,
      name: _name!,
      inverseName: _inverseName,
    );
  }

  Set<Edge> get _localUnsavedEdges => _graph._unsavedEdges
      .where((e) => e.from == _ownerKey && e.name == _name!)
      .toSet();

  // implement collection-like methods

  bool _add(E value, {bool notify = true}) {
    final edge = _createEdgeTo(value._key!);
    if (_graph._unsavedEdges.contains(edge)) {
      return false;
    }

    // Add to edges, remove from removed edges
    _graph._unsavedEdges.add(edge);
    _graph._unsavedRemovedEdges.remove(edge);

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
    final edge =
        _localUnsavedEdges.firstWhereOrNull((e) => e.to == value._key!);
    if (edge == null) {
      return false;
    }

    // Remove from edges, add to removed edges
    _graph._unsavedEdges.remove(edge);
    _graph._unsavedRemovedEdges.add(edge);

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

  Set<String> get _keys {
    if (!isInitialized) return {};
    final key = _ownerKey!;
    final inverseEdges = _graph._unsavedEdges
        .where((e) => e.to == _ownerKey! && e.inverseName == _name!);

    final edges = _graph._edgeBox
        .query((Edge_.from.equals(key) & Edge_.name.equals(_name!)) |
            (Edge_.to.equals(key) & Edge_.inverseName.equals(_name!)))
        .build()
        .find();
    return {
      for (final e in {..._localUnsavedEdges, ...inverseEdges, ...edges})
        e.from == key ? e.to : e.from
    };
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

  int get length =>
      _keys.map(_adapter.localAdapter.exists).where((e) => e == true).length;

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
