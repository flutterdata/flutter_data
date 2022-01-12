part of flutter_data;

/// An adapter base class for all remote operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_RemoteAdapterSerialization.serialize]
///  - Watch methods such as [_RemoteAdapterWatch.watchOneNotifier]
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
///   final int? id;
///   final String title;
///   final bool completed;
///
///   Todo({this.id, required this.title, this.completed = false});
/// }
/// ```
class RemoteAdapter<T extends DataModel<T>> = _RemoteAdapter<T>
    with
        _RemoteAdapterSerialization<T>,
        _RemoteAdapterOffline<T>,
        _RemoteAdapterWatch<T>;

abstract class _RemoteAdapter<T extends DataModel<T>> with _Lifecycle {
  @protected
  _RemoteAdapter(this.localAdapter, [this._oneProvider, this._allProvider]);

  @protected
  @visibleForTesting
  @nonVirtual
  final LocalAdapter<T> localAdapter;

  /// A [GraphNotifier] instance also available to adapters
  @protected
  @nonVirtual
  GraphNotifier get graph => localAdapter.graph;

  // None of these fields below can be late finals as they might be re-initialized
  late Map<String, RemoteAdapter> _adapters;
  late bool _remote;
  late bool _verbose;
  late Reader _read;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, RemoteAdapter> get adapters => _adapters;

  /// Give adapter subclasses access to the dependency injection system
  @protected
  @nonVirtual
  Reader get read => _read;

  /// INTERNAL: DO NOT USE
  @visibleForTesting
  @protected
  @nonVirtual
  String get internalType => DataHelpers.getTypeFromClass<T>();

  /// The pluralized and downcased [DataHelpers.getType<T>] version of type [T]
  /// by default.
  ///
  /// Example: [T] as `Post` has a [type] of `posts`.
  @visibleForTesting
  @protected
  String get type => internalType;

  /// ONLY FOR FLUTTER DATA INTERNAL USE
  late final Watcher internalWatch;

  late final OneProvider<T>? _oneProvider;
  late final AllProvider<T>? _allProvider;

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
  String urlForFindAll(Map<String, dynamic> params) => type;

  /// Returns HTTP method for [findAll]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindAll(
    Map<String, dynamic> params,
  ) =>
      DataRequestMethod.GET;

  /// Returns URL for [findOne]. Defaults to [type]/[id].
  @protected
  String urlForFindOne(
    String id,
    Map<String, dynamic> params,
  ) =>
      '$type/$id';

  /// Returns HTTP method for [findOne]. Defaults to `GET`.
  @protected
  DataRequestMethod methodForFindOne(
    String id,
    Map<String, dynamic> params,
  ) =>
      DataRequestMethod.GET;

  /// Returns URL for [save]. Defaults to [type]/[id] (if [id] is present).
  @protected
  String urlForSave([Object? id, Map<String, dynamic>? params]) =>
      id != null ? '$type/$id' : type;

  /// Returns HTTP method for [save]. Defaults to `PATCH` if [id] is present,
  /// or `POST` otherwise.
  @protected
  DataRequestMethod methodForSave([Object? id, Map<String, dynamic>? params]) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  /// Returns URL for [delete]. Defaults to [type]/[id].
  @protected
  String urlForDelete(Object id, Map<String, dynamic> params) => '$type/$id';

  /// Returns HTTP method for [delete]. Defaults to `DELETE`.
  @protected
  DataRequestMethod methodForDelete(String id, Map<String, dynamic> params) =>
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
  FutureOr<Map<String, dynamic>> get defaultParams => <String, dynamic>{};

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

  @mustCallSuper
  Future<void> onInitialized() async {}

  @mustCallSuper
  @nonVirtual
  Future<RemoteAdapter<T>> initialize({
    bool? remote,
    bool? verbose,
    required Map<String, RemoteAdapter> adapters,
    required Reader read,
  }) async {
    if (isInitialized) return this as RemoteAdapter<T>;

    // initialize attributes
    _adapters = adapters;
    _remote = remote ?? true;
    _verbose = verbose ?? true;
    _read = read;

    await localAdapter.initialize();

    // hook for clients
    await onInitialized();

    return this as RemoteAdapter<T>;
  }

  @override
  bool get isInitialized => localAdapter.isInitialized;

  @override
  void dispose() {
    localAdapter.dispose();
  }

  void _assertInit() {
    assert(isInitialized, true);
  }

  // serialization interface

  /// Returns a [DeserializedData] object when deserializing a given [data].
  ///
  /// [key] can be used to supply a specific `key` when deserializing ONE model.
  @protected
  @visibleForTesting
  DeserializedData<T, DataModel> deserialize(Object data, {String key});

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
  Future<List<T>> findAll({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    OnData<List<T>>? onSuccess,
    OnDataError<List<T>>? onError,
  }) async {
    _assertInit();
    remote ??= _remote;
    syncLocal ??= false;
    final _params = await defaultParams & params;
    final _headers = await defaultHeaders & headers;

    if (!shouldLoadRemoteAll(remote, _params, _headers)) {
      return localAdapter
          .findAll()
          .toImmutableList()
          .map(
            (m) => m._initialize(adapters, save: true),
          )
          .toList();
    }

    final result = await sendRequest(
      baseUrl.asUri / urlForFindAll(_params) & _params,
      method: methodForFindAll(_params),
      headers: _headers,
      requestType: DataRequestType.findAll,
      key: internalType,
      onSuccess: (dynamic data) async {
        if (syncLocal!) {
          await localAdapter.clear();
        }
        final models = data != null
            ? deserialize(data as Object).models.toImmutableList()
            : <T>[];
        return onSuccess?.call(models) ?? models;
      },
      onError: onError,
    );
    return result ?? <T>[];
  }

  @protected
  @visibleForTesting
  Future<T?> findOne(
    final dynamic idOrModel, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnData<T?>? onSuccess,
    OnDataError<T?>? onError,
  }) async {
    _assertInit();
    if (idOrModel == null) {
      throw AssertionError('Model must be not null');
    }
    remote ??= _remote;

    final _params = await defaultParams & params;
    final _headers = await defaultHeaders & headers;

    final id = _resolveId(idOrModel);

    if (!shouldLoadRemoteOne(id, remote, _params, _headers)) {
      final key = graph.getKeyForId(
        internalType,
        id,
        keyIfAbsent: idOrModel is T ? idOrModel._key : null,
      );
      if (key == null) {
        return null;
      }
      final newModel = localAdapter.findOne(key);
      newModel?._initialize(adapters, save: true);
      return newModel;
    }

    return await sendRequest(
      baseUrl.asUri / urlForFindOne(id!, _params) & _params,
      method: methodForFindOne(id, _params),
      headers: _headers,
      requestType: DataRequestType.findOne,
      key: StringUtils.typify(internalType, id),
      onSuccess: (dynamic data) {
        final model = data != null
            ? deserialize(data as Map<String, dynamic>).model
            : null;
        return onSuccess?.call(model) ?? model;
      },
      onError: onError,
    );
  }

  @protected
  @visibleForTesting
  Future<T> save(
    T model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnData<T>? onSuccess,
    OnDataError<T>? onError,
  }) async {
    _assertInit();
    remote ??= _remote;

    final _params = await defaultParams & params;
    final _headers = await defaultHeaders & headers;

    // we ignore the `init` argument here as
    // saving locally requires initializing
    model._initialize(adapters, save: true);

    if (remote == false) {
      return model;
    }

    final body = json.encode(serialize(model));

    final result = await sendRequest(
      baseUrl.asUri / urlForSave(model.id, _params) & _params,
      method: methodForSave(model.id, _params),
      headers: _headers,
      body: body,
      requestType: DataRequestType.save,
      key: model._key,
      onSuccess: (dynamic data) {
        T _model;
        if (data == null) {
          // return "old" model if response was empty
          _model = model._initialize(adapters, save: true);
        } else {
          // deserialize already inits models
          // if model had a key already, reuse it
          final _newModel =
              deserialize(data as Map<String, dynamic>, key: model._key!)
                  .model!;

          // in the unlikely case where supplied key couldn't be used
          // ensure "old" copy of model carries the updated key
          if (model._key != null && model._key != _newModel._key) {
            graph.removeKey(model._key!);
            model._key = _newModel._key;
          }
          _model = _newModel;
        }
        return onSuccess?.call(_model) ?? _model;
      },
      onError: onError,
    );
    return result ?? model;
  }

  @protected
  @visibleForTesting
  Future<void> delete(
    dynamic idOrModel, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnData<void>? onSuccess,
    OnDataError<void>? onError,
  }) async {
    _assertInit();
    remote ??= _remote;

    final _params = await defaultParams & params;
    final _headers = await defaultHeaders & headers;

    final id = _resolveId(idOrModel);
    final key = _keyForModel(idOrModel);

    if (key != null) {
      await localAdapter.delete(key);
    }

    if (remote) {
      return await sendRequest(
        baseUrl.asUri / urlForDelete(id ?? '', _params) & _params,
        method: methodForDelete(id ?? '', _params),
        headers: _headers,
        requestType: DataRequestType.delete,
        key: StringUtils.typify(internalType, id),
        onSuccess: onSuccess,
        onError: onError,
      );
    }
  }

  @protected
  @visibleForTesting
  Future<void> clear() => localAdapter.clear();

  // http

  /// An [http.Client] used to make an HTTP request.
  ///
  /// This getter returns a new client every time
  /// as by default they are used once and then closed.
  @protected
  @visibleForTesting
  http.Client get httpClient => http.Client();

  /// The function used to perform an HTTP request and return an [R].
  ///
  /// **IMPORTANT**:
  ///  - [uri] takes the FULL `Uri` including query parameters
  ///  - [headers] does NOT include ANY defaults such as [defaultHeaders]
  ///  (unless you omit the argument, in which case defaults will be included)
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
  FutureOr<R?> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String>? headers,
    String? body,
    String? key,
    OnRawData<R>? onSuccess,
    OnDataError<R>? onError,
    DataRequestType requestType = DataRequestType.adhoc,
    bool omitDefaultParams = false,
  }) async {
    // callbacks
    onError ??= this.onError as OnDataError<R>;

    headers ??= await defaultHeaders;
    final _params =
        omitDefaultParams ? <String, dynamic>{} : await defaultParams;

    http.Response? response;
    Object? data;
    Object? error;
    StackTrace? stackTrace;

    try {
      final request = http.Request(method.toShortString(), uri & _params);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = body;
      }
      final stream = await httpClient.send(request);
      response = await http.Response.fromStream(stream);
    } catch (err, stack) {
      error = err;
      stackTrace = stack;
    } finally {
      httpClient.close();
    }

    // response handling

    try {
      if (response?.body.isNotEmpty ?? false) {
        data = json.decode(response!.body);
      }
    } on FormatException catch (e) {
      error = e;
    }

    final code = response?.statusCode;

    if (_verbose) {
      print(
        '[flutter_data] [$internalType] ${method.toShortString()} $uri '
        '[HTTP ${code ?? ''}]${body != null ? '\n -> body:\n $body' : ''}',
      );
    }

    if (error == null && code != null && code >= 200 && code < 300) {
      return await onSuccess?.call(data);
    } else {
      final e = DataException(error ?? data!,
          stackTrace: stackTrace, statusCode: code);

      if (_verbose) {
        print('[flutter_data] [$internalType] Error: $e');
      }
      return await onError(e);
    }
  }

  /// Implements global request error handling.
  ///
  /// Defaults to throw [e] unless it is an HTTP 404
  /// or an `OfflineException`.
  ///
  /// NOTE: `onError` arguments throughout the API are used
  /// to override this default behavior.
  @protected
  @visibleForTesting
  FutureOr<R?> onError<R>(DataException e) {
    if (e.statusCode == 404 || e is OfflineException) {
      return null;
    }
    throw e;
  }

  /// Initializes [model] making it ready to use with [DataModel] extensions.
  ///
  /// Optionally provide [key]. Use [save] to persist in local storage.
  @protected
  @visibleForTesting
  @nonVirtual
  T initializeModel(T model, {String? key, bool save = false}) {
    return model._initialize(adapters, key: key, save: save);
  }

  String? _resolveId(dynamic model) {
    return (model is T ? model.id : model)?.toString();
  }

  String? _keyForModel(dynamic model) {
    final id = _resolveId(model);
    return graph.getKeyForId(internalType, id,
        keyIfAbsent: model is T ? model._key : null);
  }
}

/// A utility class used to return deserialized main [models] AND [included] models.
class DeserializedData<T, I> {
  const DeserializedData(this.models, {this.included = const []});
  final List<T> models;
  final List<I> included;
  T? get model => models.singleOrNull;
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}

typedef OnData<R> = FutureOr<R> Function(R);
typedef OnRawData<R> = FutureOr<R?> Function(dynamic);
typedef OnDataError<R> = FutureOr<R?> Function(DataException);

// ignore: constant_identifier_names
enum DataRequestType {
  findAll,
  findOne,
  save,
  delete,
  adhoc,
}

extension _DataRequestTypeX on DataRequestType {
  String toShortString() => toString().split('.').last;
}

DataRequestType _getDataRequestType(String type) =>
    DataRequestType.values.singleWhere((_) => _.toShortString() == type);
