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
  CoreNotifier get _graph => _adapter.localAdapter.graph;

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

    _edgeOperations.add(_RemoveAllEdgeOperation());
    _edgeOperations
        .addAll(_uninitializedKeys!.map((key) => _AddEdgeOperation(key)));
    _uninitializedKeys!.clear();

    return this;
  }

  Edge _createEdgeTo(String to) =>
      Edge(id: 0, from: ownerKey, name: name, to: to, inverseName: inverseName);

  Query<Edge> _queryTo(String to) => _graph._edgeBox
      .query((Edge_.from.equals(ownerKey) &
              Edge_.name.equals(name) &
              Edge_.to.equals(to)) |
          (Edge_.to.equals(ownerKey) &
              Edge_.inverseName.equals(name) &
              Edge_.from.equals(to)))
      .build();

  void save({bool notify = true}) {
    if (_edgeOperations.isEmpty) return;

    _graph._store.runInTransaction(TxMode.write, () {
      for (final op in _edgeOperations) {
        switch (op) {
          case final _AddEdgeOperation add:
            _graph._edgeBox.put(_createEdgeTo(add.to));
          case final _UpdateEdgeOperation update:
            final e = _queryTo(update.to).findFirst();
            if (e != null) {
              _graph._edgeBox.put(
                  Edge(id: e.id, from: e.from, name: e.name, to: update.newTo));
            }
          case final _RemoveEdgeOperation remove:
            _queryTo(remove.to).remove();
          case final _RemoveAllEdgeOperation _:
            _getPersistedEdgesQuery(ownerKey, _name!).remove();
        }
      }
    });

    // notify
    final additions =
        _edgeOperations.whereType<_AddEdgeOperation>().map((op) => op.to);
    final updates =
        _edgeOperations.whereType<_UpdateEdgeOperation>().map((op) => op.to);
    final removals =
        _edgeOperations.whereType<_RemoveEdgeOperation>().map((op) => op.to);

    if (notify) {
      if (additions.isNotEmpty) {
        // print('notifying additions $additions');
        _graph._notify(
          [ownerKey, ...additions],
          metadata: _name,
          type: DataGraphEventType.addEdge,
        );
      }
      if (updates.isNotEmpty) {
        // print('notifying updates $updates');
        _graph._notify(
          [ownerKey, ...updates],
          metadata: _name,
          type: DataGraphEventType.updateEdge,
        );
      }
      if (removals.isNotEmpty) {
        // print('notifying removals $removals');
        _graph._notify(
          [ownerKey, ...removals],
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
    _edgeOperations.add(_AddEdgeOperation(value._key!));
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
    _edgeOperations.add(_UpdateEdgeOperation(value._key!, newValue._key!));
    if (save) {
      this.save();
      return true;
    }
    return false;
  }

  bool _remove(E value, {bool save = false}) {
    _edgeOperations.add(_RemoveEdgeOperation(value._key!));
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

  Query<Edge> _getPersistedEdgesQuery(String key, String name) {
    return _graph._edgeBox
        .query((Edge_.from.equals(key) & Edge_.name.equals(name)) |
            (Edge_.to.equals(key) & Edge_.inverseName.equals(name)))
        .build();
  }

  Set<String> _keysFor(String key, String name) {
    final persistedEdges = _getPersistedEdgesQuery(key, name).find();
    return {for (final e in persistedEdges) e.from == key ? e.to : e.from};
  }

  Set<String> get _keys {
    if (_ownerKey == null) return {};
    return _keysFor(ownerKey, _name!);
  }

  Set<Object> get _ids {
    return _graph._store.runInTransaction(TxMode.read, () {
      return _keys.map((key) => _graph.getIdForKey(key)).nonNulls.toSet();
    });
  }

  DelayedStateNotifier<DataGraphEvent> get _relationshipEventNotifier {
    return _adapter.graph.where((event) {
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
    return {..._keys}.join(', ');
  }
}

// annotation

class DataRelationship {
  final String? inverse;
  final bool serialize;
  const DataRelationship({this.inverse, this.serialize = true});
}

// operations

sealed class _EdgeOperation {}

class _AddEdgeOperation extends _EdgeOperation {
  final String to;
  _AddEdgeOperation(this.to);
}

class _RemoveEdgeOperation extends _EdgeOperation {
  final String to;
  _RemoveEdgeOperation(this.to);
}

class _UpdateEdgeOperation extends _EdgeOperation {
  final String to;
  final String newTo;
  _UpdateEdgeOperation(this.to, this.newTo);
}

class _RemoveAllEdgeOperation extends _EdgeOperation {}
