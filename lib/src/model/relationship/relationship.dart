part of flutter_data;

/// A `Set` that models a relationship between one or more [DataModel] objects
/// and their a [DataModel] owner. Backed by a [GraphNotifier].
abstract class Relationship<E extends DataModel<E>, N> with EquatableMixin {
  @protected
  Relationship(Set<E>? models) : this._(models?.map((m) => m._key).toSet());

  Relationship._(this._uninitializedKeys);

  Relationship._remove() : _uninitializedKeys = {};

  String? _ownerKey;
  String? _name;
  String? _inverseName;

  RemoteAdapter<E> get _adapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<E>;
  GraphNotifier get _graph => _adapter.localAdapter.graph;

  final Set<String>? _uninitializedKeys;
  String get _internalType => DataHelpers.getType<E>();

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModel]) by supplying the owner, and related metadata.
  Relationship<E, N> initialize(
      {required final DataModel owner,
      required final String name,
      final String? inverseName}) {
    if (_ownerKey != null) {
      return this; // return if already initialized
    }

    _ownerKey = owner._key;
    _name = name;
    _inverseName = inverseName;

    if (_uninitializedKeys == null) {
      // means it was omitted (remote-omitted, or loaded locally), so skip
      return this;
    }

    // setting up from scratch, remove all and add keys

    _graph._removeEdges(_ownerKey!,
        metadata: _name!, inverseMetadata: _inverseName, notify: false);

    _graph._addEdges(
      _ownerKey!,
      tos: _uninitializedKeys!,
      metadata: _name!,
      inverseMetadata: _inverseName,
      notify: false,
    );
    _uninitializedKeys!.clear();

    return this;
  }

  // implement collection-like methods

  /// Add a [value] to this [Relationship]
  ///
  /// Attempting to add an existing [value] has no effect as this is a [Set]
  bool add(E value, {bool notify = true}) {
    if (contains(value)) {
      return false;
    }

    _graph._addEdge(_ownerKey!, value._key,
        metadata: _name!, inverseMetadata: _inverseName, notify: false);
    if (notify) {
      _graph._notify(
        [_ownerKey!, value._key],
        metadata: _name,
        type: DataGraphEventType.addEdge,
      );
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

    _graph._removeEdge(
      _ownerKey!,
      model._key,
      metadata: _name!,
      inverseMetadata: _inverseName,
      notify: false,
    );
    if (notify) {
      _graph._notify(
        [_ownerKey!, value._key],
        metadata: _name,
        type: DataGraphEventType.removeEdge,
      );
    }
    return true;
  }

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
    return keys.map((key) => _adapter.localAdapter.findOne(key)).filterNulls;
  }

  /// Returns keys as [Set] in relationship
  @protected
  @visibleForTesting
  Set<String> get keys {
    return _graph._getEdge(_ownerKey!, metadata: _name!).toSet();
  }

  Set<String> get ids {
    return keys.map((key) => _graph.getIdForKey(key)).filterNulls.toSet();
  }

  Set<Relationship?> andEach(AlsoWatch<E>? alsoWatch) {
    return {
      this,
      for (final value in _iterable) ...?alsoWatch?.call(value),
    };
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

  @override
  List<Object?> get props => [keys, _name];
}

// annotation

class DataRelationship {
  final String inverse;
  const DataRelationship({required this.inverse});
}
