part of flutter_data;

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String> baseDirFn, List<int> encryptionKey, bool clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool remote, bool verbose});

typedef InternalLocator<T extends DataModel<T>> = Repository<T> Function(
    Provider<Repository<T>>, dynamic);

/// ONLY FOR FLUTTER DATA INTERNAL USE
InternalLocator internalLocatorFn =
    (provider, container) => (container as ProviderContainer).read(provider);

class RepositoryInitializer {}

extension RepositoryInitializerX on RepositoryInitializer {
  bool get isLoading => this == null;
}

class RepositoryInitializerArgs with EquatableMixin {
  RepositoryInitializerArgs(this.remote, this.verbose);

  final bool remote;
  final bool verbose;

  @override
  List<Object> get props => [remote, verbose];
}

@protected
mixin NothingMixin {}

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T> with EquatableMixin {
  WatchArgs(
      {this.id,
      this.remote = true,
      this.params = const {},
      this.headers = const {},
      this.filterLocal,
      this.syncLocal,
      this.alsoWatch});

  final dynamic id;
  final bool remote;
  final Map<String, dynamic> params;
  final Map<String, String> headers;
  final AlsoWatch<T> alsoWatch;
  final bool Function(T) filterLocal;
  final bool syncLocal;

  @override
  List<Object> get props => [id, remote, params, headers];
}
