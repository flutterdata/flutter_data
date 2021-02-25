part of flutter_data;

extension IterableX<T> on Iterable<T> {
  @protected
  @visibleForTesting
  T get safeFirst => (this != null && isNotEmpty) ? first : null;
  @protected
  @visibleForTesting
  bool containsFirst(T model) => safeFirst == model;
  @protected
  @visibleForTesting
  Iterable<T> get filterNulls =>
      this == null ? null : where((elem) => elem != null);
  @protected
  @visibleForTesting
  List<T> toImmutableList() => this == null ? null : List.unmodifiable(this);
}

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  String decapitalize() =>
      isEmpty ? '' : '${this[0].toLowerCase()}${substring(1)}';
  String pluralize() => inflection.pluralize(this);
  String singularize() => inflection.singularize(this);
  Uri get asUri => Uri.parse(this);
}

extension MapUtilsX<K, V> on Map<K, V> {
  @protected
  @visibleForTesting
  Map<K, V> operator &(Map<K, V> more) => {...this, ...?more};

  @protected
  @visibleForTesting
  Map<K, V> get filterNulls => {
        for (final e in entries)
          if (e.value != null) e.key: e.value
      };
}

extension UriUtilsX on Uri {
  Uri operator /(String path) {
    if (path == null) return this;
    return replace(path: path_helper.normalize('/${this.path}/$path'));
  }

  Uri operator &(Map<String, dynamic> params) => params != null &&
          params.isNotEmpty
      ? replace(
          queryParameters: queryParameters & _flattenQueryParameters(params))
      : this;
}

Map<String, String> _flattenQueryParameters(Map<String, dynamic> params) {
  params ??= const {};

  return params.entries.fold<Map<String, String>>({}, (acc, e) {
    if (e.value is Map<String, dynamic>) {
      for (final e2 in (e.value as Map<String, dynamic>).entries) {
        acc['${e.key}[${e2.key}]'] = e2.value.toString();
      }
    } else {
      acc[e.key] = e.value.toString();
    }
    return acc;
  });
}
