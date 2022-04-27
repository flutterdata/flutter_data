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

@protected
mixin NothingMixin {}
