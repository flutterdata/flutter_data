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

  HasMany._(Iterable<String> keys, bool _wasOmitted)
      : super._(keys, _wasOmitted);

  HasMany.remove() : super._remove();

  /// For internal use with `json_serializable`.
  factory HasMany.fromJson(final Map<String, dynamic> map) {
    if (map['_'][0] == null) {
      final wasOmitted = map['_'][1] as bool;
      return HasMany._({}, wasOmitted);
    }
    final keys = <String>{...map['_'][0]};
    return HasMany._(keys, false);
  }

  /// Returns a [StateNotifier] which emits the latest [Set<E>] representing
  /// this [HasMany] relationship.
  @override
  DelayedStateNotifier<Set<E>> watch() {
    return _graphEvents.where((e) => e.isNotEmpty).map((e) => toSet());
  }

  @override
  String toString() => 'HasMany<$E>(${ids.join(', ')})';
}

extension IterableRelationshipExtension<T extends DataModel<T>> on Set<T> {
  /// Converts a [Set<T>] into a [HasMany<T>].
  ///
  /// Equivalent to using the constructor as `HasMany(set)`.
  HasMany<T> get asHasMany => HasMany<T>(this);
}
