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
    // type will always be first in split
    final [type, ..._] = ownerKey.split('#');

    final adapter = _internalAdapters![type]!;
    return adapter.findOneLocal(ownerKey) as DataModelMixin?;
  }

  String get name => _name!;
  String? get inverseName => _inverseName;

  Adapter<E> get _adapter => _internalAdapters![_internalType] as Adapter<E>;

  Set<String>? _uninitializedKeys;
  String get _internalType => DataHelpers.internalTypeFor(E.toString());

  Database get db => _adapter.storage.db;

  /// Initializes this relationship (typically when initializing the owner
  /// in [DataModelMixin]) by supplying the owner, and related metadata.
  @protected
  Relationship<E, N> initialize(
      {required final String ownerKey,
      required final String name,
      final String? inverseName}) {
    // If the relationship owner key is same as previous, return
    if (_ownerKey != null && _ownerKey == ownerKey) return this;

    _ownerKey = ownerKey;
    _name = name;
    _inverseName = inverseName;

    if (_uninitializedKeys == null) {
      return this;
    }

    // setting up from scratch, remove all and add keys

    db.execute(
        'DELETE FROM _edges WHERE (src = ? AND name = ?) OR (dest = ? AND inverse = ?)',
        [_ownerKey!, _name!, _ownerKey!, _name!]);

    final ps = db.prepare(
        'INSERT INTO _edges (src, name, dest, inverse) VALUES (?, ?, ?, ?)');

    for (final key in _uninitializedKeys!) {
      ps.execute([_ownerKey!, _name, key, _inverseName]);
    }
    ps.dispose();

    _uninitializedKeys!.clear();

    return this;
  }

  // implement collection-like methods

  void _addAll(Iterable<E> values) {
    final ps = db.prepare(
        'REPLACE INTO _edges (src, name, dest, inverse) VALUES (?, ?, ?, ?)');
    final additions = [];
    for (final value in values) {
      ps.execute([ownerKey, name, value._key!, inverseName]);
      additions.add(value._key!);
    }
    ps.dispose();

    _adapter.core._notify(
      [ownerKey, ...additions],
      metadata: _name,
      type: DataGraphEventType.addEdge,
    );
  }

  bool _contains(E? element) {
    return _iterable.contains(element);
  }

  bool _update(E value, E newValue) {
    db.execute(
        'UPDATE _edges SET dest = ? WHERE src = ? AND name = ? AND dest = ?',
        [newValue._key!, ownerKey, name, value._key!]);
    _adapter.core._notify(
      [ownerKey, newValue._key!],
      metadata: _name,
      type: DataGraphEventType.updateEdge,
    );
    return true;
  }

  bool _remove(E value) {
    db.execute('DELETE FROM _edges WHERE src = ? AND name = ? AND dest = ?',
        [ownerKey, name, value._key!]);
    _adapter.core._notify(
      [ownerKey, value._key!],
      metadata: _name,
      type: DataGraphEventType.removeEdge,
    );
    return true;
  }

  Iterable<Relationship>
      adjacentRelationships<R extends DataModelMixin<R>>() sync* {
    for (final key in _keys) {
      final metas =
          _adapter.relationshipMetas.values.whereType<RelationshipMeta<R>>();
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

  Iterable<E> get _iterable {
    return _adapter.findManyLocal(_keys);
  }

  Set<String> _keysFor(String key, String name) {
    final result = _adapter.storage.db.select(
        'SELECT src, dest FROM _edges WHERE (src = ? AND name = ?) OR (dest = ? AND inverse = ?)',
        [key, name, key, name]);
    // final edges = _adapter.storage.edgesFor([(key, name)]);
    return {for (final r in result) r['src'] == key ? r['dest'] : r['src']};
  }

  Set<String> get _keys {
    if (_ownerKey == null) return {};
    return _keysFor(ownerKey, _name!);
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
    return _keys.map(_adapter.exists).where((e) => e == true).length;
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
