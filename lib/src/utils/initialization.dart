part of flutter_data;

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn,
    String? encryptionKey,
    LocalStorageClearStrategy? clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool? remote, int logLevel});

class RepositoryInitializer {}

@protected
mixin NothingMixin {}
