part of flutter_data;

// TODO remove this and just pass a localStorageProvider.overrideWith()

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn,
    String? encryptionKey,
    LocalStorageClearStrategy? clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool? remote, int logLevel});

class RepositoryInitializer {}

@protected
mixin NothingMixin {}
