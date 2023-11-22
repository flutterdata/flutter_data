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

extension DeleteAllX<T extends DataModelMixin<T>>
    on Iterable<DataModelMixin<T>> {
  void deleteAll() {
    if (isEmpty) return;

    final adapter =
        first._remoteAdapter.localAdapter as ObjectboxLocalAdapter<T>;
    final keys =
        map((e) => e._key != null ? adapter.graph.intKey(e._key!) : null)
            .filterNulls;
    adapter.store.box<StoredModel>().removeMany(keys.toList());
  }
}

extension IterableNullX<T> on Iterable<T?> {
  @protected
  @visibleForTesting
  Iterable<T> get filterNulls => where((elem) => elem != null).cast();
}

extension _ListX<T> on List<T> {
  T? getSafe(int index) => (length > index) ? this[index] : null;
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

  String typifyWith(String type, {bool isInt = false}) {
    // TODO do not assert, throw; also throw if id starts with #
    assert(!type.contains('#'));
    return '$type#${isNotEmpty ? ('${isInt ? '#' : ''}$this') : ''}';
  }

  String? get namespace => split(':').safeFirst;

  String? get type => split('#').safeFirst;

  String denamespace() {
    // need to re-join with : in case there were other :s in the text
    return (split(':')..removeAt(0)).join(':');
  }

  Object? detypify({forceInt = false}) {
    final [_, maybeId, ...rest] = split('#');
    if (forceInt) {
      return int.parse(maybeId);
    }
    if (maybeId.isEmpty) {
      if (rest.isEmpty) {
        // means it has no assigned ID: people#
        return null;
      }
      // means it's an int: e.g people##1
      return int.parse(rest.first);
    } else {
      // need to re-join with # in case there were other #s in the id
      return [maybeId, ...rest].join('#');
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
