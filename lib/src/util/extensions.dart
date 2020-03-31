part of flutter_data;

// typedefs

typedef OnResponseSuccess<R> = R Function(PrimaryData);

typedef OnRequest<R> = Future<R> Function(http.Client);

// poor man typdefs

mixin _Nothing {}

class DataResourceObject = ResourceObject with _Nothing;

// member extensions

extension IterableRelationshipExtension<T extends DataSupport<T>> on List<T> {
  HasMany<T> get asHasMany => HasMany<T>(this);
}

extension DataSupportRelationshipExtension<T extends DataSupport<T>>
    on DataSupport<T> {
  BelongsTo<T> get asBelongsTo => BelongsTo<T>(this as T);
}
