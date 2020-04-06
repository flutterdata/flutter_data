part of flutter_data;

// typedefs

typedef OnResponseSuccess<R> = R Function(dynamic);

typedef OnRequest<R> = Future<R> Function(http.Client);

// member extensions

extension MapIdExtension on Map {
  String get id => this['id'] != null ? this['id'].toString() : null;
}

extension IterableRelationshipExtension<T extends DataSupport<T>> on List<T> {
  HasMany<T> get asHasMany {
    if (this.isNotEmpty) {
      this.first._assertRepo('extension asHasMany');
    }
    return HasMany<T>(this);
  }
}

extension DataSupportRelationshipExtension<T extends DataSupport<T>>
    on DataSupport<T> {
  BelongsTo<T> get asBelongsTo {
    this._assertRepo('extension asBelongsTo');
    return BelongsTo<T>(this as T, this._manager);
  }
}
