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
class BelongsTo<E extends DataModelMixin<E>> extends Relationship<E, E?> {
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
  E? get value => _iterable.safeFirst;

  /// Sets the single [E] value of this relationship, replacing any previous [value].
  ///
  /// Passing in `null` will remove the existing value from the relationship.
  set value(E? newValue) {
    if (value == null && newValue != null) {
      // addition
      super._addAll([newValue]);
    }
    if (value != null && newValue != null) {
      // update
      super._update(value!, newValue);
    }
    if (value != null && newValue == null) {
      // removal
      super._remove(value!);
    }
  }

  /// Returns the [value]'s `key`.
  String? get key => super._keys.safeFirst;

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

extension DataModelRelationshipExtension<T extends DataModelMixin<T>>
    on DataModelMixin<T> {
  /// Converts a [DataModel<T>] into a [BelongsTo<T>].
  ///
  /// Equivalent to using the constructor as `BelongsTo(model)`.
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}
