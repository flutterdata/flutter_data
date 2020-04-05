part of flutter_data;

// typedefs

typedef OnResponseSuccess<R> = R Function(dynamic);

typedef OnRequest<R> = Future<R> Function(http.Client);

// member extensions

extension MapIdExtension on Map {
  String get id => this['id'].toString();
}

extension IterableRelationshipExtension<T extends DataSupport<T>> on List<T> {
  HasMany<T> get asHasMany => HasMany<T>(this);
}

extension DataSupportRelationshipExtension<T extends DataSupport<T>>
    on DataSupport<T> {
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}
