part of flutter_data;

/// A `Set` that models a relationship between one or more [DataModelMixin] objects
/// and their a [DataModelMixin] owner. Backed by a [CoreNotifier].
sealed class Relationship<E extends DataModelMixin<E>, N> with EquatableMixin {
  @protected
  Relationship(Set<E>? models) : this._(models?.map((m) => m._key!).toSet());

  Relationship._(this._uninitializedKeys);

  Relationship._remove() : _uninitializedKeys = {};

  String? _ownerKey;
  String? _name;
  String? _inverseName;

  String get ownerKey => _ownerKey!;
  DataModelMixin? get owner {
    final type = ownerKey.split('#').first;
    final adapter = internalRepositories[type]!.remoteAdapter;
    return adapter.localAdapter.findOne(ownerKey) as DataModelMixin?;
  }

  String get name => _name!;
  String? get inverseName => _inverseName;

  RemoteAdapter<E> get _adapter =>
      internalRepositories[_internalType]!.remoteAdapter as RemoteAdapter<E>;
  CoreNotifier get _core => _adapter.localAdapter.core;

  Set<String>? _uninitializedKeys;
  String get _internalType => DataHelpers.getInternalType<E>();

  final _edgeOperations = <_EdgeOperation>[]; // MUST be a list to retain order

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
      // new owner key, get all keys associated to previous key
      // and reinitialize
      _uninitializedKeys = _keysFor(previousOwnerKey, name);
    }

    if (_uninitializedKeys == null) {
      // This means it was omitted (remote-omitted, or loaded locally)
      // so return as-is
      return this;
    }

    // HasMany(1) -- or hasMany: [1]; this is a source of truth,
    // we need to clear all and set what's required

    // TODO move to a ResetEdgeOperation so we can identify and only "merge"
    // these as they're way more used (not other barely used as add/remove)
    _edgeOperations.add(RemoveEdgeOperation(ownerKey, name));
    _edgeOperations.addAll(_uninitializedKeys!
        .map((to) => AddEdgeOperation(ownerKey, name, to, inverseName)));
    _uninitializedKeys!.clear();

    return this;
  }

  static Condition<Edge> _queryConditionTo(String from, String name,
      [String? to]) {
    var left = Edge_.from.equals(from) & Edge_.name.equals(name);
    if (to != null) {
      left = left & Edge_.to.equals(to);
    }
    var right = Edge_.to.equals(from) & Edge_.inverseName.equals(name);
    if (to != null) {
      right = right & Edge_.from.equals(to);
    }
    return left | right;
  }

  void _saveOperations(Store store, List<_EdgeOperation> operations) {
    final box = store.box<Edge>();
    for (final op in operations) {
      switch (op) {
        case final AddEdgeOperation op:
          box.put(Edge(
              from: op.from,
              name: op.name,
              to: op.to,
              inverseName: op.inverseName));
        case final UpdateEdgeOperation op:
          final e = box
              .query(_queryConditionTo(op.from, op.name, op.to))
              .build()
              .findFirst();
          if (e != null) {
            box.put(Edge(id: e.id, from: e.from, name: e.name, to: op.newTo),
                mode: PutMode.update);
          }
        case final RemoveEdgeOperation op:
          box
              .query(_queryConditionTo(op.from, op.name, op.to))
              .build()
              .remove();
      }
    }
  }

  void save({bool notify = true}) {
    if (_edgeOperations.isEmpty) return;

    final operations = _edgeOperations;
    _core._writeTxn(() => _saveOperations(_core.store, operations));

    // notify
    final additions =
        _edgeOperations.whereType<AddEdgeOperation>().map((op) => op.to);
    final updates =
        _edgeOperations.whereType<UpdateEdgeOperation>().map((op) => op.to);
    final removals =
        _edgeOperations.whereType<RemoveEdgeOperation>().map((op) => op.to);

    if (notify) {
      if (additions.isNotEmpty) {
        _core._notify(
          [ownerKey, ...additions],
          metadata: _name,
          type: DataGraphEventType.addEdge,
        );
      }
      if (updates.isNotEmpty) {
        _core._notify(
          [ownerKey, ...updates],
          metadata: _name,
          type: DataGraphEventType.updateEdge,
        );
      }
      // We can safely ignore null removals, because they are always
      // followed by additions, which notify
      if (removals.isNotEmpty) {
        _core._notify(
          [ownerKey, ...removals.nonNulls],
          metadata: _name,
          type: DataGraphEventType.removeEdge,
        );
      }
    }

    // clear and return
    _edgeOperations.clear();
  }

  // implement collection-like methods

  bool _add(E value, {bool save = false}) {
    _edgeOperations
        .add(AddEdgeOperation(ownerKey, name, value._key!, inverseName));
    if (save) {
      this.save();
      value.save();
      return true;
    }
    return false;
  }

  bool _contains(E? element) {
    return _iterable.contains(element);
  }

  bool _update(E value, E newValue, {bool save = false}) {
    _edgeOperations
        .add(UpdateEdgeOperation(ownerKey, name, value._key!, newValue._key!));
    if (save) {
      this.save();
      return true;
    }
    return false;
  }

  bool _remove(E value, {bool save = false}) {
    _edgeOperations.add(RemoveEdgeOperation(ownerKey, name, value._key!));
    if (save) {
      this.save();
      return true;
    }
    return false;
  }

  // TODO docs + tests
  Iterable<Relationship>
      adjacentRelationships<R extends DataModelMixin<R>>() sync* {
    for (final key in _keys) {
      final metas = _adapter.localAdapter.relationshipMetas.values
          .whereType<RelationshipMeta<R>>();
      for (final meta in metas) {
        final rel = switch (meta.type) {
          'HasMany' => HasMany<R>().initialize(ownerKey: key, name: meta.name),
          _ => BelongsTo<R>().initialize(ownerKey: key, name: meta.name),
        };
        yield rel;
      }
    }
  }

  // support methods

  /// Returns keys in this relationship.
  Set<String> get keys => _keys;

  /// Returns IDs in this relationship.
  Set<Object> get ids => _ids;

  Iterable<E> get _iterable {
    return _adapter.localAdapter.findMany(_keys);
  }

  Set<String> _keysFor(String key, String name) {
    print('--- [read] _keysFor');
    final persistedEdges = _core.store
        .box<Edge>()
        .query(_queryConditionTo(key, name))
        .build()
        .find();
    return {for (final e in persistedEdges) e.from == key ? e.to : e.from};
  }

  Set<String> get _keys {
    if (_ownerKey == null) return {};
    return _keysFor(ownerKey, _name!);
  }

  Set<Object> get _ids {
    return _core._readTxn(() {
      return _keys.map((key) => _core.getIdForKey(key)).nonNulls.toSet();
    });
  }

  DelayedStateNotifier<DataGraphEvent> get _relationshipEventNotifier {
    return _adapter.core.where((event) {
      return event.type.isEdge &&
          event.metadata == _name &&
          event.keys.containsFirst(ownerKey);
    });
  }

  DelayedStateNotifier<N> watch();

  /// This is used to make `json_serializable`'s `explicitToJson` transparent.
  ///
  /// For internal use. Does not return valid JSON.
  dynamic toJson() => this;

  int get length {
    return _core._readTxn(() =>
        _keys.map(_adapter.localAdapter.exists).where((e) => e == true).length);
  }

  /// Whether the relationship has a value.
  bool get isPresent => length > 0;

  @override
  List<Object?> get props => [_ownerKey, _name, _inverseName];

  @override
  String toString() {
    return {..._keys}.join(', ');
  }
}

// annotation

class DataRelationship {
  final String? inverse;
  final bool serialize;
  const DataRelationship({this.inverse, this.serialize = true});
}
