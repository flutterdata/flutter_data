/// A collection of elements (e.g. resources) returned by the server.
class Collection<T> {
  final Iterable<T> elements;

  /// Total count of the elements on the server. May be null.
  final int totalCount;

  Collection(this.elements, [this.totalCount]);
}
