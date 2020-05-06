part of flutter_data;

mixin RemoteAdapter<T extends DataSupportMixin<T>> on Repository<T> {
  @override
  String get baseUrl => throw UnsupportedError('Please implement baseUrl');

  @override
  String urlForFindAll(params) => '$type';
  @override
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  @override
  String urlForFindOne(id, params) => '$type/$id';
  @override
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  @override
  String urlForSave(id, params) => id != null ? '$type/$id' : type;
  @override
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  @override
  String urlForDelete(id, params) => '$type/$id';
  @override
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  @override
  Map<String, dynamic> get params => {};
  @override
  Map<String, dynamic> get headers => {};

  // serialization

  @override
  Map<String, dynamic> serialize(T model) => super.serialize(model);

  @override
  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models) =>
      models.map(serialize);

  @override
  T deserialize(dynamic object, {String key, bool initialize = true}) {
    final map = Map<String, dynamic>.from(object as Map);
    final model = super.deserialize(map);
    if (initialize) {
      // important to initialize (esp for "included" models)
      return _init(model, key: key, save: true);
    }
    return model;
  }

  @override
  Iterable<T> deserializeCollection(object) =>
      (object as Iterable).map(deserialize);

  @override
  Future<T> findOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    assert(id != null);

    remote ??= _remote;
    final dataId = manager.dataId<T>(id);

    if (remote == false) {
      final model = box.get(dataId.key);
      if (model == null) {
        // TODO should be handled by DataId
        dataId.delete();
        return null;
      }
      return _init(model, save: false);
    }

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
      return deserialize(data, key: dataId.key);
    });
  }

  @override
  Future<List<T>> findAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    remote ??= _remote;

    if (remote == false) {
      return box.values.map(_init).toList();
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
      return deserializeCollection(data).toList();
    });
  }

  @override
  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    remote ??= _remote;
    final key = model.key;

    if (remote == false) {
      return _init(model, key: key, save: true);
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
        return model;
      }
      // deserialize already inits models
      return deserialize(data as Map<String, dynamic>, key: key);
    });
  }

  @override
  Future<void> delete(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    remote ??= _remote;
    final dataId = manager.dataId<T>(id);

    // ignore: unawaited_futures
    box.delete(dataId.key);
    dataId?.delete();

    if (remote) {
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

  @protected
  Map<String, String> parseQueryParameters(Map<String, dynamic> params) {
    params ??= const {};

    return params.entries.fold<Map<String, String>>({}, (acc, e) {
      if (e.value is Map<String, dynamic>) {
        for (var e2 in (e.value as Map<String, dynamic>).entries) {
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
      Map<String, dynamic> headers,
      String body}) async {
    final _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    var uri = Uri.parse('$_baseUrl$url');

    final _params = this.params & params;
    if (_params.isNotEmpty) {
      uri = uri.replace(queryParameters: parseQueryParameters(_params));
    }
    final _headers = (this.headers & headers).castToString();

    http.Response response;
    switch (method) {
      case DataRequestMethod.HEAD:
        response = await client.head(uri, headers: _headers);
        break;
      case DataRequestMethod.GET:
        response = await client.get(uri, headers: _headers);
        break;
      case DataRequestMethod.PUT:
        response = await client.put(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.POST:
        response = await client.post(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.PATCH:
        response = await client.patch(uri, headers: _headers, body: body);
        break;
      case DataRequestMethod.DELETE:
        response = await client.delete(uri, headers: _headers);
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
