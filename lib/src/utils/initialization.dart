part of flutter_data;

// TODO remove this and just pass a localStorageProvider.overrideWith()

typedef ConfigureAdapterLocalStorage = Override Function(
    {FutureFn<String>? baseDirFn,
    String? encryptionKey,
    LocalStorageClearStrategy? clear});

typedef AdapterInitializerProvider = FutureProvider<AdapterInitializer>
    Function({bool? remote, int logLevel});

class AdapterInitializer {}

@protected
mixin NothingMixin {}
