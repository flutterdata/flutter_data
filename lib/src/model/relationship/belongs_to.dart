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

  BelongsTo._(Set<int>? keys) : super._(keys);

  BelongsTo.remove() : super._remove();

  /// For internal use with `json_serializable`.
  factory BelongsTo.fromJson(final Map<String, dynamic> map) {
    if (map['_'] == null) return BelongsTo._(null);
    return BelongsTo._({...map['_']});
  }

  @override
  IsarLinkBase<E> link = IsarLink();

  IsarLink<E> get _link => link as IsarLink<E>;

  /// Obtains the single [E] value of this relationship (`null` if not present).
  E? get value => _link.value;

  /// Sets the single [E] value of this relationship, replacing any previous [value].
  ///
  /// Passing in `null` will remove the existing value from the relationship.
  set value(E? newValue) {
    final isAddition = value == null && newValue != null;
    final isUpdate = value != null && newValue != null;
    final isRemoval = value != null && newValue == null;

    if (isRemoval) {
      _link.value = null;
    }
    if (isAddition || isUpdate) {
      _link.value = newValue;
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
  }

  /// Returns the [value]'s `key`.
  int? get key {
    if (!isInitialized) return null;
    // if (!_link.isLoaded) _link.loadSync();
    return _link.value?.__key;
  }

  /// Returns the [value]'s `id`.
  Object? get id => key?.typifyWith(_internalType);

  @override
  bool get isPresent => _link.value != null;

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
