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
  String urlForFindAll(params) => '$type';

  /// Returns HTTP method for [findAll]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  /// Returns URL for [findOne]. Defaults to [type]/[id].
  @protected
  String urlForFindOne(id, params) => '$type/$id';

  /// Returns HTTP method for [findOne]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  /// Returns URL for [save]. Defaults to [type]/[id] (if [id] is present).
  @protected
  String urlForSave(id, params) => id != null ? '$type/$id' : type;

  /// Returns HTTP method for [save]. Defaults to `PATCH` if [id] is present,
  /// or `POST` otherwise.
  @protected
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  /// Returns URL for [delete]. Defaults to [type]/[id].
  @protected
  String urlForDelete(id, params) => '$type/$id';

  /// Returns HTTP method for [delete]. Defaults to `DELETE`.
  @protected
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  /// A [Map] representing HTTP query parameters. Defaults to empty.
  ///
  /// It can return a [Future], so that adapters overriding this method
  /// have a chance to call async methods.
  ///
  /// Example:
  /// ```
  /// @override
  /// FutureOr<Map<String, dynamic>> get params async {
  ///   final token = await _localStorage.get('token');
  ///   return await super.params..addAll({'token': token});
  /// }
  /// ```
  ///
  @protected
  FutureOr<Map<String, dynamic>> get params => {};

  /// A [Map] representing HTTP headers. Defaults to `{'Content-Type': 'application/json'}`.
  ///
  /// It can return a [Future], so that adapters overriding this method
  /// have a chance to call async methods.
  ///
  /// Example:
  /// ```
  /// @override
  /// FutureOr<Map<String, String>> get headers async {
  ///   final token = await _localStorage.get('token');
  ///   return await super.headers..addAll({'Authorization': token});
  /// }
  /// ```
  ///
  @protected
  FutureOr<Map<String, String>> get headers =>
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
    params = await this.params & params;
    headers = await this.headers & headers;
    init ??= false;

    if (!shouldLoadRemoteAll(remote, params, headers)) {
      final models = localAdapter.findAll();
      if (init) {
        models.map((m) => m._initialize(adapters, save: true));
      }
      return models;
    }

    return await withRequest<List<T>>(
      urlForFindAll(params),
      method: methodForFindAll(params),
      params: params,
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
    params = await this.params & params;
    headers = await this.headers & headers;
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

    assert(id != null);
    return await withRequest<T>(
      urlForFindOne(id, params),
      method: methodForFindOne(id, params),
      params: params,
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
    params = await this.params & params;
    headers = await this.headers & headers;
    init ??= false;

    if (remote == false) {
      // we ignore `init` as saving locally requires initializing
      return model._initialize(adapters, save: true);
    }

    final body = json.encode(serialize(model));

    return await withRequest<T>(
      urlForSave(model.id, params),
      method: methodForSave(model.id, params),
      params: params,
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
    params = await this.params & params;
    headers = await this.headers & headers;

    final id = model is T ? model.id : model;
    final key = graph.getKeyForId(type, id) ?? (model is T ? model._key : null);

    if (key == null) {
      return;
    }

    await localAdapter.delete(key);

    if (remote && id != null) {
      graph.removeId(type, id);
      return await withRequest<void>(
        urlForDelete(id, params),
        method: methodForDelete(id, params),
        params: params,
        headers: headers,
        onSuccess: (_) {},
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
  /// Takes expected arguments [url], [method], [params], [headers].
  ///
  /// In addition, [onSuccess] MUST be supplied to post-process the
  /// data in JSON format. Typically, deserialization and initialization
  /// happen in there.
  ///
  /// [onError] can also be supplied to override [_RemoteAdapter.onError].
  @protected
  @visibleForTesting
  FutureOr<R> withRequest<R>(
    String url, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, dynamic> params,
    Map<String, String> headers,
    String body,
    @required OnData<R> onSuccess,
    OnData<R> onError,
  }) async {
    final _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    var uri = Uri.parse('$_baseUrl$url');

    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: flattenQueryParameters(params));
    }

    // callbacks
    assert(onSuccess != null);
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

    if (_verbose && response != null) {
      print(
          '[flutter_data] $T: ${method.toShortString()} $uri [HTTP ${response.statusCode}]');
    }

    // response handling

    if (response.body.isNotEmpty) {
      try {
        data = json.decode(response.body);
      } on FormatException catch (e) {
        error = e;
      }
    }

    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      if (error != null) {
        error = DataException(error, stackTrace: stackTrace, statusCode: code);
      } else {
        return await onSuccess(data);
      }
    } else if (code >= 400 && code < 600) {
      error = DataException(error ?? data,
          stackTrace: stackTrace, statusCode: code);
    } else {
      error = DataException('Failed request for type $R', statusCode: code);
    }

    return await onError(error);
  }

  /// Describes how to handle errors arising in [withRequest].
  ///
  /// NOTE: [withRequest] has an `onError` argument used to override
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

  // helpers

  @protected
  @visibleForTesting
  Map<String, String> flattenQueryParameters(Map<String, dynamic> params) {
    params ??= const {};

    return params.entries.fold<Map<String, String>>({}, (acc, e) {
      if (e.value is Map<String, dynamic>) {
        for (final e2 in (e.value as Map<String, dynamic>).entries) {
          acc['${e.key}[${e2.key}]'] = e2.value.toString();
        }
      } else {
        acc[e.key] = e.value.toString();
      }
      return acc;
    });
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
/// Usually thrown from [_RemoteAdapter.onError] in [_RemoteAdapter.withRequest].
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
