part of flutter_data;

extension IterableX<T> on Iterable<T> {
  @protected
  @visibleForTesting
  T? get safeFirst => isNotEmpty ? first : null;
  @protected
  @visibleForTesting
  bool containsFirst(T model) => safeFirst == model;
  @protected
  @visibleForTesting
  List<T> toImmutableList() => List.unmodifiable(this);
}

extension IterableNullX<T> on Iterable<T?> {
  @protected
  @visibleForTesting
  Iterable<T> get filterNulls => where((elem) => elem != null).cast();
}

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  String decapitalize() =>
      isEmpty ? '' : '${this[0].toLowerCase()}${substring(1)}';

  String pluralize() => inflection.pluralize(this);

  String singularize() => inflection.singularize(this);

  Uri get asUri => Uri.parse(this);

  String denamespace() {
    // need to re-join with : in case there were other :s in the text
    return (split(':')..removeAt(0)).join(':');
  }

  String detypify() {
    // need to re-join with # in case there were other #s in the id
    return (split('#')..removeAt(0)).join('#');
  }
}

class StringUtils {
  @protected
  @visibleForTesting
  static String namespace(String prefix, String text) {
    assert(!prefix.contains(':'));
    return '$prefix:$text';
  }

  @protected
  @visibleForTesting
  static String typify(String type, Object id) {
    assert(!type.contains('#'));
    return '$type#$id';
  }
}

extension MapUtilsX<K, V> on Map<K, V> {
  @protected
  @visibleForTesting
  Map<K, V> operator &(Map<K, V>? more) => {...this, ...?more};

  @protected
  @visibleForTesting
  Map<K, V> get filterNulls => {
        for (final e in entries)
          if (e.value != null) e.key: e.value
      };
}

extension UriUtilsX on Uri {
  Uri operator /(String path) {
    return replace(path: path_helper.posix.normalize('/${this.path}/$path'));
  }

  Uri operator &(Map<String, dynamic> params) => params.isNotEmpty
      ? replace(
          queryParameters: queryParameters & _flattenQueryParameters(params))
      : this;
}

Map<String, String> _flattenQueryParameters(Map<String, dynamic> params) {
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
