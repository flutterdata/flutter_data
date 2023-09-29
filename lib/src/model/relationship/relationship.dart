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

    // setting up from scratch, add edges (removing existing)

    _graph._addEdges(
      _ownerKey!,
      tos: _uninitializedKeys!,
      metadata: _name!,
      inverseMetadata: _inverseName,
      clearExisting: true,
      notify: false,
    );

    _uninitializedKeys!.clear();

    return this;
  }

  // implement collection-like methods

  bool _add(E value, {bool notify = true}) {
    if (_contains(value)) {
      return false;
    }

    _graph._addEdge(_ownerKey!, value._key!,
        metadata: _name!, inverseMetadata: _inverseName, notify: false);

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

  bool _remove(Object? value, {bool notify = true}) {
    assert(value is E);
    final model = value as E;

    _graph._removeEdge(
      _ownerKey!,
      model._key!,
      metadata: _name!,
      notify: false,
    );

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
    return _graph._getEdge(_ownerKey!, metadata: _name!).toSet();
  }

  Set<Object> get _ids {
    return _keys.map((key) => _graph.getIdForKey(key)).filterNulls.toSet();
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
