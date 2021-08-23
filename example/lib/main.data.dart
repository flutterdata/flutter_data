

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: directives_ordering, top_level_function_literal_block

import 'package:flutter_data/flutter_data.dart';



import 'package:jsonplaceholder_example/models/comment.dart';
import 'package:jsonplaceholder_example/models/post.dart';
import 'package:jsonplaceholder_example/models/user.dart';

// ignore: prefer_function_declarations_over_variables
ConfigureRepositoryLocalStorage configureRepositoryLocalStorage = ({FutureFn<String>? baseDirFn, List<int>? encryptionKey, bool? clear}) {
  
    
  
  
  
  
  return hiveLocalStorageProvider.overrideWithProvider(Provider(
        (_) => HiveLocalStorage(baseDirFn: baseDirFn, encryptionKey: encryptionKey, clear: clear)));
};

// ignore: prefer_function_declarations_over_variables
RepositoryInitializerProvider repositoryInitializerProvider = (
        {bool? remote, bool? verbose}) {
  return _repositoryInitializerProviderFamily(
      RepositoryInitializerArgs(remote, verbose));
};

final repositoryProviders = <String, Provider<Repository<DataModel>>>{
  'comments': commentsRepositoryProvider,
'posts': postsRepositoryProvider,
'sheep': sheepRepositoryProvider,
'users': usersRepositoryProvider
};

final _repositoryInitializerProviderFamily =
  FutureProvider.family<RepositoryInitializer, RepositoryInitializerArgs>((ref, args) async {
    final adapters = <String, RemoteAdapter>{'comments': ref.read(commentsRemoteAdapterProvider), 'posts': ref.read(postsRemoteAdapterProvider), 'sheep': ref.read(sheepRemoteAdapterProvider), 'users': ref.read(usersRemoteAdapterProvider)};
    final remotes = <String, bool>{'comments': true, 'posts': true, 'sheep': false, 'users': true};

    await ref.read(graphNotifierProvider).initialize();

    for (final key in repositoryProviders.keys) {
      final repository = ref.read(repositoryProviders[key]!);
      repository.dispose();
      await repository.initialize(
        remote: args.remote ?? remotes[key]!,
        verbose: args.verbose,
        adapters: adapters,
      );
    }

    ref.onDispose(() {
      if (ref.mounted) {
        for (final repositoryProvider in repositoryProviders.values) {
          ref.read(repositoryProvider).dispose();
        }
        ref.read(graphNotifierProvider).dispose();
      }
    });

    return RepositoryInitializer();
});
