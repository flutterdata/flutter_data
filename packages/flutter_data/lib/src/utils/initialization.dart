part of flutter_data;
// import 'package:equatable/equatable.dart';
// import 'package:flutter_data/flutter_data.dart';
// import 'package:meta/meta.dart';

typedef ConfigureRepositoryLocalStorage = Override Function({
  FutureFn<String>? baseDirFn,
  List<int>? encryptionKey,
  bool? clear,
});

typedef RepositoryInitializerProvider = FutureProvider<RepositoryInitializer> Function({
  bool? remote,
  bool? verbose,
});

/// ONLY FOR FLUTTER DATA INTERNAL USE
dynamic internalLocatorFn<S extends DataModel<S>>(
  Provider<Repository<S>> provider,
  Reader reader,
) =>
    reader(provider);

class RepositoryInitializer {}

class RepositoryInitializerArgs with EquatableMixin {
  RepositoryInitializerArgs(this.remote, this.verbose);

  bool remote;
  bool verbose;

  @override
  List<Object?> get props => [remote, verbose];
}

@protected
mixin NothingMixin {}

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T> with EquatableMixin {
  WatchArgs({
    this.id,
    this.remote,
    this.params,
    this.headers,
    this.syncLocal,
    this.alsoWatch,
  });

  Object? id;
  bool? remote;
  Map<String, dynamic>? params;
  Map<String, String>? headers;
  bool? syncLocal;
  AlsoWatch<T>? alsoWatch;

  @override
  List<Object?> get props => [id, remote, params, headers];
}
