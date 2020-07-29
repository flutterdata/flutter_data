part of flutter_data;

/// An adapter base class for all remote operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_RemoteAdapterSerialization.serialize]
///  - Watch methods such as [_RemoteAdapterWatch.watchOne]
///  - Access to the [_RemoteAdapter.graph] for subclasses or mixins
///
/// This class is meant to be extended via mixing in new adapters.
/// This can be done with the [DataRepository] annotation on a [DataModel] class:
///
/// ```
/// @JsonSerializable()
/// @DataRepository([MyAppAdapter])
/// class Todo with DataModel<Todo> {
///   @override
///   final int id;
///   final String title;
///   final bool completed;
///
///   Todo({this.id, this.title, this.completed = false});
/// }
/// ```
class RemoteAdapter<T extends DataModel<T>> = _RemoteAdapter<T>
    with _RemoteAdapterSerialization<T>, _RemoteAdapterWatch<T>;

abstract class _RemoteAdapter<T extends DataModel<T>>
    with _Lifecycle<_RemoteAdapter<T>> {
  @protected
  _RemoteAdapter(this.localAdapter);

  @protected
  @visibleForTesting
  final LocalAdapter<T> localAdapter;

  /// A [GraphNotifier] instance also available to adapters
  @protected
  GraphNotifier get graph => localAdapter.graph;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  Map<String, RemoteAdapter> adapters;

  // late finals
  bool _remote;
  bool _verbose;

  /// Give adapter subclasses access to the dependency injection system
  @nonVirtual
  @protected
  ProviderReference ref;

  /// The pluralized and downcased [DataHelpers.getType<T>] version of type [T]
  ///
  /// Example: [T] as `Post` has a [type] of `posts`.
  @nonVirtual
  @protected
  final type = DataHelpers.getType<T>();

  /// Returns the base URL for this type [T].
  ///
  /// Typically used in a generic adapter (i.e. one shared by all types)
  /// so it should be e.g. `http://jsonplaceholder.typicode.com/`
  ///
  /// For specific paths to this type [T], see [urlForFindAll], [urlForFindOne], etc
  @protected
  String get baseUrl => throw UnsupportedError('Please override baseUrl');

  /// Returns URL for [findAll]. Defaults to [type].
  @protected
  String urlForFindAll(Map<String, dynamic> params) => '$type';

  /// Returns HTTP method for [findAll]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindAll(Map<String, dynamic> params) =>
      DataRequestMethod.GET;

  /// Returns URL for [findOne]. Defaults to [type]/[id].
  @protected
  String urlForFindOne(id, Map<String, dynamic> params) => '$type/$id';

  /// Returns HTTP method for [findOne]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindOne(id, Map<String, dynamic> params) =>
      DataRequestMethod.GET;

  /// Returns URL for [save]. Defaults to [type]/[id] (if [id] is present).
  @protected
  String urlForSave(id, Map<String, dynamic> params) =>
      id != null ? '$type/$id' : type;

  /// Returns HTTP method for [save]. Defaults to `PATCH` if [id] is present,
  /// or `POST` otherwise.
  @protected
  DataRequestMethod methodForSave(id, Map<String, dynamic> params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  /// Returns URL for [delete]. Defaults to [type]/[id].
  @protected
  String urlForDelete(id, Map<String, dynamic> params) => '$type/$id';

  /// Returns HTTP method for [delete]. Defaults to `DELETE`.
  @protected
  DataRequestMethod methodForDelete(id, Map<String, dynamic> params) =>
      DataRequestMethod.DELETE;

  /// A [Map] representing default HTTP query parameters. Defaults to empty.
  ///
  /// It can return a [Future], so that adapters overriding this method
  /// have a chance to call async methods.
  ///
  /// Example:
  /// ```
  /// @override
  /// FutureOr<Map<String, dynamic>> get defaultParams async {
  ///   final token = await _localStorage.get('token');
  ///   return await super.defaultParams..addAll({'token': token});
  /// }
  /// ```
  @protected
  FutureOr<Map<String, dynamic>> get defaultParams => {};

  /// A [Map] representing default HTTP headers.
  ///
  /// Initial default is: `{'Content-Type': 'application/json'}`.
  ///
  /// It can return a [Future], so that adapters overriding this method
  /// have a chance to call async methods.
  ///
  /// Example:
  /// ```
  /// @override
  /// FutureOr<Map<String, String>> get defaultHeaders async {
  ///   final token = await _localStorage.get('token');
  ///   return await super.defaultHeaders..addAll({'Authorization': token});
  /// }
  /// ```
  @protected
  FutureOr<Map<String, String>> get defaultHeaders =>
      {'Content-Type': 'application/json'};

  // lifecycle methods

  @override
  @mustCallSuper
  Future<RemoteAdapter<T>> initialize(
      {final bool remote,
      final bool verbose,
      final Map<String, RemoteAdapter> adapters,
      ProviderReference ref}) async {
    if (isInitialized) return this as RemoteAdapter<T>;
    _remote = remote ?? true;
    _verbose = verbose ?? true;
    this.adapters = adapters;
    this.ref = ref;

    await localAdapter.initialize();

    await super.initialize();
    return this as RemoteAdapter<T>;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await localAdapter.dispose();
  }

  void _assertInit() {
    assert(isInitialized, true);
  }

  // serialization interface

  /// Returns a [DeserializedData] object when deserializing a given [data].
  ///
  /// If [init] is `true`, ALL models in deserialization (including `included`)
  /// will be initialized.
  ///
  /// [key] can be used to supply a specific `key` when deserializing ONE model.
  @protected
  @visibleForTesting
  DeserializedData<T, DataModel<dynamic>> deserialize(dynamic data,
      {String key, bool init});

  /// Returns a serialized version of a model of [T],
  /// as a [Map<String, dynamic>] ready to be JSON-encoded.
  @protected
  @visibleForTesting
  Map<String, dynamic> serialize(T model);

  // caching

  /// Returns whether calling [findAll] should trigger a remote call.
  ///
  /// Meant to be overriden. Defaults to [remote].
  @protected
  bool shouldLoadRemoteAll(
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  /// Returns whether calling [findOne] should initiate an HTTP call.
  ///
  /// Meant to be overriden. Defaults to [remote].
  @protected
  bool shouldLoadRemoteOne(
    dynamic id,
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  // remote implementation

  @protected
  @visibleForTesting
  Future<List<T>> findAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      bool init}) async {
    _assertInit();
    remote ??= _remote;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;
    init ??= false;

    if (!shouldLoadRemoteAll(remote, params, headers)) {
      final models = localAdapter.findAll();
      if (init) {
        models.map((m) => m._initialize(adapters, save: true));
      }
      return models;
    }

    return await sendRequest<List<T>>(
      baseUrl.asUri / urlForFindAll(params) & params,
      method: methodForFindAll(params),
      headers: headers,
      onSuccess: (data) {
        return deserialize(data, init: init).models;
      },
    );
  }

  @protected
  @visibleForTesting
  Future<T> findOne(final dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      bool init}) async {
    _assertInit();
    assert(model != null);
    remote ??= _remote;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;
    init ??= false;

    final id = model is T ? model.id : model;

    if (!shouldLoadRemoteOne(id, remote, params, headers)) {
      final key =
          graph.getKeyForId(type, id) ?? (model is T ? model._key : null);
      if (key == null) {
        return null;
      }
      final newModel = localAdapter.findOne(key);
      if (init) {
        newModel._initialize(adapters, save: true);
      }
      return newModel;
    }

    return await sendRequest<T>(
      baseUrl.asUri / urlForFindOne(id, params) & params,
      method: methodForFindOne(id, params),
      headers: headers,
      onSuccess: (data) {
        return deserialize(data as Map<String, dynamic>, init: init).model;
      },
    );
  }

  @protected
  @visibleForTesting
  Future<T> save(final T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      bool init}) async {
    _assertInit();
    remote ??= _remote;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;
    init ??= false;

    if (remote == false) {
      // we ignore `init` as saving locally requires initializing
      return model._initialize(adapters, save: true);
    }

    final body = json.encode(serialize(model));

    return await sendRequest<T>(
      baseUrl.asUri / urlForSave(model.id, params) & params,
      method: methodForSave(model.id, params),
      headers: headers,
      body: body,
      onSuccess: (data) {
        if (data == null) {
          // return "old" model if response was empty
          if (init) {
            model._initialize(adapters, save: true);
          }
          return model;
        }
        // deserialize already inits models
        // if model had a key already, reuse it
        final newModel = deserialize(data as Map<String, dynamic>,
                key: model._key, init: init)
            .model;

        // in the unlikely case where supplied key couldn't be used
        // ensure "old" copy of model carries the updated key
        if (init && model._key != null && model._key != newModel._key) {
          graph.removeKey(model._key);
          model._key = newModel._key;
        }
        return newModel;
      },
    );
  }

  @protected
  @visibleForTesting
  Future<void> delete(final dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertInit();
    remote ??= _remote;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    final id = model is T ? model.id : model;
    final key = graph.getKeyForId(type, id) ?? (model is T ? model._key : null);

    if (key == null) {
      return;
    }

    await localAdapter.delete(key);

    if (remote && id != null) {
      graph.removeId(type, id);
      return await sendRequest<void>(
        baseUrl.asUri / urlForDelete(id, params) & params,
        method: methodForDelete(id, params),
        headers: headers,
      );
    }
  }

  @protected
  @visibleForTesting
  Future<void> clear() => localAdapter.clear();

  // http

  /// The [http.Client] used to make all HTTP requests.
  @protected
  @visibleForTesting
  http.Client get httpClient => http.Client();

  /// The function used to perform an HTTP request and return an [R].
  ///
  /// **IMPORTANT**:
  ///  - [uri] takes the FULL `Uri` including query parameters
  ///  - [headers] do NOT include ANY defaults such as [defaultHeaders]
  ///
  /// Example:
  ///
  /// ```
  /// await sendRequest(
  ///   baseUrl.asUri + 'token' & await defaultParams & {'a': 1},
  ///   headers: await defaultHeaders & {'a': 'b'},
  ///   onSuccess: (data) => data['token'] as String,
  /// );
  /// ```
  ///
  ///ignore: comment_references
  /// To build the URI you can use [String.asUri], [Uri.+] and [Uri.&].
  ///
  /// To merge headers and params with their defaults you can use the helper
  /// [Map<String, dynamic>.&].
  ///
  /// In addition, [onSuccess] is supplied to post-process the
  /// data in JSON format. Deserialization and initialization
  /// typically occur in this function.
  ///
  /// [onError] can also be supplied to override [_RemoteAdapter.onError].
  @protected
  @visibleForTesting
  FutureOr<R> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String> headers,
    String body,
    OnData<R> onSuccess,
    OnData<R> onError,
  }) async {
    // callbacks
    onSuccess ??= (_) async => null;
    onError ??= (e) async => this.onError(e) as R;

    http.Response response;
    dynamic data;
    dynamic error;
    StackTrace stackTrace;

    try {
      switch (method) {
        case DataRequestMethod.HEAD:
          response = await httpClient.head(uri, headers: headers);
          break;
        case DataRequestMethod.GET:
          response = await httpClient.get(uri, headers: headers);
          break;
        case DataRequestMethod.PUT:
          response = await httpClient.put(uri, headers: headers, body: body);
          break;
        case DataRequestMethod.POST:
          response = await httpClient.post(uri, headers: headers, body: body);
          break;
        case DataRequestMethod.PATCH:
          response = await httpClient.patch(uri, headers: headers, body: body);
          break;
        case DataRequestMethod.DELETE:
          response = await httpClient.delete(uri, headers: headers);
          break;
        default:
          break;
      }
    } catch (err, stack) {
      error = err;
      stackTrace = stack;
    } finally {
      httpClient.close();
    }

    // response handling

    if (response?.body == null) {
      return await onError(DataException(error, stackTrace: stackTrace));
    }

    try {
      data = response.body.isEmpty ? null : json.decode(response.body);
    } on FormatException catch (e) {
      error = e;
    }

    final code = response.statusCode;

    if (_verbose) {
      print(
          '[flutter_data] $T: ${method.toShortString()} $uri [HTTP $code]${body != null ? '\n -> body: $body' : ''}');
    }

    if (error == null && code >= 200 && code < 300) {
      return await onSuccess(data);
    } else {
      final e = DataException(error ?? data,
          stackTrace: stackTrace, statusCode: code);
      if (_verbose) {
        print('[flutter_data] $T: $e');
      }
      return await onError(e);
    }
  }

  /// Describes how to handle errors arising in [sendRequest].
  ///
  /// NOTE: [sendRequest] has an `onError` argument used to override
  /// this default behavior.
  @protected
  @visibleForTesting
  OnData<R> onError<R>(e) => throw e;

  /// Initializes [model] making it ready to use with [DataModel] extensions.
  ///
  /// Optionally provide [key]. Use [save] to persist in local storage.
  @protected
  @visibleForTesting
  T initializeModel(T model, {String key, bool save}) {
    return model?._initialize(adapters, key: key, save: save);
  }
}

/// A utility class used to return deserialized main [models] AND [included] models.
class DeserializedData<T, I> {
  const DeserializedData(this.models, {this.included});
  final List<T> models;
  final List<I> included;
  T get model => models.single;
}

/// A standard [Exception] used throughout Flutter Data.
///
/// Usually thrown from [_RemoteAdapter.onError] in [_RemoteAdapter.sendRequest].
class DataException implements Exception {
  final Object error;
  final int statusCode;
  final StackTrace stackTrace;
  const DataException(this.error, {this.stackTrace, this.statusCode});

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || toString() == other.toString();

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      statusCode.hashCode ^
      error.hashCode ^
      stackTrace.hashCode;

  @override
  String toString() {
    return 'DataException: $error ${statusCode != null ? " [HTTP $statusCode]" : ""}\n$stackTrace';
  }
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}
