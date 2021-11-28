part of flutter_data;

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn, List<int>? encryptionKey, bool? clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool? remote, bool? verbose});

/// ONLY FOR FLUTTER DATA INTERNAL USE
var internalLocatorFn =
    <S extends DataModel<S>>(Provider<Repository<S>> provider, Reader reader) =>
        reader(provider);

class RepositoryInitializer {}

class RepositoryInitializerArgs with EquatableMixin {
  RepositoryInitializerArgs(this.remote, this.verbose);

  final bool? remote;
  final bool? verbose;

  @override
  List<Object?> get props => [remote, verbose];
}

@protected
mixin NothingMixin {}

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T> with EquatableMixin {
  WatchArgs({
    this.id,
    this.remote,
    this.params,
    this.headers,
    this.syncLocal,
    this.filterLocal,
    this.alsoWatch,
  });

  final Object? id;
  final bool? remote;
  final Map<String, dynamic>? params;
  final Map<String, String>? headers;
  final bool? syncLocal;
  final bool Function(T)? filterLocal;
  final AlsoWatch<T>? alsoWatch;

  @override
  List<Object?> get props => [id, remote, params, headers];
}
