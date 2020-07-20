part of flutter_data;

class RemoteAdapter<T extends DataSupport<T>> = _RemoteAdapter<T>
    with _RemoteAdapterSerialization<T>, _RemoteAdapterWatch<T>;

abstract class _RemoteAdapter<T extends DataSupport<T>>
    with _Lifecycle<_RemoteAdapter<T>> {
  @protected
  _RemoteAdapter(this.localAdapter);

  @protected
  @visibleForTesting
  final LocalAdapter<T> localAdapter;

  @protected
  GraphNotifier get graph => localAdapter.graph;

  @protected
  Map<String, RemoteAdapter> adapters;

  // late finals
  bool _remote;
  bool _verbose;

  /// Give adapter subclasses access to the DI system
  @nonVirtual
  @protected
  ProviderReference ref;

  //

  @nonVirtual
  @protected
  final type = DataHelpers.getType<T>();

  @protected
  String get baseUrl => throw UnsupportedError('Please override baseUrl');

  @protected
  String urlForFindAll(params) => '$type';

  @protected
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  @protected
  String urlForFindOne(id, params) => '$type/$id';

  @protected
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  @protected
  String urlForSave(id, params) => id != null ? '$type/$id' : type;

  @protected
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  @protected
  String urlForDelete(id, params) => '$type/$id';

  @protected
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  @protected
  FutureOr<Map<String, dynamic>> get params => {};

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
    // _save();
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

  // mixins

  @protected
  @visibleForTesting
  DeserializedData<T, DataSupport<dynamic>> deserialize(dynamic data,
      {String key, bool init});

  @protected
  @visibleForTesting
  Map<String, dynamic> serialize(T model);

  // caching

  @protected
  bool shouldLoadRemoteAll(
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  @protected
  bool shouldLoadRemoteOne(
    dynamic id,
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  // repository implementation

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
        models._initialize(adapters, save: true);
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

  @protected
  @visibleForTesting
  final http.Client httpClient = http.Client();

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
      uri = uri.replace(queryParameters: parseQueryParameters(params));
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
          throw UnsupportedError('No known HTTP method: $method');
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
        error = DataException(error, stackTrace: stackTrace, status: code);
      }
      return await onSuccess(data);
    } else if (code >= 400 && code < 600) {
      error =
          DataException(error ?? data, stackTrace: stackTrace, status: code);
    } else {
      error = DataException('Failed request for type $R', status: code);
    }

    return await onError(error);
  }

  @protected
  @visibleForTesting
  OnData<R> onError<R>(e) => throw e;

  // helpers

  @protected
  @visibleForTesting
  Map<String, String> parseQueryParameters(Map<String, dynamic> params) {
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

//

class DeserializedData<T, I> {
  const DeserializedData(this.models, {this.included});
  final List<T> models;
  final List<I> included;
  T get model => models.single;
}

class DataException implements Exception {
  final Object error;
  final int status;
  final StackTrace stackTrace;
  const DataException(this.error, {this.stackTrace, this.status});

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || toString() == other.toString();

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      status.hashCode ^
      error.hashCode ^
      stackTrace.hashCode;

  @override
  String toString() {
    return 'DataException: $error ${status != null ? " [HTTP $status]" : ""}\n$stackTrace';
  }
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}
