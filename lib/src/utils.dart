part of flutter_data;

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String type]) {
    if (T == dynamic && type == null) {
      return null;
    }
    return (type ?? T.toString()).toLowerCase().pluralize();
  }

  static String generateKey<T>([String type]) {
    type = getType<T>(type);
    if (type != null) {
      return '$type#${uuid.v1().substring(0, 8)}';
    }
    return null;
  }
}

// initialization helpers

typedef InternalLocator<T extends DataModel<T>> = Repository<T> Function(
    Provider<Repository<T>>, dynamic);

/// ONLY FOR FLUTTER DATA INTERNAL USE
InternalLocator internalLocatorFn =
    (provider, owner) => provider.readOwner(owner as ProviderStateOwner);

class RepositoryInitializer {}

extension RepositoryInitializerX on RepositoryInitializer {
  bool get isLoading => this == null;
}

class RepositoryInitializerArgs {
  RepositoryInitializerArgs(this.remote, this.verbose);

  final bool remote;
  final bool verbose;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is RepositoryInitializerArgs &&
            other.remote == remote &&
            other.verbose == verbose);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ remote.hashCode ^ verbose.hashCode;
}

@protected
mixin NothingMixin {}

typedef FutureFn<R> = FutureOr<R> Function();

typedef OnData<R> = FutureOr<R> Function(dynamic);

// private utilities

abstract class _Lifecycle<T> {
  bool _isInit = false;

  @mustCallSuper
  // ignore: missing_return
  FutureOr<T> initialize() async {
    _isInit = true;
  }

  @protected
  @visibleForTesting
  bool get isInitialized => _isInit;

  @mustCallSuper
  Future<void> dispose() async {}
}

// misc extensions

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
  Map<K, V> get filterNulls =>
      {for (final e in entries) if (e.value != null) e.key: e.value};
}

extension UriUtilsX on Uri {
  Uri operator /(String path) {
    if (path == null) return this;
    return replace(path: path_helper.canonicalize('/${this.path}/$path'));
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

// Riverpod type aliases, so we don't have to export it
// (except ProviderStateOwner for now)

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String> baseDirFn, List<int> encryptionKey, bool clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool remote, bool verbose});

class RiverpodAlias {
  static Provider<T> provider<T>(T Function(ProviderReference) create) =>
      Provider<T>(create);
  static FutureProviderFamily<T, A> futureProviderFamily<T, A>(
          Future<T> Function(ProviderReference, A) create) =>
      FutureProvider.family<T, A>(create);
}
