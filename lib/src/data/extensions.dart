part of flutter_data;

// enums

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

// typedefs

typedef AlsoWatch<T> = List<Relationship> Function(T);

typedef OnResponseSuccess<R> = R Function(dynamic);

typedef OnRequest<R> = Future<R> Function(http.Client);

// member extensions

extension ToStringX on DataRequestMethod {
  String toShortString() {
    return toString().split('.').last;
  }
}

extension MapX<K, V> on Map<K, V> {
  String get id => this['id'] != null ? this['id'].toString() : null;
  Map<K, V> operator &(Map<K, V> more) => {...this, ...?more};
  Map<String, String> castToString() => Map<String, String>.fromEntries(
      entries.map((e) => MapEntry(e.key.toString(), e.value.toString())));
}

@optionalTypeArgs
extension IterableRelationshipExtension<T extends DataSupportMixin<T>>
    on Set<T> {
  HasMany<T> get asHasMany {
    if (isNotEmpty) {
      return HasMany<T>(this, first._manager, first._save);
    }
    return HasMany<T>();
  }
}

extension DataSupportMixinRelationshipExtension<T extends DataSupportMixin<T>>
    on DataSupportMixin<T> {
  BelongsTo<T> get asBelongsTo {
    return BelongsTo<T>(this as T, _manager, _save);
  }
}

extension ManagerDataId on DataManager {
  @optionalTypeArgs
  DataId<T> dataId<T>(dynamic id, {String useKey, String type}) =>
      DataId<T>(id, this, useKey: useKey, type: type);
}

extension SafeBoxX<T> on Box<T> {
  T safeGet(key) => key != null ? get(key) : null;
  Future<void> safeDelete(key) => key != null ? delete(key) : null;
}
