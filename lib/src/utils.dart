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
  RepositoryInitializerArgs(this.remote, this.verbose, this.alsoAwait);

  final bool remote;
  final bool verbose;
  final FutureFn alsoAwait;

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is RepositoryInitializerArgs &&
            other.remote == remote &&
            other.verbose == verbose &&
            other.alsoAwait == alsoAwait);
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      remote.hashCode ^
      verbose.hashCode ^
      alsoAwait.hashCode;
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
}

extension _MapX<K, V> on Map<K, V> {
  Map<K, V> operator &(Map<K, V> more) => {...this, ...?more};
}
