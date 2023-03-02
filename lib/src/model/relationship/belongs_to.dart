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
  E? get value => _iterable.isNotEmpty ? _iterable.first : null;

  /// Sets the single [E] value of this relationship, replacing any previous [value].
  ///
  /// Passing in `null` will remove the existing value from the relationship.
  set value(E? newValue) {
    final isAddition = value == null && newValue != null;
    final isUpdate = value != null && newValue != null;
    final isRemoval = value != null && newValue == null;

    if (isRemoval || isUpdate) {
      super._remove(value!, notify: false);
    }
    if (isAddition || isUpdate) {
      super._add(newValue, notify: false);
    }

    // handle events
    DataGraphEventType? eventType;
    if (isAddition) eventType = DataGraphEventType.addEdge;
    if (isUpdate) eventType = DataGraphEventType.updateEdge;
    if (isRemoval) eventType = DataGraphEventType.removeEdge;

    if (eventType != null) {
      _graph._notify(
        [_ownerKey!, if (newValue != null) newValue._key!],
        metadata: _name,
        type: eventType,
      );
    }
    assert(_iterable.length <= 1);
  }

  /// Returns the [value]'s `key`.
  String? get key => super._keys.safeFirst;

  /// Returns the [value]'s `id`.
  Object? get id => super._ids.safeFirst;

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

  @override
  String toString() {
    return 'BelongsTo<$E>(${super.toString()})';
  }
}

extension DataModelRelationshipExtension<T extends DataModel<T>>
    on DataModel<T> {
  /// Converts a [DataModel<T>] into a [BelongsTo<T>].
  ///
  /// Equivalent to using the constructor as `BelongsTo(model)`.
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}
