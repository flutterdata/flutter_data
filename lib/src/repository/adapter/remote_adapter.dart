part of flutter_data;

mixin RemoteAdapter<T extends DataSupport<T>> on Repository<T> {
  @protected
  @visibleForTesting
  String get baseUrl => throw UnsupportedError('Please override baseUrl');

  @protected
  @visibleForTesting
  String urlForFindAll(params) => '$type';

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  @protected
  @visibleForTesting
  String urlForFindOne(id, params) => '$type/$id';

  @protected
  @visibleForTesting
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  @protected
  @visibleForTesting
  String urlForSave(id, params) => id != null ? '$type/$id' : type;

  @protected
  @visibleForTesting
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  @protected
  @visibleForTesting
  String urlForDelete(id, params) => '$type/$id';

  @protected
  @visibleForTesting
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  @protected
  @visibleForTesting
  Map<String, dynamic> get params => {};

  @protected
  @visibleForTesting
  Map<String, String> get headers => {'Content-Type': 'application/json'};

  // serialization

  @override
  Map<String, dynamic> serialize(T model) {
    final map = localSerialize(model);

    final relationships = <String, dynamic>{};

    for (final relEntry in relationshipsFor().entries) {
      final field = relEntry.key;
      final key = keyForField(field);
      if (map[field] != null) {
        if (relEntry.value['kind'] == 'HasMany') {
          final dataIdKeys = List<String>.from(map[field] as Iterable);
          relationships[key] = dataIdKeys.map(manager.getId);
        } else if (relEntry.value['kind'] == 'BelongsTo') {
          final dataIdKey = map[field].toString();
          relationships[key] = manager.getId(dataIdKey);
        }
      }
      map.remove(field);
    }

    return map..addAll(relationships);
  }

  @override
  DeserializedData<T, DataSupport<dynamic>> deserialize(dynamic data,
      {String key, bool save = true}) {
    final result = DeserializedData<T, DataSupport<dynamic>>([], included: []);

    Object addIncluded(id, Repository repository) {
      if (id is Map) {
        final model = repository.localDeserialize(id as Map<String, dynamic>);
        result.included.add(
            model.init(manager: manager, key: key, save: save) as DataSupport);
        return model.id;
      }
      return id;
    }

    if (data is Map) {
      data = [data];
    }

    for (final mapIn in (data as Iterable)) {
      final mapOut = <String, dynamic>{};

      final relationshipKeys = relationshipsFor().keys;

      for (final mapInKey in mapIn.keys) {
        final mapOutKey = fieldForKey(mapInKey.toString());

        if (relationshipKeys.contains(mapOutKey)) {
          final metadata = relationshipsFor()[mapOutKey];
          final _type = metadata['type'] as String;

          if (metadata['kind'] == 'BelongsTo') {
            final id = addIncluded(mapIn[mapInKey], relatedRepositories[_type]);

            // transform ids into keys
            mapOut[mapOutKey] = manager.getKeyForId(_type, id,
                keyIfAbsent: Repository.generateKey(_type));
          }

          if (metadata['kind'] == 'HasMany') {
            mapOut[mapOutKey] = (mapIn[mapInKey] as Iterable)?.map((id) {
              id = addIncluded(id, relatedRepositories[_type]);
              return manager.getKeyForId(_type, id,
                  keyIfAbsent: Repository.generateKey(_type));
            })?.toImmutableList();
          }
        } else {
          // regular field mapping
          mapOut[mapOutKey] = mapIn[mapInKey];
        }
      }
      final model = localDeserialize(mapOut);
      result.models.add(model.init(manager: manager, key: key, save: save));
    }

    return result;
  }

  @protected
  @visibleForTesting
  String get identifierSuffix => '_id';

  Map<String, Map<String, Object>> get _belongsTos => Map.fromEntries(
      relationshipsFor().entries.where((e) => e.value['kind'] == 'BelongsTo'));

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
  @visibleForTesting
  bool shouldLoadRemoteAll(
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  @protected
  @visibleForTesting
  bool shouldLoadRemoteOne(
    dynamic id,
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
  ) =>
      remote;

  // repository implementation

  @override
  Future<List<T>> findAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;
    params = this.params & params;
    headers = this.headers & headers;

    if (!shouldLoadRemoteAll(remote, params, headers)) {
      return localFindAll();
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
      return deserialize(data).models;
    });
  }

  @override
  Future<T> findOne(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    assert(model != null);
    remote ??= _remote;
    params = this.params & params;
    headers = this.headers & headers;

    final id = model is T ? model.id : model;

    if (!shouldLoadRemoteOne(id, remote, params, headers)) {
      final key =
          manager.getKeyForId(type, id) ?? (model is T ? model._key : null);
      if (key == null) {
        return null;
      }
      return localFindOne(key);
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
      return deserialize(data as Map<String, dynamic>).model;
    });
  }

  @override
  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;
    params = this.params & params;
    headers = this.headers & headers;

    _initModel(model);
    localSave(model._key, model);

    if (remote == false) {
      return model;
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
        return _initModel(model);
      }
      // deserialize already inits models
      // if model had a key already, reuse it
      final newModel =
          deserialize(data as Map<String, dynamic>, key: model._key).model;
      if (model._key != null && model._key != newModel._key) {
        // in the unlikely case where supplied key couldn't be used
        // ensure "old" copy of model carries the updated key
        manager.removeKey(model._key);
        model._key = newModel._key;
      }
      return newModel;
    });
  }

  @override
  Future<void> delete(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    remote ??= _remote;
    params = this.params & params;
    headers = this.headers & headers;

    final id = model is T ? model.id : model;
    final key =
        manager.getKeyForId(type, id) ?? (model is T ? model._key : null);

    if (key == null) {
      return;
    }

    localDelete(key);

    if (remote && id != null) {
      manager.removeId(type, id);
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

  @override
  Map<dynamic, T> dumpBox() => box.toMap();

  // utils

  @protected
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
  Future<R> withHttpClient<R>(OnRequest<R> onRequest) async {
    final client = http.Client();
    try {
      return await onRequest(client);
    } finally {
      client.close();
    }
  }

  @protected
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
}
