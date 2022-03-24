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
      {bool? remote,
      bool? verbose,
      required Map<String, RemoteAdapter> adapters}) async {
    if (isInitialized) return this;
    _adapters.addAll(adapters);
    await remoteAdapter.initialize(
      remote: remote,
      verbose: verbose,
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
  Future<List<T>> findAll({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    OnDataError<List<T>>? onError,
  }) {
    return remoteAdapter.findAll(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      onError: onError,
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
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnDataError<T>? onError,
  }) {
    return remoteAdapter.findOne(
      id,
      remote: remote,
      params: params,
      headers: headers,
      onError: onError,
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
    OnData<T>? onSuccess,
    OnDataError<T>? onError,
  }) {
    return remoteAdapter.save(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
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
  Future<void> delete(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnData<void>? onSuccess,
    OnDataError<void>? onError,
  }) {
    return remoteAdapter.delete(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Deletes all models of type [T] in local storage.
  ///
  ///
  ///
  /// If you need to clear all models, use the
  /// `repositoryProviders` map exposed on your `main.data.dart`.
  Future<void> clear() => remoteAdapter.clear();

  // offline

  /// Gets a list of all pending [OfflineOperation]s for this type.
  Set<OfflineOperation<T>> get offlineOperations =>
      remoteAdapter.offlineOperations;

  /// Watches a provider wrapping [_RemoteAdapterWatch.watchAllNotifier]
  /// which allows the watcher to be notified of changes
  /// on any model of this [type].
  ///
  /// Example: Watch all models of type `books` on a Riverpod hook-enabled app.
  ///
  /// ```
  /// ref.books.watchAll();
  /// ```
  DataState<List<T>> watchAll({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
  }) {
    return remoteAdapter.watchAll(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
    );
  }

  /// Watches a provider wrapping [_RemoteAdapterWatch.watchOneNotifier]
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
  }) {
    return remoteAdapter.watchOne(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
    );
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
