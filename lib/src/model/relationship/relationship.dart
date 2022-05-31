part of flutter_data;

/// A `Set` that models a relationship between one or more [DataModel] objects
/// and their a [DataModel] owner. Backed by a [GraphNotifier].
abstract class Relationship<E extends DataModel<E>, N> with EquatableMixin {
  @protected
  Relationship(Set<E>? models)
      : this._(models?.map((m) {
          if (!m._isInitialized) {
            throw AssertionError(
                'Model $m must be initialized to be included in this relationship');
          }
          return m.__key!;
        }).toSet());

  Relationship._(this._uninitializedKeys);

  Relationship._remove() : _uninitializedKeys = {};

  String? _ownerKey;
  String? _name;
  String? _inverseName;

  RemoteAdapter<E> get _adapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<E>;
  GraphNotifier get _graph => _adapter.localAdapter.graph;

  final Set<int>? _uninitializedKeys;
  String get _internalType => DataHelpers.getType<E>();

  bool get isInitialized => _ownerKey != null;

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModel]) by supplying the owner, and related metadata.
  Relationship<E, N> initialize(
      {required final DataModel owner,
      required final String name,
      final String? inverseName}) {
    if (isInitialized) return this;

    _ownerKey = owner._key;
    _name = name;
    _inverseName = inverseName;

    // means it was omitted (remote-omitted, or loaded locally), so skip
    if (_uninitializedKeys == null) return this;

    // setting up from scratch, remove all and add keys

    _graph._removeEdges(_ownerKey!, metadata: _name!, notify: false);

    _graph._addEdges(
      _ownerKey!,
      tos: _uninitializedKeys!.map((key) => key.typifyWith(_internalType)),
      metadata: _name!,
      inverseMetadata: _inverseName,
      notify: false,
    );
    _uninitializedKeys!.clear();

    // TODO notify?

    return this;
  }

  // collection-like methods

  bool _add(E value, {bool notify = true}) {
    if (_contains(value)) {
      return false;
    }
    _graph._addEdges(_ownerKey!,
        tos: [value._key],
        metadata: _name!,
        inverseMetadata: _inverseName,
        notify: notify);
    return true;
  }

  bool _contains(Object? element) {
    return _iterable.contains(element);
  }

  bool _remove(Object? value, {bool notify = true}) {
    assert(value is E);
    final model = value as E;

    _graph._removeEdges(
      _ownerKey!,
      tos: [model._key],
      metadata: _name!,
      notify: notify,
    );
    return true;
  }

  // support methods

  Iterable<E> get _iterable {
    return _keys.map((key) => _adapter.localAdapter.findOne(key)).filterNulls;
  }

  Set<int> get _keys {
    if (!isInitialized) return {};
    return _graph
        ._getEdges(_ownerKey!, metadata: _name!)
        .map((e) => e.to._detypifyInt())
        .toSet();
  }

  Set<Object> get _ids {
    return _keys.map((key) => _graph.getIdForKey(key)).filterNulls.toSet();
  }

  /// This is used to make `json_serializable`'s `explicitToJson` transparent.
  ///
  /// For internal use. Does not return valid JSON.
  dynamic toJson() => this;

  /// Whether the relationship has a value.
  bool get isPresent;

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
