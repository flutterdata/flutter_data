part of flutter_data;

// typedefs

typedef OnResponseSuccess<R> = R Function(dynamic);

typedef OnRequest<R> = Future<R> Function(http.Client);

// member extensions

extension MapIdExtension on Map {
  String get id => this['id'] != null ? this['id'].toString() : null;
}

@optionalTypeArgs
extension IterableRelationshipExtension<T extends DataSupportMixin<T>>
    on List<T> {
  HasMany<T> get asHasMany {
    if (this.isNotEmpty) {
      return HasMany<T>(this, this.first._manager);
    }
    return HasMany<T>();
  }
}

extension DataSupportMixinRelationshipExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  BelongsTo<T> get asBelongsTo {
    return BelongsTo<T>(this as T, this._manager);
  }
}
