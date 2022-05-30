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

extension _DataModelListX on Iterable<DataModel> {
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

extension IterableNullX<T> on Iterable<T?> {
  @protected
  @visibleForTesting
  Iterable<T> get filterNulls => where((elem) => elem != null).cast();
}

extension IntUtilsX on int {
  String typifyWith(String type) {
    return toString().typifyWith(type);
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

  String typifyWith(String type) {
    assert(!type.contains('#'));
    if (isEmpty) {
      return type;
    }
    return '$type#$this';
  }

  String? get namespace => split(':').safeFirst;

  String? get type => split('#').safeFirst;

  String denamespace() {
    // need to re-join with : in case there were other :s in the text
    return (split(':')..removeAt(0)).join(':');
  }

  String detypify() {
    // need to re-join with # in case there were other #s in the id
    return (split('#')..removeAt(0)).join('#');
  }

  int _detypifyInt() {
    return int.tryParse(detypify())!;
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

extension FieldMetaX on Map<String, FieldMeta> {
  Map<String, AttributeMeta> get attributes {
    return {
      for (final e in entries)
        if (e.value is AttributeMeta) e.key: e.value as AttributeMeta,
    };
  }

  Map<String, RelationshipMeta> get relationships {
    return {
      for (final e in entries)
        if (e.value is RelationshipMeta) e.key: e.value as RelationshipMeta,
    };
  }
}
