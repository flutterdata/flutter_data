

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block, depend_on_referenced_packages

import 'package:flutter_data/flutter_data.dart';




import 'package:jsonplaceholder_example/models/task.dart';
import 'package:jsonplaceholder_example/models/user.dart';

// ignore: prefer_function_declarations_over_variables
ConfigureAdapterLocalStorage configureAdapterLocalStorage = ({FutureFn<String>? baseDirFn, String? encryptionKey, LocalStorageClearStrategy? clear}) {
  
    
  
  
  
  
  return localStorageProvider.overrideWith(
    (ref) => LocalStorage(
      baseDirFn: baseDirFn,
      encryptionKey: encryptionKey,
      clear: clear,
    ),
  );
};

final adapterProviders = <String, Provider<Adapter<DataModelMixin>>>{
  'tasks': tasksAdapterProvider,
'users': usersAdapterProvider
};

final adapterInitializerProvider =
  FutureProvider<AdapterInitializer>((ref) async {
    DataHelpers.setInternalType<Task>('tasks');
    DataHelpers.setInternalType<User>('users');
    final adapters = <String, Adapter>{'tasks': ref.watch(tasksAdapterProvider), 'users': ref.watch(usersAdapterProvider)};
    final remotes = <String, bool>{'tasks': true, 'users': true};

    await ref.read(localStorageProvider).initialize();

    // initialize and register
    for (final type in adapterProviders.keys) {
      final adapter = ref.read(adapterProviders[type]!);
      adapter.dispose();
      await adapter.initialize(
        remote: remotes[type],
        adapters: adapters,
        ref: ref
      );
      internalAdapters[type] = adapter;
    }

    return AdapterInitializer();
});


extension AdapterRefX on ProviderContainer {
E watch<E>(ProviderListenable<E> provider) {
  return readProviderElement(provider as ProviderBase<E>).readSelf();
}

  Adapter<Task> get tasks => watch(tasksAdapterProvider)..internalWatch = watch;
  Adapter<User> get users => watch(usersAdapterProvider)..internalWatch = watch;
}