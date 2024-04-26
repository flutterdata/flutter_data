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

extension _DataModelListX on Iterable<DataModelMixin> {
  String toShortLog() {
    final ids = map((m) => m.id).toSet();
    return ids.isEmpty
        ? 'none'
        : (ids.length > 5
                ? '${ids.take(5).toSet()} (and ${ids.length - 5} more)'
                : ids)
            .toString();
  }
}

extension _ListX<T> on List<T> {
  T? getSafe(int index) => (length > index) ? this[index] : null;
}

extension DynamicX on dynamic {
  String typifyWith(String type) {
    final _this = this.toString();
    if (this == null || _this.isEmpty) {
      return type;
    }
    // If int use #, else use ##
    return '$type#${_this.isNotEmpty ? ('${this is! int ? '#' : ''}$_this') : ''}';
  }
}

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  String decapitalize() =>
      isEmpty ? '' : '${this[0].toLowerCase()}${substring(1)}';

  String pluralize() => inflection.pluralize(this);

  String singularize() => inflection.singularize(this);

  Uri get asUri => Uri.parse(this);

  String namespaceWith(String prefix) {
    assert(!prefix.contains(':'));
    return '$prefix:$this';
  }

  String? get namespace => split(':').safeFirst;

  String? get type => split('#').safeFirst;

  String denamespace() {
    // need to re-join with : in case there were other :s in the text
    return (split(':')..removeAt(0)).join(':');
  }

  /// Returns key as int
  int? detypifyKey() {
    final [_, key] = split('#');
    if (key.isEmpty) {
      // enters here if there is only a type, e.g. `people`
      return null;
    }
    return int.parse(key);
  }

  Object? detypify() {
    final [_, ...other] = split('#');
    if (other.isEmpty) {
      // enters here if there is only a type, e.g. `people`
      return null;
    }
    final [intId, ...rest] = other;
    if (intId.isEmpty) {
      // means it is a string id people##
      if (rest.isEmpty) {
        // means it has no assigned ID: people#
        return null;
      } else {
        // need to re-join with # in case there were other #s in the id
        return rest.join('#');
      }
    } else {
      // means it's an int: e.g people#1
      return int.parse(intId);
    }
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

extension _R2 on (String, String) {
  bool contains(String str) {
    return $1 == str || $2 == str;
  }

  bool unorderedEquals((String, String) record) {
    return $1 == record.$1 ||
        $1 == record.$2 ||
        $2 == record.$1 ||
        $2 == record.$2;
  }
}
