part of flutter_data;

typedef ConfigureRepositoryLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn, List<int>? encryptionKey, bool? clear});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer>
    Function({bool? remote, bool? verbose});

class RepositoryInitializer {}

@protected
mixin NothingMixin {}
