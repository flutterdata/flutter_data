

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';



import 'package:get_it/get_it.dart';


import 'package:jsonplaceholder_example/models/post.dart';
import 'package:jsonplaceholder_example/models/user.dart';
import 'package:jsonplaceholder_example/models/comment.dart';

ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = ({FutureFn<String> baseDirFn, List<int> encryptionKey, bool clear}) {
  // ignore: unnecessary_statements
  baseDirFn;
  return hiveLocalStorageProvider.overrideWithProvider(Provider(
        (_) => HiveLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear)));
};

RepositoryInitializerProvider repositoryInitializerProvider = (
        {bool remote, bool verbose}) {
  
  return _repositoryInitializerProviderFamily(
      RepositoryInitializerArgs(remote, verbose));
};

final _repositoryInitializerProviderFamily =
  FutureProvider.family<RepositoryInitializer, RepositoryInitializerArgs>((ref, args) async {
    final graphs = <String, Map<String, RemoteAdapter>>{'comments,posts,users': {'comments': ref.read(commentRemoteAdapterProvider), 'posts': ref.read(postRemoteAdapterProvider), 'users': ref.read(userRemoteAdapterProvider)}};
    

      await ref.read(postRepositoryProvider).initialize(
        remote: args?.remote,
        verbose: args?.verbose,
        adapters: graphs['comments,posts,users'],
      );

      await ref.read(userRepositoryProvider).initialize(
        remote: args?.remote,
        verbose: args?.verbose,
        adapters: graphs['comments,posts,users'],
      );

      await ref.read(commentRepositoryProvider).initialize(
        remote: args?.remote,
        verbose: args?.verbose,
        adapters: graphs['comments,posts,users'],
      );

    ref.onDispose(() {
      if (ref.mounted) {
              ref.read(postRepositoryProvider).dispose();
      ref.read(userRepositoryProvider).dispose();
      ref.read(commentRepositoryProvider).dispose();

      }
    });

    return RepositoryInitializer();
});



extension GetItFlutterDataX on GetIt {
  void registerRepositories({FutureFn<String> baseDirFn, List<int> encryptionKey,
    bool clear, bool remote, bool verbose}) {
final i = GetIt.instance;

final _container = ProviderContainer(
  overrides: [
    configureRepositoryLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear),
  ],
);

if (i.isRegistered<RepositoryInitializer>()) {
  return;
}

i.registerSingletonAsync<RepositoryInitializer>(() async {
    final init = _container.read(repositoryInitializerProvider(remote: remote, verbose: verbose).future);
    internalLocatorFn = (provider, _) => _container.read(provider);
    return init;
  });  
i.registerSingletonWithDependencies<Repository<Post>>(
      () => _container.read(postRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      
  
i.registerSingletonWithDependencies<Repository<User>>(
      () => _container.read(userRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      
  
i.registerSingletonWithDependencies<Repository<Comment>>(
      () => _container.read(commentRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      } }
