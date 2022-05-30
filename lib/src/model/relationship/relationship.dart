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

  @protected
  IsarLinkBase<E> get link;

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

    // print(
    //     'initializing rel of owner type ${owner._internalType} with $_ownerKey , $_name hashcode $hashCode - $this (and uninit $_uninitializedKeys)');

    //

    final a = (_adapter.localAdapter as IsarLocalAdapter<E>);
    final ownerAdapter = owner.remoteAdapter.localAdapter as IsarLocalAdapter;
    // ignore: invalid_use_of_protected_member
    link.attach(ownerAdapter._collection, a._collection, _name!, owner.__key);
    link.loadSync();
    if (link is IsarLinks) {
      print('loaded for $_ownerKey, $_name and link is $link');
      // for (final e in link as IsarLinks<E>) {
      //   (this as HasMany).add(e);
      // }
    }

    // means it was omitted (remote-omitted, or loaded locally), so skip
    if (_uninitializedKeys == null) return this;

    // print(
    //     'initializing with $_uninitializedKeys of $E and attached? ${(link as IsarLinkBaseImpl).isAttached}');

    final models =
        a._collection.getAllSync(_uninitializedKeys!.toList()).cast<E>();

    a._collection.isar.writeTxnSync(() {
      // print(
      //     'adding $models to link ${link.hashCode} in rel hashcode $hashCode [owner $_ownerKey]');

      // (link as IsarLinksCommon).updateSync(link: models);

      // print(
      //     'before saving: link loaded? ${link.isLoaded} - changed> ${link.isChanged}');
      if (link is IsarLinks) {
        (link as IsarLinks).addAll(models);
      }
      if (link is IsarLink) {
        (link as IsarLink).value = models.first;
      }
      link.saveSync();
      link.loadSync();

      // (link as IsarLinkBaseImpl)
      //     .updateIdsInternalSync([..._uninitializedKeys!], [], true);

      // print(
      //     'done saving: link loaded? ${link.isLoaded} - changed> ${link.isChanged}');
    });

    _graph._notify(
      [
        _ownerKey!,
        ..._uninitializedKeys!.map((e) => e.typifyWith(_internalType)),
      ],
      type: DataGraphEventType.addEdge, // or update?
      metadata: _name!,
    );
    _uninitializedKeys!.clear();

    return this;
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
    // final keysWithoutId =
    //     _keys.where((k) => _graph.getIdForKey(k) == null).map((k) => '[$k]');
    // return '${{..._ids, ...keysWithoutId}.join(', ')}';
    return '';
  }
}

// annotation

class DataRelationship {
  final String? inverse;
  final bool serialize;
  const DataRelationship({this.inverse, this.serialize = true});
}
