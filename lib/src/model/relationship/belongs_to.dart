part of flutter_data;

/// A [Relationship] that models a to-one ownership.
///
/// Example: A book that belongs to an author
/// ```
/// class Book with DataModel<Book> {
///  @override
///  final int id;
///  final String title;
///  final BelongsTo<Author> author;
///
///  Todo({this.id, this.title, this.author});
/// }
///```
class BelongsTo<E extends DataModel<E>> extends Relationship<E, E?> {
  /// Creates a [BelongsTo] relationship, with an optional initial [E] model.
  ///
  /// Example:
  /// ```
  /// final author = Author(name: 'JK Rowling');
  /// final book = Book(id: 1, author: BelongsTo(author));
  /// ```
  ///
  /// See also: [DataModelRelationshipExtension<E>.asBelongsTo]
  BelongsTo([E? model]) : super(model != null ? {model} : null);

  BelongsTo._(Set<String>? keys) : super._(keys);

  BelongsTo.remove() : super._remove();

  /// For internal use with `json_serializable`.
  factory BelongsTo.fromJson(final Map<String, dynamic> map) {
    if (map['_'] == null) return BelongsTo._(null);
    return BelongsTo._({...map['_']});
  }

  /// Obtains the single [E] value of this relationship (`null` if not present).
  E? get value => isNotEmpty ? first : null;

  /// Sets the single [E] value of this relationship, replacing any previous [value].
  ///
  /// Passing in `null` will remove the existing value from the relationship.
  set value(E? newValue) {
    final isAddition = value == null && newValue != null;
    final isUpdate = value != null && newValue != null;
    final isRemoval = value != null && newValue == null;

    if (isRemoval || isUpdate) {
      super.remove(value!, notify: false);
    }
    if (isAddition || isUpdate) {
      super.add(newValue!, notify: false);
    }

    // handle events
    DataGraphEventType? eventType;
    if (isAddition) eventType = DataGraphEventType.addEdge;
    if (isUpdate) eventType = DataGraphEventType.updateEdge;
    if (isRemoval) eventType = DataGraphEventType.removeEdge;

    if (eventType != null) {
      _graph._notify(
        [_ownerKey!, if (newValue != null) newValue._key],
        metadata: _name,
        type: eventType,
      );
    }
    assert(length <= 1);
  }

  /// Returns the [value]'s `key`
  @protected
  @visibleForTesting
  String? get key => super.keys.safeFirst;

  String? get id => super.ids.safeFirst;

  @override
  Relationship<E, E?> initialize(
      {required final DataModel owner,
      required final String name,
      final String? inverseName}) {
    final _this =
        super.initialize(owner: owner, name: name, inverseName: inverseName);
    if (inverseName != null) {
      addInverse(inverseName, owner);
    }
    return _this;
  }

  /// Returns a [StateNotifier] which emits the latest [value] of
  /// this [BelongsTo] relationship.
  @override
  DelayedStateNotifier<E?> watch() {
    return _relationshipEventNotifier.map((e) {
      return [DataGraphEventType.removeNode, DataGraphEventType.removeEdge]
              .contains(e.type)
          ? null
          : value;
    });
  }

  void addInverse(String inverseName, DataModel model) {
    if (value != null) {
      final _rels = value!.remoteAdapter.localAdapter.relationshipsFor(value!);
      final inverseMetadata = _rels[inverseName];
      if (inverseMetadata?['instance'] != null) {
        final inverseRelationship =
            inverseMetadata!['instance'] as Relationship;
        inverseRelationship.add(model);
      }
    }
  }

  @override
  String toString() {
    return 'BelongsTo<$E>($id)';
  }
}

extension DataModelRelationshipExtension<T extends DataModel<T>>
    on DataModel<T> {
  /// Converts a [DataModel<T>] into a [BelongsTo<T>].
  ///
  /// Equivalent to using the constructor as `BelongsTo(model)`.
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}
