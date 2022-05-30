part of flutter_data;

/// A [Relationship] that models a to-many ownership.
///
/// Example: An author who has many books
/// ```
/// class Author with DataModel<Author> {
///  @override
///  final int id;
///  final String name;
///  final HasMany<Book> books;
///
///  Todo({this.id, this.name, this.books});
/// }
///```
class HasMany<E extends DataModel<E>> extends Relationship<E, Set<E>> {
  /// Creates a [HasMany] relationship, with an optional initial [Set<E>].
  ///
  /// Example:
  /// ```
  /// final book = Book(title: 'Harry Potter');
  /// final author = Author(id: 1, name: 'JK Rowling', books: HasMany({book}));
  /// ```
  ///
  /// See also: [IterableRelationshipExtension<E>.asHasMany]
  HasMany([Set<E>? models]) : super(models);

  HasMany._(Set<int>? keys) : super._(keys);

  HasMany.remove() : super._remove();

  /// For internal use with `json_serializable`.
  factory HasMany.fromJson(final Map<String, dynamic> map) {
    if (map['_'] == null) return HasMany._(null);
    return HasMany._({...map['_']});
  }

  @override
  IsarLinkBase<E> link = IsarLinks();

  IsarLinks<E> get _links {
    print(
        'link (${link.hashCode}) in hasmany, owner $_ownerKey rel hashcode $hashCode');
    return link as IsarLinks<E>;
  }

  /// Add a [value] to this [Relationship]
  ///
  /// Attempting to add an existing [value] has no effect as this is a [Set]
  bool add(E value, {bool notify = true}) {
    final wasAdded = _links.add(value);

    if (wasAdded && notify) {
      _graph._notify(
        [_ownerKey!, value._key],
        metadata: _name,
        type: DataGraphEventType.addEdge,
      );
    }
    return wasAdded;
  }

  /// Removes a [value] from this [Relationship]
  bool remove(E? value, {bool notify = true}) {
    if (value == null) return false;
    final wasRemoved = _links.remove(value);

    if (wasRemoved && notify) {
      _graph._notify(
        [_ownerKey!, value._key],
        metadata: _name,
        type: DataGraphEventType.removeEdge,
      );
    }

    return wasRemoved;
  }

  /// Returns keys in this relationship.
  Set<int> get keys {
    if (!isInitialized) return {};
    // if (!_links.isLoaded) _links.loadSync();
    // print(
    //     'links $this [owner $_ownerKey] ($hashCode) after loadSync ${_links.toSet()}');
    return {for (final e in _links) e.__key!};
  }

  /// Returns IDs in this relationship.
  Set<Object> get ids =>
      {for (final key in keys) key.typifyWith(_internalType)};

  @override
  bool get isPresent => _links.isNotEmpty;

  // iterable utils

  bool contains(E value) => _links.contains(value);

  Set<E> toSet() => _links;

  List<E> toList() => _links.toList();

  int get length => _links.length;

  E get first => _links.first;

  bool get isEmpty => _links.isEmpty;

  bool get isNotEmpty => _links.isNotEmpty;

  Iterable<E> where(bool Function(E) test) => _links.where(test);

  Iterable<T> map<T>(T Function(E) f) => _links.map(f);

  @override
  String toString() => 'HasMany<$E>(${super.toString()})';
}

extension IterableRelationshipExtension<T extends DataModel<T>> on Set<T> {
  /// Converts a [Set<T>] into a [HasMany<T>].
  ///
  /// Equivalent to using the constructor as `HasMany(set)`.
  HasMany<T> get asHasMany => HasMany<T>(this);
}
