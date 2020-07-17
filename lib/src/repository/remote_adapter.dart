part of flutter_data;

class RemoteAdapter<T extends DataSupport<T>>
    with _Lifecycle<RemoteAdapter<T>> {
  @protected
  RemoteAdapter(this._localAdapter);

  final LocalAdapter<T> _localAdapter;

  DataGraphNotifier get _graph => _localAdapter.graph;

  // late finals
  bool _remote;
  bool _verbose;
  Map<String, RemoteAdapter> _adapters;

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
    if (isInitialized) return this;
    _remote = remote ?? true;
    _verbose = verbose ?? true;
    _adapters = adapters;
    this.ref = ref;

    await _localAdapter.initialize();
    // _save();
    await super.initialize();
    return this;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await _localAdapter.dispose();
  }

  // serialization

  @protected
  @visibleForTesting
  Map<String, dynamic> serialize(T model) {
    final map = _localAdapter.serialize(model);

    final relationships = <String, dynamic>{};

    for (final relEntry in _localAdapter.relationshipsFor().entries) {
      final field = relEntry.key;
      final key = keyForField(field);
      if (map[field] != null) {
        if (relEntry.value['kind'] == 'HasMany') {
          final dataIdKeys = List<String>.from(map[field] as Iterable);
          relationships[key] = dataIdKeys.map(_graph.getId).toList();
        } else if (relEntry.value['kind'] == 'BelongsTo') {
          final dataIdKey = map[field].toString();
          relationships[key] = _graph.getId(dataIdKey);
        }
      }
      map.remove(field);
    }

    return map..addAll(relationships);
  }

  @protected
  @visibleForTesting
  DeserializedData<T, DataSupport<dynamic>> deserialize(dynamic data,
      {bool init}) {
    final result = DeserializedData<T, DataSupport<dynamic>>([], included: []);
    init ??= false;

    Object addIncluded(id, RemoteAdapter adapter) {
      if (id is Map) {
        final data =
            adapter.deserialize(id as Map<String, dynamic>, init: init);
        result.included
          ..add(data.model)
          ..addAll(data.included);
        if (init) {
          data.model._initialize(_adapters, save: true);
        }
        return data.model.id;
      }
      return id;
    }

    if (data is Map) {
      data = [data];
    }

    for (final mapIn in (data as Iterable)) {
      final mapOut = <String, dynamic>{};

      final relationshipKeys = _localAdapter.relationshipsFor().keys;

      for (final mapInKey in mapIn.keys) {
        final mapOutKey = fieldForKey(mapInKey.toString());

        if (relationshipKeys.contains(mapOutKey)) {
          final metadata = _localAdapter.relationshipsFor()[mapOutKey];
          final _type = metadata['type'] as String;

          if (metadata['kind'] == 'BelongsTo') {
            final id = addIncluded(mapIn[mapInKey], _adapters[_type]);
            // transform ids into keys
            mapOut[mapOutKey] = _graph.getKeyForId(_type, id,
                keyIfAbsent: DataHelpers.generateKey(_type));
          }

          if (metadata['kind'] == 'HasMany') {
            mapOut[mapOutKey] = (mapIn[mapInKey] as Iterable)?.map((id) {
              id = addIncluded(id, _adapters[_type]);
              return _graph.getKeyForId(_type, id,
                  keyIfAbsent: DataHelpers.generateKey(_type));
            })?.toImmutableList();
          }
        } else {
          // regular field mapping
          mapOut[mapOutKey] = mapIn[mapInKey];
        }
      }

      final model = _localAdapter.deserialize(mapOut);
      if (init) {
        model._initialize(_adapters, save: true);
      }
      result.models.add(model);
    }

    return result;
  }

  @protected
  String get identifierSuffix => '_id';

  Map<String, Map<String, Object>> get _belongsTos =>
      Map.fromEntries(_localAdapter
          .relationshipsFor()
          .entries
          .where((e) => e.value['kind'] == 'BelongsTo'));

  @protected
  @visibleForTesting
  String fieldForKey(String key) {
    if (key.endsWith(identifierSuffix)) {
      final keyWithoutId = key.substring(0, key.length - 3);
      if (_belongsTos.keys.contains(keyWithoutId)) {
        return keyWithoutId;
      }
    }
    return key;
  }

  @protected
  @visibleForTesting
  String keyForField(String field) {
    if (_belongsTos.keys.contains(field)) {
      return '$field$identifierSuffix';
    }
    return field;
  }

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
      final models = _localAdapter.findAll();
      if (init) {
        models._initialize(_adapters, save: true);
      }
      return models;
    }

    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForFindAll(params),
        methodForFindAll(params),
        params: params,
        headers: headers,
      ),
    );

    return withResponse<List<T>>(response, (data) {
      return deserialize(data, init: init).models;
    });
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
          _graph.getKeyForId(type, id) ?? (model is T ? model._key : null);
      if (key == null) {
        return null;
      }
      final newModel = _localAdapter.findOne(key);
      if (init) {
        newModel._initialize(_adapters, save: true);
      }
      return newModel;
    }

    assert(id != null);
    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForFindOne(id, params),
        methodForFindOne(id, params),
        params: params,
        headers: headers,
      ),
    );

    return withResponse<T>(response, (data) {
      return deserialize(data as Map<String, dynamic>, init: init).model;
    });
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
      return model._initialize(_adapters, save: true);
    }

    final body = json.encode(serialize(model));

    final response = await withHttpClient(
      (client) => _executeRequest(
        client,
        urlForSave(model.id, params),
        methodForSave(model.id, params),
        params: params,
        headers: headers,
        body: body,
      ),
    );

    return withResponse<T>(response, (data) {
      if (data == null) {
        // return "old" model if response was empty
        if (init) {
          model._initialize(_adapters, save: true);
        }
        return model;
      }
      // deserialize already inits models
      // if model had a key already, reuse it
      final newModel =
          deserialize(data as Map<String, dynamic>, init: init).model;

      // TODO ensure this is covered y tests
      // in the unlikely case where supplied key couldn't be used
      // ensure "old" copy of model carries the updated key
      if (init && model._key != null && model._key != newModel._key) {
        _graph.removeKey(model._key);
        model._key = newModel._key;
      }
      return newModel;
    });
  }

  @protected
  @visibleForTesting
  Future<void> delete(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    _assertInit();
    remote ??= _remote;
    params = await this.params & params;
    headers = await this.headers & headers;

    final id = model is T ? model.id : model;
    final key =
        _graph.getKeyForId(type, id) ?? (model is T ? model._key : null);

    if (key == null) {
      return;
    }

    _localAdapter.delete(key);

    if (remote && id != null) {
      _graph.removeId(type, id);
      final response = await withHttpClient(
        (client) => _executeRequest(
          client,
          urlForDelete(id, params),
          methodForDelete(id, params),
          params: params,
          headers: headers,
        ),
      );

      return withResponse<void>(response, (_) {
        return;
      });
    }
  }

  // utils

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

  @protected
  @visibleForTesting
  Future<R> withHttpClient<R>(OnRequest<R> onRequest) async {
    final client = http.Client();
    try {
      return await onRequest(client);
    } finally {
      client.close();
    }
  }

  @protected
  @visibleForTesting
  FutureOr<R> withResponse<R>(
      http.Response response, OnResponseSuccess<R> onSuccess) {
    dynamic data;
    dynamic error;

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
        throw DataException(error, response.statusCode);
      }
      return onSuccess(data);
    } else if (code >= 400 && code < 600) {
      throw DataException(error ?? data, response.statusCode);
    } else {
      throw UnsupportedError('Failed request for type $R');
    }
  }

  // helpers

  Future<http.Response> _executeRequest(
      http.Client client, String url, DataRequestMethod method,
      {Map<String, dynamic> params,
      Map<String, String> headers,
      String body}) async {
    final _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    var uri = Uri.parse('$_baseUrl$url');

    if (params.isNotEmpty) {
      uri = uri.replace(queryParameters: parseQueryParameters(params));
    }

    http.Response response;
    switch (method) {
      case DataRequestMethod.HEAD:
        response = await client.head(uri, headers: headers);
        break;
      case DataRequestMethod.GET:
        response = await client.get(uri, headers: headers);
        break;
      case DataRequestMethod.PUT:
        response = await client.put(uri, headers: headers, body: body);
        break;
      case DataRequestMethod.POST:
        response = await client.post(uri, headers: headers, body: body);
        break;
      case DataRequestMethod.PATCH:
        response = await client.patch(uri, headers: headers, body: body);
        break;
      case DataRequestMethod.DELETE:
        response = await client.delete(uri, headers: headers);
        break;
      default:
        response = null;
        break;
    }

    if (_verbose && response != null) {
      print(
          '[flutter_data] $T: ${method.toShortString()} $uri [HTTP ${response.statusCode}]');
    }

    return response;
  }

  // WATCH

  @protected
  @visibleForTesting
  Duration get throttleDuration =>
      Duration(milliseconds: 16); // 1 frame at 60fps

  /// Sort-of-exponential backoff for reads
  @protected
  @visibleForTesting
  Duration readRetryAfter(int i) {
    final list = [0, 1, 2, 2, 2, 2, 2, 4, 4, 4, 8, 8, 16, 16, 24, 36, 72];
    final index = i < list.length ? i : list.length - 1;
    return Duration(seconds: list[index]);
  }

  /// Sort-of-exponential backoff for writes
  @protected
  @visibleForTesting
  Duration writeRetryAfter(int i) => readRetryAfter(i);

  @protected
  @visibleForTesting
  StateNotifier<List<DataGraphEvent>> get throttledGraph =>
      _graph.throttle(throttleDuration);

  // initialize & save

  // var _writeCounter = 0;

  // final _offlineAdapterKey = 'offline:adapter';
  // final _offlineSaveMetadata = 'offline:save';

  void _assertInit() {
    assert(isInitialized, true);
  }

  // void _save() async {
  //   final keys =
  //       manager.getEdge(_offlineAdapterKey, metadata: _offlineSaveMetadata);
  //   for (final key in keys) {
  //     final model = localFindOne(key);
  //     if (model != null) {
  //       await model.save(); // might throw here
  //       manager.removeEdge(_offlineAdapterKey, key,
  //           metadata: _offlineSaveMetadata);
  //       _writeCounter = 0; // reset write counter
  //     }
  //   }
  // }

  // @override
  // Future<T> save(T model,
  //     {bool remote,
  //     Map<String, dynamic> params,
  //     Map<String, String> headers}) async {
  //   try {
  //     return await super
  //         .save(model, remote: remote, params: params, headers: headers);
  //   } on SocketException {
  //     // ensure offline node exists
  //     if (!manager.hasNode(_offlineAdapterKey)) {
  //       manager.addNode(_offlineAdapterKey);
  //     }

  //     // add model's key with offline meta
  //     manager.addEdge(_offlineAdapterKey, keyFor(model),
  //         metadata: _offlineSaveMetadata);

  //     // there was a failure, so call _trySave again
  //     Future.delayed(writeRetryAfter(_writeCounter++), _save);
  //     rethrow;
  //   }
  // }

  // watchers

  var _readCounter = 0;

  DataStateNotifier<List<T>> watchAll(
      {final bool remote,
      final Map<String, dynamic> params,
      final Map<String, String> headers}) {
    _assertInit();
    final _notifier = DataStateNotifier<List<T>>(
      DataState(_localAdapter.findAll()),
      reload: (notifier) async {
        try {
          // ignore: unawaited_futures
          findAll(params: params, headers: headers, remote: remote, init: true);
          _readCounter = 0; // reset counter
          notifier.data = notifier.data.copyWith(isLoading: true);
        } catch (error, stackTrace) {
          if (error is Exception) {
            // TODO find non-dart:io SocketException alternative!
            Future.delayed(readRetryAfter(_readCounter++), notifier.reload);
          }
          // we're only interested in notifying errors
          // as models will pop up via box events
          notifier.data = notifier.data.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
    );

    // kick off
    _notifier.reload();

    throttledGraph.forEach((events) {
      if (!_notifier.mounted) {
        return;
      }

      // filter by keys (that are not IDs)
      final filteredEvents = events.where((event) =>
          event.type.isNode &&
          event.keys.first.startsWith(type) &&
          !event.graph._hasEdge(event.keys.first, metadata: 'key'));

      if (filteredEvents.isEmpty) {
        return;
      }

      final list = _notifier.data.model.toList();

      for (final event in filteredEvents) {
        final key = event.keys.first;
        assert(key != null);
        switch (event.type) {
          case DataGraphEventType.addNode:
            list.add(_localAdapter.findOne(key));
            break;
          case DataGraphEventType.updateNode:
            final idx = list.indexWhere((model) => model?._key == key);
            list[idx] = _localAdapter.findOne(key);
            break;
          case DataGraphEventType.removeNode:
            list..removeWhere((model) => model?._key == key);
            break;
          default:
        }
      }

      _notifier.data = _notifier.data.copyWith(model: list, isLoading: false);
    });

    return _notifier;
  }

  DataStateNotifier<T> watchOne(final dynamic model,
      {final bool remote,
      final Map<String, dynamic> params,
      final Map<String, String> headers,
      final AlsoWatch<T> alsoWatch}) {
    _assertInit();
    assert(model != null);

    final id = model is T ? model.id : model;

    // lazy key access
    String _key;
    String key() => _key ??=
        _graph.getKeyForId(type, id) ?? (model is T ? model._key : null);

    final _alsoWatchFilters = <String>{};
    var _relatedKeys = <String>{};

    final _notifier = DataStateNotifier<T>(
      DataState(_localAdapter.findOne(key())),
      reload: (notifier) async {
        if (id == null) return;
        try {
          // ignore: unawaited_futures
          findOne(id,
              params: params, headers: headers, remote: remote, init: true);
          _readCounter = 0; // reset counter
          notifier.data = notifier.data.copyWith(isLoading: true);
        } catch (error, stackTrace) {
          if (error is Exception) {
            // TODO find non-dart:io SocketException alternative!
            Future.delayed(readRetryAfter(_readCounter++), notifier.reload);
          }
          // we're only interested in notifying errors
          // as models will pop up via box events
          notifier.data = notifier.data.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
    );

    void _initializeRelationshipsToWatch(T model) {
      if (alsoWatch != null && _alsoWatchFilters.isEmpty) {
        _alsoWatchFilters.addAll(alsoWatch(model).map((rel) => rel._name));
      }
    }

    // kick off

    // try to find relationships to watch
    if (_notifier.data.model != null) {
      _initializeRelationshipsToWatch(_notifier.data.model);
    }

    // trigger local + async loading
    _notifier.reload();

    // start listening to graph for further changes
    throttledGraph.forEach((events) {
      if (!_notifier.mounted) {
        return;
      }

      // buffers
      var modelBuffer = _notifier.data.model;
      var refresh = false;

      for (final event in events) {
        if (event.keys.containsFirst(key())) {
          // add/update
          if (event.type == DataGraphEventType.addNode ||
              event.type == DataGraphEventType.updateNode) {
            final model = _localAdapter.findOne(key());
            if (model != null) {
              _initializeRelationshipsToWatch(model);
              modelBuffer = model;
            }
          }

          // remove
          if (event.type == DataGraphEventType.removeNode &&
              _notifier.data.model != null) {
            modelBuffer = null;
          }

          // changes on specific relationships of this model
          if (_notifier.data.model != null &&
              event.type.isEdge &&
              _alsoWatchFilters.contains(event.metadata)) {
            // calculate current related models
            _relatedKeys = _localAdapter
                .relationshipsFor(_notifier.data.model)
                .values
                .map((meta) => (meta['instance'] as Relationship)?.keys)
                .where((keys) => keys != null)
                .expand((key) => key)
                .toSet();

            refresh = true;
          }
        }

        // updates on all models of specific relationships of this model
        if (event.type == DataGraphEventType.updateNode &&
            _relatedKeys.any(event.keys.contains)) {
          refresh = true;
        }
      }

      // NOTE: because of this comparison, use field equality
      // rather than key equality (which wouldn't update)
      if (modelBuffer != _notifier.data.model || refresh) {
        _notifier.data = _notifier.data
            .copyWith(model: modelBuffer, isLoading: false, exception: null);
      }
    });

    return _notifier;
  }
}

class DataException implements Exception {
  final Object errors;
  final int status;
  const DataException([this.errors = const [], this.status]);

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) || toString() == other.toString();

  @override
  int get hashCode => runtimeType.hashCode ^ status.hashCode ^ errors.hashCode;

  @override
  String toString() {
    return 'DataException: ${status != null ? "[HTTP $status] " : ""}$errors';
  }
}

class DeserializedData<T, I> {
  const DeserializedData(this.models, {this.included});
  final List<T> models;
  final List<I> included;
  T get model => models.single;
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }

typedef OnResponseSuccess<R> = R Function(dynamic);

typedef OnRequest<R> = Future<R> Function(http.Client);

typedef AlsoWatch<T> = List<Relationship> Function(T);

extension _ToStringX on DataRequestMethod {
  String toShortString() => toString().split('.').last;
}
