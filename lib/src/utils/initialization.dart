part of flutter_data;

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn,
    List<int>? encryptionKey,
    LocalStorageClearStrategy? clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool? remote, int logLevel});

class RepositoryInitializer {}

@protected
mixin NothingMixin {}
