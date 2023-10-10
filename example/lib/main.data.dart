// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block, depend_on_referenced_packages

import 'package:flutter_data/flutter_data.dart';

import 'package:jsonplaceholder_example/models/task.dart';
import 'package:jsonplaceholder_example/models/user.dart';

// ignore: prefer_function_declarations_over_variables
ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = (
    {FutureFn<String>? baseDirFn,
    String? encryptionKey,
    LocalStorageClearStrategy? clear}) {
  return hiveLocalStorageProvider.overrideWith(
    (ref) => IsarLocalStorage(
      baseDirFn: baseDirFn,
      encryptionKey: encryptionKey,
      clear: clear,
    ),
  );
};

final repositoryProviders = <String, Provider<Repository<DataModelMixin>>>{
  'todos': tasksRepositoryProvider,
  'users': usersRepositoryProvider
};

final repositoryInitializerProvider =
    FutureProvider<RepositoryInitializer>((ref) async {
  DataHelpers.setInternalType<Task>('todos');
  DataHelpers.setInternalType<User>('users');
  final adapters = <String, RemoteAdapter>{
    'todos': ref.watch(internalTasksRemoteAdapterProvider),
    'users': ref.watch(internalUsersRemoteAdapterProvider)
  };
  final remotes = <String, bool>{'todos': true, 'users': true};

  await ref.watch(graphNotifierProvider).initialize();

  // initialize and register
  for (final type in repositoryProviders.keys) {
    final repository = ref.read(repositoryProviders[type]!);
    repository.dispose();
    await repository.initialize(
      remote: remotes[type],
      adapters: adapters,
    );
    internalRepositories[type] = repository;
  }

  return RepositoryInitializer();
});

extension RepositoryRefX on ProviderContainer {
  E watch<E>(ProviderListenable<E> provider) {
    return readProviderElement(provider as ProviderBase<E>).readSelf();
  }

  Repository<Task> get tasks =>
      watch(tasksRepositoryProvider)..remoteAdapter.internalWatch = watch;
  Repository<User> get users =>
      watch(usersRepositoryProvider)..remoteAdapter.internalWatch = watch;
}
