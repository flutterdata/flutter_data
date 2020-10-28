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

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T> with EquatableMixin {
  WatchArgs(
      {this.id,
      this.remote = true,
      this.params = const {},
      this.headers = const {},
      this.alsoWatch});

  final dynamic id;
  final bool remote;
  final Map<String, dynamic> params;
  final Map<String, String> headers;
  final AlsoWatch<T> alsoWatch;

  @override
  List<Object> get props => [id, remote, params, headers, alsoWatch];
}
