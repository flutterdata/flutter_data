// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';

import 'package:jsonplaceholder_example/models/task.dart';
import 'package:jsonplaceholder_example/models/user.dart';

// ignore: prefer_function_declarations_over_variables
ConfigureRepositoryLocalStorage configureRepositoryLocalStorage =
    ({FutureFn<String>? baseDirFn, List<int>? encryptionKey, bool? clear}) {
  return isarLocalStorageProvider
      .overrideWithProvider(Provider((ref) => IsarLocalStorage(
            baseDirFn: baseDirFn,
            clear: clear,
          )));
};

final repositoryProviders = <String, Provider<Repository<DataModel>>>{
  'tasks': tasksRepositoryProvider,
  'users': usersRepositoryProvider
};

final repositoryInitializerProvider =
    FutureProvider<RepositoryInitializer>((ref) async {
  final adapters = <String, RemoteAdapter>{
    'tasks': ref.watch(internalTasksRemoteAdapterProvider),
    'users': ref.watch(internalUsersRemoteAdapterProvider)
  };
  final remotes = <String, bool>{'tasks': true, 'users': true};

  // await ref.watch(graphNotifierProvider).initialize();

  final _repoMap = {
    for (final type in repositoryProviders.keys)
      type: ref.watch(repositoryProviders[type]!)
  };

  for (final type in _repoMap.keys) {
    final repository = _repoMap[type]!;
    internalRepositories[type] = repository;
    repository.dispose();
    await repository.initialize(
      remote: remotes[type],
      adapters: adapters,
    );
  }

  ref.onDispose(() {
    for (final repository in _repoMap.values) {
      repository.dispose();
    }
  });

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
