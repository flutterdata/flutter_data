part of flutter_data;

/// Thin wrapper on the [RemoteAdapter] API
class Repository<T extends DataModel<T>> with _Lifecycle {
  final Reader _read;
  Repository(this._read);

  var _isInit = false;

  String get _internalType => DataHelpers.getType<T>();

  final _adapters = <String, RemoteAdapter>{};

  /// Obtain the [RemoteAdapter] for this type.
  RemoteAdapter<T> get remoteAdapter =>
      _adapters[_internalType]! as RemoteAdapter<T>;

  /// Type for the [RemoteAdapter]
  @nonVirtual
  String get type => remoteAdapter.type;

  /// Initializes this [Repository]. Nothing will work without this.
  /// In standard scenarios this initialization is done by the framework.
  @mustCallSuper
  FutureOr<Repository<T>> initialize(
      {bool? remote, required Map<String, RemoteAdapter> adapters}) async {
    if (isInitialized) return this;
    _adapters.addAll(adapters);
    await remoteAdapter.initialize(
      remote: remote,
      adapters: adapters,
      read: _read,
    );
    _isInit = true;
    return this;
  }

  /// Returns whether this [Repository] is initialized
  /// (when its underlying [RemoteAdapter] is).
  @override
  bool get isInitialized => _isInit && remoteAdapter.isInitialized;

  /// Disposes this [Repository] and everything that depends on it.
  @override
  void dispose() {
    if (isInitialized) {
      remoteAdapter.dispose();
      _isInit = false;
    }
  }

  // Public API

  /// Returns all models of type [T].
  ///
  /// If [_RemoteAdapter.shouldLoadRemoteAll] (function of [remote]) is `true`,
  /// it will initiate an HTTP call.
  /// Otherwise returns all models of type [T] in local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_RemoteAdapter.defaultParams] and [_RemoteAdapter.defaultHeaders], respectively.
  ///
  /// For local storage of type [T] to be synchronized to the exact resources
  /// returned from the remote source when using `findAll`, pass `syncLocal: true`.
  /// This call would, for example, reflect server-side resource deletions.
  /// The default is `syncLocal: false`.
  ///
  /// See also: [_RemoteAdapter.urlForFindAll], [_RemoteAdapter.methodForFindAll].
  Future<List<T>?> findAll({
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    OnSuccessAll<T>? onSuccess,
    OnErrorAll<T>? onError,
    DataRequestLabel? label,
  }) {
    return remoteAdapter.findAll(
      remote: remote,
      background: background,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      onSuccess: onSuccess,
      onError: onError,
      label: label,
    );
  }

  /// Returns model of type [T] by [id].
  ///
  /// If [_RemoteAdapter.shouldLoadRemoteOne] (function of [remote]) is `true`,
  /// it will initiate an HTTP call.
  /// Otherwise returns model of type [T] and [id] in local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_RemoteAdapter.defaultParams] and [_RemoteAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_RemoteAdapter.urlForFindOne], [_RemoteAdapter.methodForFindOne].
  Future<T?> findOne(
    Object id, {
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) {
    return remoteAdapter.findOne(
      id,
      remote: remote,
      background: background,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
      label: label,
    );
  }

  /// Saves [model] of type [T].
  ///
  /// If [remote] is `true`, it will initiate an HTTP call.
  ///
  /// Always persists to local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_RemoteAdapter.defaultParams] and [_RemoteAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_RemoteAdapter.urlForSave], [_RemoteAdapter.methodForSave].
  Future<T> save(
    T model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) {
    return remoteAdapter.save(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
      label: label,
    );
  }

  /// Deletes [model] of type [T].
  ///
  /// If [remote] is `true`, it will initiate an HTTP call.
  ///
  /// Always deletes from local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_RemoteAdapter.defaultParams] and [_RemoteAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_RemoteAdapter.urlForDelete], [_RemoteAdapter.methodForDelete].
  Future<T?> delete(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) {
    return remoteAdapter.delete(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
      label: label,
    );
  }

  /// Deletes all models of type [T] in local storage.
  ///
  /// If you need to clear all models, use the
  /// `repositoryProviders` map exposed on your `main.data.dart`.
  Future<void> clear() => remoteAdapter.clear();

  // offline

  /// Gets a list of all pending [OfflineOperation]s for this type.
  Set<OfflineOperation<T>> get offlineOperations =>
      remoteAdapter.offlineOperations;

  // watchers

  /// Watches a provider wrapping [Repository.watchAllNotifier]
  /// which allows the watcher to be notified of changes
  /// on any model of this [type].
  ///
  /// Example: Watch all models of type `books` on a Riverpod hook-enabled app.
  ///
  /// ```
  /// ref.books.watchAll();
  /// ```
  DataState<List<T>?> watchAll({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    String? finder,
    DataRequestLabel? label,
  }) {
    final provider = watchAllProvider(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      label: label,
    );
    return remoteAdapter.internalWatch!(provider);
  }

  /// Watches a provider wrapping [Repository.watchOneNotifier]
  /// which allows the watcher to be notified of changes
  /// on a specific model of this [type], optionally reacting
  /// to selected relationships of this model via [alsoWatch].
  ///
  /// Example: Watch model of type `books` and `id=1` along
  /// with its `author` relationship on a Riverpod hook-enabled app.
  ///
  /// ```
  /// ref.books.watchOne(1, alsoWatch: (book) => [book.author]);
  /// ```
  DataState<T?> watchOne(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    final provider = watchOneProvider(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      label: label,
    );
    return remoteAdapter.internalWatch!(provider);
  }

  // providers

  AutoDisposeStateNotifierProvider<DataStateNotifier<List<T>?>,
      DataState<List<T>?>> watchAllProvider({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    String? finder,
    DataRequestLabel? label,
  }) {
    remote ??= remoteAdapter._remote;
    return _watchAllProvider(
      WatchArgs(
        remote: remote,
        params: params,
        headers: headers,
        syncLocal: syncLocal,
        finder: finder,
        label: label,
      ),
    );
  }

  late final _watchAllProvider = StateNotifierProvider.autoDispose
      .family<DataStateNotifier<List<T>?>, DataState<List<T>?>, WatchArgs<T>>(
          (ref, args) {
    return remoteAdapter.watchAllNotifier(
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      syncLocal: args.syncLocal,
      finder: args.finder,
      label: args.label,
    );
  });

  AutoDisposeStateNotifierProvider<DataStateNotifier<T?>, DataState<T?>>
      watchOneProvider(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
    DataRequestLabel? label,
  }) {
    final key = remoteAdapter.keyForModelOrId(model);
    remote ??= remoteAdapter._remote;
    final relationshipMetas = alsoWatch
        ?.call(RelationshipGraphNode<T>())
        .whereType<RelationshipMeta>()
        .toImmutableList();

    return _watchOneProvider(
      WatchArgs(
        key: key,
        remote: remote,
        params: params,
        headers: headers,
        relationshipMetas: relationshipMetas,
        alsoWatch: alsoWatch,
        finder: finder,
        label: label,
      ),
    );
  }

  late final _watchOneProvider = StateNotifierProvider.autoDispose
      .family<DataStateNotifier<T?>, DataState<T?>, WatchArgs<T>>((ref, args) {
    return remoteAdapter.watchOneNotifier(
      args.key!,
      remote: args.remote,
      params: args.params,
      headers: args.headers,
      alsoWatch: args.alsoWatch,
      finder: args.finder,
      label: args.label,
    );
  });

  // notifiers

  DataStateNotifier<List<T>?> watchAllNotifier(
      {bool? remote,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      bool? syncLocal,
      String? finder,
      DataRequestLabel? label}) {
    final provider = watchAllProvider(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      finder: finder,
      label: label,
    );
    return remoteAdapter.internalWatch!(provider.notifier);
  }

  DataStateNotifier<T?> watchOneNotifier(Object model,
      {bool? remote,
      Map<String, dynamic>? params,
      Map<String, String>? headers,
      AlsoWatch<T>? alsoWatch,
      String? finder,
      DataRequestLabel? label}) {
    return remoteAdapter.internalWatch!(watchOneProvider(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
      finder: finder,
      label: label,
    ).notifier);
  }

  /// Watch this model (local)
  T watch(T model) {
    return watchOne(model, remote: false).model!;
  }

  /// Notifier for watched model (local)
  DataStateNotifier<T?> notifierFor(T model) {
    return watchOneNotifier(model, remote: false);
  }

  /// Logs messages for a specific label when `verbose` is `true`.
  void log(DataRequestLabel label, String message, {int logLevel = 1}) {
    remoteAdapter.log(label, message, logLevel: logLevel);
  }

  int get logLevel => remoteAdapter._logLevel;
  set logLevel(int value) {
    remoteAdapter._logLevel = value;
  }
}

/// Annotation on a [DataModel] model to request a [Repository] be generated for it.
///
/// Takes a list of [adapters] to be mixed into this [Repository].
/// Public methods of these [adapters] mixins will be made available in the repository
/// via extensions.
///
/// A classic example is:
///
/// ```
/// @JsonSerializable()
/// @DataRepository([JSONAPIAdapter])
/// class Todo with DataModel<Todo> {
///   @override
///   final int id;
///   final String title;
///   final bool completed;
///
///   Todo({this.id, this.title, this.completed = false});
/// }
///```
class DataRepository {
  final List<Type> adapters;
  final bool remote;
  const DataRepository(this.adapters, {this.remote = true});
}
