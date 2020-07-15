

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'dart:async';
import 'package:flutter_data/flutter_data.dart';



import 'package:get_it/get_it.dart';

import 'package:jsonplaceholder_example/model/post.dart';
import 'package:jsonplaceholder_example/model/user.dart';
import 'package:jsonplaceholder_example/model/comment.dart';

Future<void> initializeRepositories(ProviderReference ref,
    {bool remote, bool verbose, FutureProvider<void> alsoInitialize}) async {
    final graphs = <String, Map<String, RemoteAdapter>>{'comments,posts,users': {'comments': ref.read(commentsRemoteAdapterProvider), 'posts': ref.read(postsRemoteAdapterProvider), 'users': ref.read(usersRemoteAdapterProvider)}, 'users': {'users': ref.read(usersRemoteAdapterProvider)}};
                await ref.read(postsRepositoryProvider).initialize(
              remote: remote,
              verbose: verbose,
              adapters: graphs['comments,posts,users'],
            );            await ref.read(usersRepositoryProvider).initialize(
              remote: remote,
              verbose: verbose,
              adapters: graphs['users'],
            );            await ref.read(commentsRepositoryProvider).initialize(
              remote: remote,
              verbose: verbose,
              adapters: graphs['comments,posts,users'],
            );
    if (alsoInitialize != null) {
      await ref.read(alsoInitialize);
    }
}

StateNotifierProvider<RepositoryInitializerNotifier>
    repositoryInitializerProvider(
        {bool remote, bool verbose, FutureProvider<void> alsoInitialize}) {
  return StateNotifierProvider<RepositoryInitializerNotifier>((ref) {
    final notifier = RepositoryInitializerNotifier(false);
    initializeRepositories(ref,
            remote: remote, verbose: verbose, alsoInitialize: alsoInitialize)
        .then((_) => notifier.value = true);
    return notifier;
  });
}



class RepositoryInitializer {}

extension GetItFlutterDataX on GetIt {
  void registerRepositories({FutureOr<String> Function() baseDirFn,
    bool clear, bool remote, bool verbose, List<int> encryptionKey, FutureProvider<void> alsoInitialize}) {

final _owner = ProviderStateOwner(overrides: [
    hiveDirectoryProvider.overrideAs(FutureProvider((ref) async {
      final dir = baseDirFn?.call();
      return dir;
    })),
    hiveLocalStorageProvider.overrideAs(Provider(
        (ref) => HiveLocalStorage(ref, encryptionKey: encryptionKey, clear: true)))
  ]);

GetIt.instance.registerSingletonAsync<RepositoryInitializer>(() async {
    await initializeRepositories(_owner.ref,
                remote: remote, verbose: verbose, alsoInitialize: alsoInitialize);
    return RepositoryInitializer();
  });  
GetIt.instance.registerSingletonWithDependencies<Repository<Post>>(
      () => _owner.ref.read(postsRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      
  
GetIt.instance.registerSingletonWithDependencies<Repository<User>>(
      () => _owner.ref.read(usersRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      
  
GetIt.instance.registerSingletonWithDependencies<Repository<Comment>>(
      () => _owner.ref.read(commentsRepositoryProvider),
      dependsOn: [RepositoryInitializer]);

      } }
