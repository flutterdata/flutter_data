part of flutter_data;

/// An adapter base class for all remote operations for type [T].
///
/// Includes:
///
///  - Remote methods such as [_BaseAdapter.findAll] or [_BaseAdapter.save]
///  - Configuration methods and getters like [_BaseAdapter.baseUrl] or [_BaseAdapter.urlForFindAll]
///  - Serialization methods like [_SerializationAdapter.serialize]
///  - Watch methods such as [_WatchAdapter.watchOneNotifier]
///  - Access to the [_BaseAdapter.core] for subclasses or mixins
///
/// This class is meant to be extended via mixing in new adapters.
/// This can be done with the [DataAdapter] annotation on a [DataModelMixin] class:
///
/// ```
/// @JsonSerializable()
/// @DataAdapter([MyAppAdapter])
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
class Adapter<T extends DataModelMixin<T>> = _BaseAdapter<T>
    with _SerializationAdapter<T>, _WatchAdapter<T>;

abstract class _BaseAdapter<T extends DataModelMixin<T>> with _Lifecycle {
  @protected
  _BaseAdapter(Ref ref, [this._internalHolder])
      : core = ref.read(_coreNotifierProvider),
        storage = ref.read(localStorageProvider);

  @protected
  @visibleForTesting
  final CoreNotifier core;

  @protected
  @visibleForTesting
  final LocalStorage storage;

  bool _stopInitialization = false;

  // None of these fields below can be late finals as they might be re-initialized
  Map<String, Adapter>? _adapters;
  bool? _remote;
  Ref? _ref;

  /// All adapters for the relationship subgraph of [T] and their relationships.
  ///
  /// This [Map] is typically required when initializing new models, and passed as-is.
  @protected
  @nonVirtual
  Map<String, Adapter> get adapters => _adapters!;

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
  int logLevel = 0;

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
  Future<Adapter<T>> initialize(
      {bool? remote,
      required Map<String, Adapter> adapters,
      required Ref ref}) async {
    if (isInitialized) return this as Adapter<T>;

    // initialize attributes
    _adapters = adapters;
    _remote = remote ?? true;
    _ref = ref;

    storage.db.execute('''
      CREATE TABLE IF NOT EXISTS $internalType (
        key INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT
      );
    ''');

    // hook for clients
    await onInitialized();

    return this as Adapter<T>;
  }

  @override
  void dispose() {}

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

  /// Returns all models of type [T].
  ///
  /// If [_BaseAdapter.shouldLoadRemoteAll] (function of [remote]) is `true`,
  /// it will initiate an HTTP call.
  /// Otherwise returns all models of type [T] in local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_BaseAdapter.defaultParams] and [_BaseAdapter.defaultHeaders], respectively.
  ///
  /// For local storage of type [T] to be synchronized to the exact resources
  /// returned from the remote source when using `findAll`, pass `syncLocal: true`.
  /// This call would, for example, reflect server-side resource deletions.
  /// The default is `syncLocal: false`.
  ///
  /// See also: [_BaseAdapter.urlForFindAll], [_BaseAdapter.methodForFindAll].
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
          clearLocal();
        }
        onSuccess ??= (data, label, _) async {
          final result = await this.onSuccess<List<T>>(data, label);
          return result as List<T>;
        };
        return onSuccess!.call(data, label, this as Adapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) async {
          final result = await this.onError<List<T>>(e, label);
          return result as List<T>;
        };
        return onError!.call(e, label, this as Adapter<T>);
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

  /// Returns all models of type [T] in local storage.
  List<T> findAllLocal() {
    throw UnimplementedError('');
  }

  /// Finds many models of type [T] by [keys] in local storage.
  List<T> findManyLocal(Iterable<String> keys) {
    throw UnimplementedError('');
  }

  /// Returns model of type [T] by [id].
  ///
  /// If [_BaseAdapter.shouldLoadRemoteOne] (function of [remote]) is `true`,
  /// it will initiate an HTTP call.
  /// Otherwise returns model of type [T] and [id] in local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_BaseAdapter.defaultParams] and [_BaseAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_BaseAdapter.urlForFindOne], [_BaseAdapter.methodForFindOne].
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
      model = findOneLocalById(id);
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
        return onSuccess!.call(data, label, this as Adapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) => this.onError<T>(e, label);
        return onError!.call(e, label, this as Adapter<T>);
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

  /// Finds model of type [T] by [key] in local storage.
  T? findOneLocal(String? key) {
    final intKey = key?.detypifyKey();
    if (intKey == null) return null;
    final result = storage.db
        .select('SELECT key, data FROM $internalType WHERE key = ?', [intKey]);
    final data = result.firstOrNull?['data'];
    if (data != null) {
      final map = Map<String, dynamic>.from(jsonDecode(data));
      final ds = deserialize(map,
          key: result.firstOrNull?['key'].toString().typifyWith(internalType));
      return ds;
    }
    return null;
  }

  T? findOneLocalById(Object id) {
    final key = core.getKeyForId(internalType, id);
    return findOneLocal(key);
  }

  /// Whether [key] exists in local storage.
  bool exists(String key) {
    throw UnimplementedError('');
  }

  /// Saves [model] of type [T].
  ///
  /// If [remote] is `true`, it will initiate an HTTP call.
  ///
  /// Always persists to local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_BaseAdapter.defaultParams] and [_BaseAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_BaseAdapter.urlForSave], [_BaseAdapter.methodForSave].
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
    saveLocal(model);

    label = DataRequestLabel('save',
        type: internalType,
        id: model.id?.toString(),
        model: model,
        withParent: label);

    if (remote == false) {
      log(label, 'saved in local storage only');
      return model;
    }

    final serialized = await serializeAsync(model);
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
        return onSuccess!.call(data, label, this as Adapter<T>);
      },
      onError: (e, label) async {
        onError ??= (e, label, _) => this.onError<T>(e, label);
        return onError!.call(e, label, this as Adapter<T>);
      },
    );
    return result ?? model;
  }

  /// Saves model of type [T] in local storage.
  ///
  /// By default notifies this modification to the associated [CoreNotifier].
  T saveLocal(T model, {bool notify = true}) {
    if (model._key == null) {
      throw Exception("Model must be initialized:\n\n$model");
    }
    final intKey = model._key!.detypifyKey();

    final map = serialize(model, withRelationships: false);
    final data = jsonEncode(map);
    storage.db.execute(
        'REPLACE INTO $internalType (key, data) VALUES (?, ?)', [intKey, data]);
    return model;
  }

  Future<void> saveManyLocal(Iterable<DataModelMixin> models,
      {bool notify = true}) async {
    throw UnimplementedError('');
  }

  /// Deletes [model] of type [T].
  ///
  /// If [remote] is `true`, it will initiate an HTTP call.
  ///
  /// Always deletes from local storage.
  ///
  /// Arguments [params] and [headers] will be merged with
  /// [_BaseAdapter.defaultParams] and [_BaseAdapter.defaultHeaders], respectively.
  ///
  /// See also: [_BaseAdapter.urlForDelete], [_BaseAdapter.methodForDelete].
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
    final key = core.keyForModelOrId(internalType, model);

    label = DataRequestLabel('delete',
        type: internalType, id: id.toString(), withParent: label);

    if (remote == false) {
      log(label, 'deleted in local storage only');
    }
    deleteLocalByKeys({key});

    if (remote == true && id != null) {
      return await sendRequest(
        baseUrl.asUri / urlForDelete(id, params) & params,
        method: methodForDelete(id, params),
        headers: headers,
        label: label,
        onSuccess: (data, label) {
          onSuccess ??= (data, label, _) => this.onSuccess<T>(data, label);
          return onSuccess!.call(data, label, this as Adapter<T>);
        },
        onError: (e, label) async {
          onError ??= (e, label, _) => this.onError<T>(e, label);
          return onError!.call(e, label, this as Adapter<T>);
        },
      );
    }
    return null;
  }

  /// Deletes model of type [T] from local storage.
  void deleteLocal(T model, {bool notify = true}) {
    throw UnimplementedError('');
  }

  /// Deletes model with [id] from local storage.
  void deleteLocalById(Object id, {bool notify = true}) {
    throw UnimplementedError('');
  }

  /// Deletes models with [keys] from local storage.
  void deleteLocalByKeys(Iterable<String> keys, {bool notify = true}) {
    throw UnimplementedError('');
  }

  /// Deletes all models of type [T] in local storage.
  ///
  /// If you need to clear all models, use the
  /// `adapterProviders` map exposed on your `main.data.dart`.
  Future<void> clearLocal() {
    // leave async in case some impls need to remove files
    throw UnimplementedError('');
  }

  /// Counts all models of type [T] in local storage.
  int get countLocal {
    throw UnimplementedError('');
  }

  /// Gets all keys of type [T] in local storage.
  List<String> get keys {
    throw UnimplementedError('');
  }

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
  /// [onError] can also be supplied to override [_BaseAdapter.onError].
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
        'requesting${logLevel > 1 ? ' [HTTP ${method.toShortString()}] $uri' : ''}');

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
            adapter: this as Adapter<T>,
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
      OfflineOperation.remove(label, this as Adapter<T>);

      final e = DataException(error ?? responseBody ?? '',
          stackTrace: stackTrace, statusCode: code);
      final sb = StringBuffer(e);
      if (logLevel > 1) {
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
    OfflineOperation.remove(label, this as Adapter);

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

      final data = await deserializeAsync(body as Map<String, dynamic>,
          key: label.model!._key);
      final model = data.model!;

      // TODO group?
      // if there has been a migration to a new key, delete the old one
      if (model._key != label.model!._key) {
        deleteLocalByKeys({label.model!._key!});
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

    final adapter = this as Adapter;

    // custom non-JSON request, return as-is
    if (isCustom &&
        !(response.headers['content-type']?.contains('json') ?? false)) {
      return response.body as R?;
    }

    // TODO test: not properly deserializing findAll with relationship references (see example app)
    final deserialized = await deserializeAsync(body);

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
      await saveManyLocal(models.cast());
    });
  }

  // serialize interfaces

  @protected
  @visibleForTesting
  Future<Map<String, dynamic>> serializeAsync(T model,
      {bool withRelationships = true});

  @protected
  @visibleForTesting
  Future<DeserializedData<T>> deserializeAsync(Object? data, {String? key});

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
    if (this.logLevel >= logLevel) {
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
                  label, map, this as Adapter<T>);
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

  //

  @protected
  @nonVirtual
  T internalWrapStopInit(Function fn, {String? key}) {
    _stopInitialization = true;
    late T model;
    try {
      model = fn();
    } finally {
      _stopInitialization = false;
    }
    return initModel(model, key: key);
  }

  @protected
  @nonVirtual
  T initModel(T model, {String? key, Function(T)? onModelInitialized}) {
    if (_stopInitialization) {
      return model;
    }

    // // (before -> after remote save)
    // // (1) if noid -> noid => `key` is the key we want to keep
    // // (2) if id -> noid => use autogenerated key (`key` should be the previous (derived))
    // // so we can migrate rels
    // // (3) if noid -> id => use derived key (`key` should be the previous (autogen'd))
    // // so we can migrate rels

    if (model._key == null) {
      model._key = key ?? core.getKeyForId(internalType, model.id);
      if (model._key != key) {
        _initializeRelationships(model, fromKey: key);
      } else {
        _initializeRelationships(model);
      }

      onModelInitialized?.call(model);
    }
    return model;
  }

  void _initializeRelationships(T model, {String? fromKey}) {
    final metadatas = relationshipMetas.values;
    for (final metadata in metadatas) {
      final relationship = metadata.instance(model);
      if (relationship != null) {
        // if rel was omitted, fill with info of previous key
        // TODO optimize: put outside loop and query edgesFor just once
        if (fromKey != null && relationship._uninitializedKeys == null) {
          // TODO restore
          // final edges = storage.edgesFor({(fromKey, metadata.name)});
          // relationship._uninitializedKeys = edges.map((e) => e.to).toSet();
        }
        relationship.initialize(
          ownerKey: model._key!,
          name: metadata.name,
          inverseName: metadata.inverseName,
        );
      }
    }
  }

  Map<String, dynamic> serialize(T model, {bool withRelationships = true}) {
    throw UnimplementedError('');
  }

  T deserialize(Map<String, dynamic> map, {String? key}) {
    throw UnimplementedError('');
  }

  Map<String, RelationshipMeta> get relationshipMetas {
    throw UnimplementedError('');
  }

  Map<String, dynamic> transformSerialize(Map<String, dynamic> map,
      {bool withRelationships = true}) {
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      if (withRelationships) {
        final ignored = e.value.serialize == false;
        if (ignored) map.remove(key);

        if (map[key] is HasMany) {
          map[key] = (map[key] as HasMany).keys;
        } else if (map[key] is BelongsTo) {
          map[key] = map[key].key;
        }

        if (map[key] == null) map.remove(key);
      } else {
        map.remove(key);
      }
    }
    return map;
  }

  Map<String, dynamic> transformDeserialize(Map<String, dynamic> map) {
    // ensure value is dynamic (argument might come in as Map<String, String>)
    map = Map<String, dynamic>.from(map);
    for (final e in relationshipMetas.entries) {
      final key = e.key;
      final keyset = map[key] is Iterable
          ? {...(map[key] as Iterable)}
          : {if (map[key] != null) map[key].toString()};
      final ignored = e.value.serialize == false;
      map[key] = {
        '_': (map.containsKey(key) && !ignored) ? keyset : null,
      };
    }
    return map;
  }
}

/// When this provider is non-null it will override
/// all [_BaseAdapter.httpClient] overrides;
/// it is useful for providing a mock client for testing
final httpClientProvider = Provider<http.Client?>((_) => null);

/// Annotation on a [DataModelMixin] model to request an [Adapter] be generated for it.
///
/// Takes a list of [adapters] to be mixed into this [Adapter].
/// Public methods of these [adapters] mixins will be made available in the adapter
/// via extensions.
///
/// A classic example is:
///
/// ```
/// @JsonSerializable()
/// @DataAdapter([JSONAPIAdapter])
/// class Todo with DataModel<Todo> {
///   @override
///   final int id;
///   final String title;
///   final bool completed;
///
///   Todo({this.id, this.title, this.completed = false});
/// }
///```
class DataAdapter {
  final List<Type> adapters;
  final bool remote;
  const DataAdapter(this.adapters, {this.remote = true});
}
