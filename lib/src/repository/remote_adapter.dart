part of flutter_data;

/// An adapter base class for all remote operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_RemoteAdapterSerialization.serialize]
///  - Watch methods such as [Repository.watchOneNotifier]
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
///
/// Identity in this layer is enforced by IDs.
// ignore: library_private_types_in_public_api
class RemoteAdapter<T extends DataModel<T>> = _RemoteAdapter<T>
    with _RemoteAdapterSerialization<T>, _RemoteAdapterWatch<T>;

abstract class _RemoteAdapter<T extends DataModel<T>> with _Lifecycle {
  @protected
  _RemoteAdapter(this.localAdapter, [this._internalHolder]);

  @protected
  @visibleForTesting
  @nonVirtual
  final LocalAdapter<T> localAdapter;

  /// A [GraphNotifier] instance also available to adapters
  @protected
  @nonVirtual
  GraphNotifier get graph => localAdapter.graph;

  // None of these fields below can be late finals as they might be re-initialized
  Map<String, RemoteAdapter>? _adapters;
  bool? _remote;
  Reader? _read;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, RemoteAdapter> get adapters => _adapters!;

  /// Give access to the dependency injection system
  @nonVirtual
  Reader get read => _read!;

  /// INTERNAL: DO NOT USE
  @visibleForTesting
  @protected
  @nonVirtual
  String get internalType => DataHelpers.getType<T>();

  /// The pluralized and downcased [DataHelpers.getType<T>] version of type [T]
  /// by default.
  ///
  /// Example: [T] as `Post` has a [type] of `posts`.
  String get type => internalType;

  /// ONLY FOR FLUTTER DATA INTERNAL USE
  Watcher? internalWatch;
  final InternalHolder<T>? _internalHolder;

  /// Set log level.
  // ignore: prefer_final_fields
  int _logLevel = 0;

  /// Returns the base URL for this type [T].
  ///
  /// Typically used in a generic adapter (i.e. one shared by all types)
  /// so it should be e.g. `http://jsonplaceholder.typicode.com/`
  ///
  /// For specific paths to this type [T], see [urlForFindAll], [urlForFindOne], etc
  @protected
  String get baseUrl => 'https://override-base-url-in-adapter/';

  /// Returns URL for [findAll]. Defaults to [type].
  @protected
  String urlForFindAll(Map<String, dynamic> params) => type;

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

  @mustCallSuper
  Future<void> onInitialized() async {}

  @mustCallSuper
  @nonVirtual
  Future<RemoteAdapter<T>> initialize(
      {bool? remote,
      required Map<String, RemoteAdapter> adapters,
      required Reader read}) async {
    if (isInitialized) return this as RemoteAdapter<T>;

    // initialize attributes
    _adapters = adapters;
    _remote = remote ?? true;
    _read = read;

    await localAdapter.initialize();

    // hook for clients
    await onInitialized();

    return this as RemoteAdapter<T>;
  }

  @override
  bool get isInitialized => localAdapter.isInitialized;

  /// ONLY FOR FLUTTER DATA INTERNAL USE
  Future<void> internalInitializeModels() async {
    final models = localAdapter.findAll();
    if (models != null) {
      for (final model in models) {
        initModel(model, save: false);
      }
    }
  }

  @override
  void dispose() {
    localAdapter.dispose();
  }

  // serialization interface

  /// Returns a [DeserializedData] object when deserializing a given [data].
  @protected
  @visibleForTesting
  Future<DeserializedData<T>> deserialize(Object? data);

  /// Returns a serialized version of a model of [T],
  /// as a [Map<String, dynamic>] ready to be JSON-encoded.
  @protected
  @visibleForTesting
  Future<Map<String, dynamic>> serialize(T model,
      {bool withRelationships = true});

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
    Object? id,
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  // remote implementation

  Future<List<T>?> findAll({
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    OnSuccessAll<T>? onSuccess,
    OnErrorAll<T>? onError,
    DataRequestLabel? label,
  }) async {
    remote ??= _remote;
    background ??= false;
    syncLocal ??= false;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    label = DataRequestLabel('findAll', type: internalType, withParent: label);

    late List<T>? models;

    if (!shouldLoadRemoteAll(remote!, params, headers) || background) {
      models = localAdapter.findAll()?.toImmutableList();
      if (models != null) {
        log(label,
            'returned ${models.toShortLog()} from local storage${background ? ' and loading in the background' : ''}');
      }
      if (!background) {
        return models;
      }
    }

    final future = sendRequest<List<T>>(
      baseUrl.asUri / urlForFindAll(params) & params,
      method: methodForFindAll(params),
      headers: headers,
      label: label,
      onSuccess: (data, label) async {
        if (syncLocal!) {
          await localAdapter.clear();
        }
        onSuccess ??= (data, label, _) => this.onSuccess<List<T>>(data, label);
        return onSuccess!.call(data, label, this as RemoteAdapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) => this.onError<List<T>>(e, label);
        return onError!.call(e, label, this as RemoteAdapter<T>);
      },
    );

    if (background && models != null) {
      // ignore: unawaited_futures
      future.then((_) => Future.value(_));
      return models;
    } else {
      return await future ?? <T>[];
    }
  }

  Future<T?> findOne(
    Object id, {
    bool? remote,
    bool? background,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) async {
    remote ??= _remote;
    background ??= false;
    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    final resolvedId = _resolveId(id);
    late T? model;

    label = DataRequestLabel('findOne',
        type: internalType, id: resolvedId?.toString(), withParent: label);

    if (!shouldLoadRemoteOne(id, remote!, params, headers) || background) {
      final key = graph.getKeyForId(internalType, resolvedId,
          keyIfAbsent: id is T ? id._key : null);
      model = localAdapter.findOne(key);
      if (model != null) {
        log(label,
            'returned from local storage${background ? ' and loading in the background' : ''}');
      }
      if (!background) {
        return model;
      }
    }

    final future = sendRequest(
      baseUrl.asUri / urlForFindOne(id, params) & params,
      method: methodForFindOne(id, params),
      headers: headers,
      label: label,
      onSuccess: (data, label) {
        onSuccess ??= (data, label, _) => this.onSuccess<T>(data, label);
        return onSuccess!.call(data, label, this as RemoteAdapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) => this.onError<T>(e, label);
        return onError!.call(e, label, this as RemoteAdapter<T>);
      },
    );

    if (background && model != null) {
      // ignore: unawaited_futures
      future.then((_) => Future.value(_));
      return model;
    } else {
      return await future;
    }
  }

  FutureOr<T?> onSuccessOne(Object? data, DataRequestLabel? label) =>
      onSuccess<T>(data, label);

  Future<T> save(
    T model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) async {
    remote ??= _remote;

    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    // ensure model is saved
    localAdapter.save(model);

    label = DataRequestLabel('save',
        type: internalType,
        id: model.id?.toString(),
        model: model,
        withParent: label);

    if (remote == false) {
      log(label, 'saved in local storage only');
      return model;
    }

    final serialized = await serialize(model);
    final body = json.encode(serialized);

    final uri = baseUrl.asUri / urlForSave(model.id, params) & params;
    final method = methodForSave(model.id, params);

    final result = await sendRequest<T>(
      uri,
      method: method,
      headers: headers,
      body: body,
      label: label,
      onSuccess: (data, label) {
        onSuccess ??= (data, label, _) => this.onSuccess<T>(data, label);
        return onSuccess!.call(data, label, this as RemoteAdapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) => this.onError<T>(e, label);
        return onError!.call(e, label, this as RemoteAdapter<T>);
      },
    );
    return result ?? model;
  }

  Future<T?> delete(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    OnSuccessOne<T>? onSuccess,
    OnErrorOne<T>? onError,
    DataRequestLabel? label,
  }) async {
    remote ??= _remote;

    params = await defaultParams & params;
    headers = await defaultHeaders & headers;

    final id = _resolveId(model);
    final key = keyForModelOrId(model);

    label = DataRequestLabel('delete',
        type: internalType, id: id.toString(), withParent: label);

    if (key != null) {
      if (remote == false) {
        log(label, 'deleted in local storage only');
      }
      await localAdapter.delete(key);
    }

    if (remote == true && id != null) {
      return await sendRequest(
        baseUrl.asUri / urlForDelete(id, params) & params,
        method: methodForDelete(id, params),
        headers: headers,
        label: label,
        onSuccess: (data, label) {
          onSuccess ??= (data, label, _) => this.onSuccess<T>(data, label);
          return onSuccess!.call(data, label, this as RemoteAdapter<T>);
        },
        onError: (e, label) async {
          onError ??= (e, label, _) => this.onError<T>(e, label);
          return onError!.call(e, label, this as RemoteAdapter<T>);
        },
      );
    }
    return null;
  }

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
  Future<R?> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String>? headers,
    String? body,
    _OnSuccessGeneric<R>? onSuccess,
    _OnErrorGeneric<R>? onError,
    bool omitDefaultParams = false,
    DataRequestLabel? label,
  }) async {
    // defaults
    headers ??= await defaultHeaders;
    final params =
        omitDefaultParams ? <String, dynamic>{} : await defaultParams;

    label ??= DataRequestLabel('custom', type: internalType);
    onSuccess ??= this.onSuccess;
    onError ??= this.onError;

    http.Response? response;
    Object? data;
    Object? error;
    StackTrace? stackTrace;

    final client = _isTesting ? read(httpClientProvider)! : httpClient;

    log(label,
        'requesting${_logLevel > 1 ? ' [HTTP ${method.toShortString()}] $uri' : ''}');

    try {
      final request = http.Request(method.toShortString(), uri & params);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = body;
      }
      final stream = await client.send(request);
      response = await http.Response.fromStream(stream);
    } catch (err, stack) {
      error = err;
      stackTrace = stack;
    } finally {
      client.close();
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

    if (error == null && code != null && code >= 200 && code < 300) {
      return onSuccess(data, label);
    } else {
      if (isOfflineError(error)) {
        // queue a new operation if:
        //  - this is a network error and we're offline
        //  - the request was not a find
        if (method != DataRequestMethod.GET) {
          OfflineOperation<T>(
            httpRequest: '${method.toShortString()} $uri',
            label: label,
            body: body,
            headers: headers,
            onSuccess: onSuccess as _OnSuccessGeneric<T>,
            onError: onError as _OnErrorGeneric<T>,
            adapter: this as RemoteAdapter<T>,
          ).add();
        }

        // wrap error in an OfflineException
        final offlineException = OfflineException(error: error!);

        // call error handler but do not return it
        // (this gives the user the chance to present
        // a UI element to retry fetching, for example)
        onError(offlineException, label);

        // instead return a fallback model from local storage
        switch (label.kind) {
          case 'findAll':
            return findAll(remote: false) as Future<R?>;
          case 'findOne':
          case 'save':
            return label.model as R?;
          default:
            return null;
        }
      }

      // if it was not a network error
      // remove all operations with this request
      OfflineOperation.remove(label, this as RemoteAdapter<T>);

      final e = DataException(error ?? data!,
          stackTrace: stackTrace, statusCode: code);
      log(label, '$e${_logLevel > 1 ? ' $uri' : ''}');
      if (_logLevel > 1 && stackTrace != null) {
        log(label, stackTrace.toString());
      }
      return await onError(e, label);
    }
  }

  FutureOr<R?> onSuccess<R>(Object? data, DataRequestLabel? label) async {
    // remove all operations with this label
    OfflineOperation.remove(label!, this as RemoteAdapter);

    if (label.kind == 'save') {
      if (label.model == null) {
        return null;
      }
      var model = label.model as T;

      if (data == null) {
        // return original model if response was empty
        return model as R?;
      }

      // deserialize already inits models
      // if model had a key already, reuse it
      final deserialized = await deserialize(data as Map<String, dynamic>);
      model = deserialized.model!.was(model).saveLocal();

      log(label, 'saved in local storage and remote');
      return model as R?;
    }

    if (label.kind == 'delete') {
      log(label, 'deleted in local storage and remote');
      return null;
    }

    final deserialized = await deserialize(data);
    deserialized._log(this as RemoteAdapter, label);

    final isFindAll = label.kind.startsWith('findAll');
    final isFindOne = label.kind.startsWith('findOne');
    final isCustom = label.kind == 'custom';

    if (isFindAll || (isCustom && deserialized.model == null)) {
      for (final model in [...deserialized.models, ...deserialized.included]) {
        model.saveLocal();
      }
      return deserialized.models as R?;
    }

    if (isFindOne || (isCustom && deserialized.model != null)) {
      for (final model in [...deserialized.models, ...deserialized.included]) {
        model.saveLocal();
      }
      return deserialized.model as R?;
    }

    return null;
  }

  /// Implements global request error handling.
  ///
  /// Defaults to throw [e] unless it is an HTTP 404
  /// or an `OfflineException`.
  ///
  /// NOTE: `onError` arguments throughout the API are used
  /// to override this default behavior.
  FutureOr<R?> onError<R>(
    DataException e,
    DataRequestLabel? label,
  ) {
    if (e.statusCode == 404 || e is OfflineException) {
      return null;
    }
    throw e;
  }

  void log(DataRequestLabel label, String message, {int logLevel = 1}) {
    if (_logLevel >= logLevel) {
      final now = DateTime.now();
      final timestamp =
          '${now.second.toString().padLeft(2, '0')}:${now.millisecond.toString().padLeft(3, '0')}';
      print('$timestamp ${' ' * label.indentation * 2}[$label] $message');
    }
  }

  // model
  final random = math.Random();

  static int kMinKey = -9223372035854775807;

  T initModel(T model, {bool save = true}) {
    // ignore if already initialized
    if (model._isInitialized) return model;

    model.__key = model.id != null
        ? int.tryParse(model.id!.toString())
        : (-9223372036854775807 + random.nextInt(1000000000));
    _initializeRelationships(model);
    return model;
  }

  void _initializeRelationships(T model) {
    final metadatas = localAdapter.fieldMetas.relationships.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(model);
      relationship?.initialize(
        owner: model,
        name: metadata.name,
        inverseName: metadata.inverseName,
      );
    }
  }

  // offline

  /// Determines whether [error] was an offline error.
  @protected
  @visibleForTesting
  bool isOfflineError(Object? error) {
    // timeouts via http's `connectionTimeout` are
    // also socket exceptions
    // we check the exception like this in order not to import `dart:io`
    final err = error.toString();
    return err.startsWith('SocketException') ||
        err.startsWith('Connection closed before full header was received') ||
        err.startsWith('HandshakeException');
  }

  @protected
  @visibleForTesting
  @nonVirtual
  Set<OfflineOperation<T>> get offlineOperations {
    return {};
    // final node = graph._getNode(_offlineAdapterKey);
    // return node
    //     .map((e) {
    //       // extract type from e.g. _offline:findOne/users#3@d7bcc9
    //       final label = DataRequestLabel.parse(e.from.denamespace());
    //       if (label.type == internalType) {
    //         // get first edge value
    //         final map = json.decode(e.tos.first) as Map<String, dynamic>;
    //         return OfflineOperation<T>.fromJson(
    //             label, map, this as RemoteAdapter<T>);
    //       }
    //     })
    //     .filterNulls
    //     .toSet();
  }

  Object? _resolveId(Object obj) {
    return obj is T ? obj.id : obj;
  }

  @protected
  @visibleForTesting
  @nonVirtual
  int? keyForModelOrId(Object model) {
    if (model is T) {
      return model.__key;
    } else {
      final id = _resolveId(model);
      if (id != null) {
        // keyIfAbsent: DataHelpers.generateKey<T>()
        return graph.getKeyForId(internalType, id)!;
      } else {
        return null;
      }
    }
  }

  bool get _isTesting {
    return read(httpClientProvider) != null;
  }
}

/// When this provider is non-null it will override
/// all [_RemoteAdapter.httpClient] overrides;
/// it is useful for providing a mock client for testing
final httpClientProvider = Provider<http.Client?>((_) => null);
