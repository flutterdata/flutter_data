part of flutter_data;

/// An adapter base class for all remote operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_RemoteAdapter.findAll] or [_RemoteAdapter.save]
///  - Configuration methods and getters like [_RemoteAdapter.baseUrl] or [_RemoteAdapter.urlForFindAll]
///  - Serialization methods like [_RemoteAdapterSerialization.serialize]
///  - Watch methods such as [Repository.watchOneNotifier]
///  - Access to the [_RemoteAdapter.core] for subclasses or mixins
///
/// This class is meant to be extended via mixing in new adapters.
/// This can be done with the [DataRepository] annotation on a [DataModelMixin] class:
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
class RemoteAdapter<T extends DataModelMixin<T>> = _RemoteAdapter<T>
    with _RemoteAdapterSerialization<T>, _RemoteAdapterWatch<T>;

abstract class _RemoteAdapter<T extends DataModelMixin<T>> with _Lifecycle {
  @protected
  _RemoteAdapter(this.localAdapter, [this._internalHolder]);

  @protected
  @visibleForTesting
  @nonVirtual
  final LocalAdapter<T> localAdapter;

  /// A [CoreNotifier] instance also available to adapters
  @protected
  @nonVirtual
  CoreNotifier get core => localAdapter.core;

  // None of these fields below can be late finals as they might be re-initialized
  Map<String, RemoteAdapter>? _adapters;
  bool? _remote;
  Ref? _ref;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, RemoteAdapter> get adapters => _adapters!;

  /// Give access to the dependency injection system
  @nonVirtual
  Ref get ref => _ref!;

  /// INTERNAL: DO NOT USE
  @visibleForTesting
  @protected
  @nonVirtual
  String get internalType => DataHelpers.getInternalType<T>();

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

  @override
  var isInitialized = false;

  @mustCallSuper
  Future<void> onInitialized() async {}

  @mustCallSuper
  @nonVirtual
  Future<RemoteAdapter<T>> initialize(
      {bool? remote,
      required Map<String, RemoteAdapter> adapters,
      required Ref ref}) async {
    if (isInitialized) return this as RemoteAdapter<T>;

    // initialize attributes
    _adapters = adapters;
    _remote = remote ?? true;
    _ref = ref;

    await localAdapter.initialize();

    // hook for clients
    await onInitialized();

    return this as RemoteAdapter<T>;
  }

  @override
  void dispose() {
    localAdapter.dispose();
  }

  // serialization interface

  /// Returns a [DeserializedData] object when deserializing a given [data].
  ///
  @protected
  @visibleForTesting
  Future<DeserializedData<T>> deserialize(Object? data, {String? key});

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

  Future<List<T>> findAll({
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

    late List<T> models;

    if (shouldLoadRemoteAll(remote!, params, headers) == false || background) {
      models = findAllLocal();
      log(label,
          'returned ${models.toShortLog()} from local storage${background ? ' and loading in the background' : ''}');
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
          localAdapter.clear();
        }
        onSuccess ??= (data, label, _) async {
          final result = await this.onSuccess<List<T>>(data, label);
          return result as List<T>;
        };
        return onSuccess!.call(data, label, this as RemoteAdapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) async {
          final result = await this.onError<List<T>>(e, label);
          return result as List<T>;
        };
        return onError!.call(e, label, this as RemoteAdapter<T>);
      },
    );

    if (background) {
      // ignore: unawaited_futures
      future.then((_) => Future.value(_));
      return models;
    } else {
      return await future ?? <T>[];
    }
  }

  List<T> findAllLocal() {
    return localAdapter.findAll().toImmutableList();
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

    late T? model;

    label = DataRequestLabel('findOne',
        type: internalType, id: _resolveId(id)?.toString(), withParent: label);

    if (shouldLoadRemoteOne(id, remote!, params, headers) == false ||
        background) {
      model = findOneLocal(id);
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

    if (background) {
      // ignore: unawaited_futures
      future.then((_) => Future.value(_));
      return model;
    } else {
      return await future;
    }
  }

  T? findOneLocal(Object id) {
    final key = core.getKeyForId(internalType, id);
    return localAdapter.findOne(key);
  }

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
    localAdapter.save(model._key!, model);

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

  T saveLocal(T model, {bool notify = true}) {
    if (model._key == null) {
      throw Exception("Model must be initialized:\n\n$model");
    }
    localAdapter.save(model._key!, model, notify: notify);
    return model;
  }

  Future<void> saveManyLocal(Iterable<T> models, {bool notify = true}) {
    return localAdapter.saveMany(models, notify: notify);
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
    final key = localAdapter.core.keyForModelOrId(internalType, model);

    label = DataRequestLabel('delete',
        type: internalType, id: id.toString(), withParent: label);

    if (remote == false) {
      log(label, 'deleted in local storage only');
    }
    localAdapter.delete(key);

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

  void deleteLocal(T model, {bool notify = true}) {
    localAdapter.delete(model._key!, notify: notify);
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
    Object? body,
    _OnSuccessGeneric<R>? onSuccess,
    _OnErrorGeneric<R>? onError,
    bool omitDefaultParams = false,
    bool returnBytes = false,
    DataRequestLabel? label,
    bool closeClientAfterRequest = true,
  }) async {
    // defaults
    headers ??= await defaultHeaders;
    final params =
        omitDefaultParams ? <String, dynamic>{} : await defaultParams;

    label ??= DataRequestLabel('custom', type: internalType);
    onSuccess ??= this.onSuccess;
    onError ??= this.onError;

    http.Response? response;
    Object? responseBody;
    Object? error;
    StackTrace? stackTrace;

    final client = _isTesting ? ref.read(httpClientProvider)! : httpClient;

    log(label,
        'requesting${_logLevel > 1 ? ' [HTTP ${method.toShortString()}] $uri' : ''}');

    try {
      final request = http.Request(method.toShortString(), uri & params);
      request.headers.addAll(headers);

      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is List) {
          request.bodyBytes = body.cast<int>();
        } else if (body is Map) {
          request.bodyFields = body.cast<String, String>();
        } else {
          throw ArgumentError('Invalid request body "$body".');
        }
      }

      final stream = await client.send(request);
      response = await http.Response.fromStream(stream);
    } catch (err, stack) {
      error = err;
      stackTrace = stack;
    } finally {
      if (closeClientAfterRequest) {
        client.close();
      }
    }

    // response handling

    var contentType = '';

    try {
      if (response != null) {
        contentType = response.headers['content-type'] ?? 'application/json';

        responseBody = await Isolate.run(() {
          if (returnBytes) {
            return response!.bodyBytes;
          } else if (response!.body.isNotEmpty) {
            final body = response.body;
            if (contentType.contains('json')) {
              return json.decode(body);
            } else {
              return body;
            }
          }
          return null;
        });
      }
    } on FormatException catch (e, stack) {
      error = e;
      stackTrace = stack;
    }

    final code = response?.statusCode;

    if (error == null && code != null && code >= 200 && code < 400) {
      final data = DataResponse(
        body: responseBody,
        statusCode: code,
        headers: {...?response?.headers, 'content-type': contentType},
      );
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
            timestamp: DateTime.now().millisecondsSinceEpoch,
            body: body?.toString(),
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

      final e = DataException(error ?? responseBody ?? '',
          stackTrace: stackTrace, statusCode: code);
      final sb = StringBuffer(e);
      if (_logLevel > 1) {
        sb.write(' $uri');
        if (stackTrace != null) {
          sb.write(stackTrace);
        }
      }
      log(label, sb.toString());

      return await onError(e, label);
    }
  }

  FutureOr<R?> onSuccess<R>(
      DataResponse response, DataRequestLabel label) async {
    // remove all operations with this label
    OfflineOperation.remove(label, this as RemoteAdapter);

    final body = response.body;

    // this will happen when `returnBytes` is requested
    if (body is Uint8List) {
      return response as R;
    }

    if (label.kind == 'save') {
      if (label.model == null) {
        return null;
      }
      if (body == null) {
        // return original model if response was empty
        return label.model as R?;
      }

      final data = await deserialize(body as Map<String, dynamic>,
          key: label.model!._key);
      final model = data.model!;

      // TODO group?
      // if there has been a migration to a new key, delete the old one
      if (model._key != label.model!._key) {
        localAdapter.deleteKeys({label.model!._key!});
      }
      model.saveLocal();

      log(label, 'saved in local storage and remote');

      return model as R?;
    }

    if (label.kind == 'delete') {
      log(label, 'deleted in local storage and remote');
      return null;
    }

    final isFindAll = label.kind.startsWith('findAll');
    final isFindOne = label.kind.startsWith('findOne');
    final isCustom = label.kind == 'custom';

    final adapter = this as RemoteAdapter;

    // custom non-JSON request, return as-is
    if (isCustom &&
        !(response.headers['content-type']?.contains('json') ?? false)) {
      return response.body as R?;
    }

    // TODO test: not properly deserializing findAll with relationship references (see example app)
    final deserialized = await deserialize(body);

    if (isFindAll || (isCustom && deserialized.model == null)) {
      await _saveDeserialized(deserialized);
      deserialized._log(adapter, label);

      late R? models;
      if (response.statusCode == 304) {
        models = await adapter.findAll(remote: false) as R?;
      } else {
        models = deserialized.models as R?;
      }
      return models;
    }

    if (isFindOne || (isCustom && deserialized.model != null)) {
      await _saveDeserialized(deserialized);
      deserialized._log(adapter, label);

      late R? model;
      if (response.statusCode == 304) {
        model = await adapter.findOne(label.id!, remote: false) as R?;
      } else {
        model = deserialized.model as R?;
      }
      return model;
    }

    return null;
  }

  Future<void> _saveDeserialized(DeserializedData deserialized) async {
    final models = [...deserialized.models, ...deserialized.included];
    if (models.isEmpty) return;
    await logTimeAsync('[_saveDeserialized] writing ${models.length} models',
        () async {
      await localAdapter.saveMany(models.cast());
    });
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

  /// After model initialization hook
  @protected
  void onModelInitialized(T model) {}

  // offline

  /// Determines whether [error] was an offline error.
  @protected
  @visibleForTesting
  bool isOfflineError(Object? error) {
    final commonExceptions = [
      // timeouts via http's `connectionTimeout` are also socket exceptions
      'SocketException',
      'HttpException',
      'HandshakeException',
      'TimeoutException',
    ];

    // we check exceptions with strings to avoid importing `dart:io`
    final err = error.runtimeType.toString();
    return commonExceptions.any(err.contains);
  }

  @protected
  @visibleForTesting
  @nonVirtual
  Set<OfflineOperation<T>> get offlineOperations {
    // TODO restore
    final edges =
        []; //localAdapter.storage.edgesFor([(_offlineAdapterKey, null)]);
    return edges
        .map((e) {
          try {
            // extract type from e.g. _offline:findOne/users#3@d7bcc9
            final label = DataRequestLabel.parse(e.name.denamespace());
            if (label.type == internalType) {
              // get first edge value
              final map = json.decode(e.to) as Map<String, dynamic>;
              return OfflineOperation<T>.fromJson(
                  label, map, this as RemoteAdapter<T>);
            }
          } catch (_) {
            // TODO restore
            // if there were any errors parsing labels or json ignore and remove
            // localAdapter.storage.removeEdgesFor([(_offlineAdapterKey, e.name)]);
          }
        })
        .nonNulls
        .toSet();
  }

  Object? _resolveId(Object obj) {
    return obj is T ? obj.id : obj;
  }

  bool get _isTesting {
    return ref.read(httpClientProvider) != null;
  }
}

/// When this provider is non-null it will override
/// all [_RemoteAdapter.httpClient] overrides;
/// it is useful for providing a mock client for testing
final httpClientProvider = Provider<http.Client?>((_) => null);
