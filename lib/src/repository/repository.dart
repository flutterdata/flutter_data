part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  String get type => DataId.getType<T>();

  @visibleForTesting
  @protected
  final LocalAdapter<T> localAdapter;
  Repository(this.localAdapter);

  DataStateNotifier<T> _watchOneNotifier;
  DataStateNotifier<List<T>> _watchAllNotifier;

  // url

  String baseUrl = 'http://127.0.0.1:8080/';

  // FIXME when we get late fields
  UrlDesign _urlDesign;
  UrlDesign get urlDesign =>
      _urlDesign ??= PathBasedUrlDesign(Uri.parse(baseUrl));

  String updateHttpMethod = 'PATCH';

  Map<String, String> get headers => {};

  Duration get requestTimeout => Duration(seconds: 8);

  //

  Map<String, dynamic> get relationshipMetadata;

  Map<String, dynamic> serialize(T model) => localAdapter.serialize(model);

  serializeCollection(Iterable<T> models) => models.map(serialize);

  T deserialize(dynamic object, {String key}) {
    final model =
        localAdapter.deserialize(Map<String, dynamic>.from(object as Map));
    return model._init(this, key: key);
  }

  Iterable<T> deserializeCollection(object) =>
      (object as Iterable).map(deserialize);

  @visibleForTesting
  @protected
  DataManager get manager => localAdapter.manager;

  // repository methods

  Future<List<T>> findAll(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) async {
    if (remote == false) {
      return localAdapter.findAll();
    }

    final uri = QueryParameters(params ?? const {}).addToUri(
      urlDesign.collection(type),
    );

    final response = await withHttpClient(
      (client) => client.get(uri, headers: headers ?? this.headers),
    );

    print('[flutter_data] findAll $T: $uri [HTTP ${response.statusCode}]');

    return withResponse<List<T>>(response, (data) {
      return deserializeCollection(data).toList();
    });
  }

  DataStateNotifier<List<T>> watchAll(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    _watchAllNotifier ??= DataStateNotifier<List<T>>();

    final _load = () async {
      if (remote == false) {
        return;
      }
      _watchAllNotifier.state =
          _watchAllNotifier.state.copyWith(isLoading: true);
      // we're only interested in capturing errors
      // as models will pop up via localAdapter.watchAll()
      try {
        await findAll(params: params, headers: headers);
      } catch (e) {
        _watchAllNotifier.state =
            _watchAllNotifier.state.copyWith(exception: DataException(e));
      }
    };

    _watchAllNotifier.state = DataState(
      model: localAdapter.findAll(),
      reload: _load,
    );

    _load();

    localAdapter.watchAll().forEach((model) {
      _watchAllNotifier.state =
          _watchAllNotifier.state.copyWith(model: model, isLoading: false);
    }).catchError((Object e) {
      _watchAllNotifier.state =
          _watchAllNotifier.state.copyWith(exception: DataException(e));
    });
    return _watchAllNotifier;
  }

  // one

  Future<T> findOne(dynamic id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) async {
    assert(id != null);

    if (remote == false) {
      final key = manager.dataId<T>(id).key;
      return localAdapter.findOne(key);
    }

    final uri = QueryParameters(params ?? const {}).addToUri(
      urlDesign.resource(type, id.toString()),
    );

    final response = await withHttpClient(
      (client) => client.get(uri, headers: headers ?? this.headers),
    );

    print('[flutter_data] loadOne $T: $uri [HTTP ${response.statusCode}]');

    // ignore: unnecessary_lambdas
    return withResponse<T>(response, (data) {
      return deserialize(data);
    });
  }

  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    final key = manager.dataId<T>(id).key;
    _watchOneNotifier ??= DataStateNotifier<T>();

    final _load = () async {
      if (remote == false) {
        return;
      }
      _watchOneNotifier.state =
          _watchOneNotifier.state.copyWith(isLoading: true);
      // we're only interested in capturing errors
      // as models will pop up via localAdapter.watchOne(_key)
      try {
        await findOne(id, params: params, headers: headers);
      } catch (e) {
        _watchOneNotifier.state =
            _watchOneNotifier.state.copyWith(exception: DataException(e));
      }
    };

    _watchOneNotifier.state = DataState(
      model: localAdapter.findOne(key),
      reload: _load,
    );

    _load();

    localAdapter.watchOne(key).forEach((model) {
      _watchOneNotifier.state =
          _watchOneNotifier.state.copyWith(model: model, isLoading: false);
    }).catchError((Object e) {
      _watchOneNotifier.state =
          _watchOneNotifier.state.copyWith(exception: DataException(e));
    });
    return _watchOneNotifier;
  }

  // save & delete

  Future<T> save(T model,
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    if (remote == false) {
      return localAdapter._init(model);
    }

    final body = json.encode(serialize(model));

    final queryParams = QueryParameters(params);
    Uri uri;
    if (model.id != null) {
      uri = queryParams.addToUri(urlDesign.resource(type, model.id.toString()));
    } else {
      uri = queryParams.addToUri(urlDesign.collection(type));
    }

    final response = await withHttpClient(
      (client) {
        final _patch = updateHttpMethod == 'PUT' ? client.put : client.patch;
        final _send = model.id != null ? _patch : client.post;
        return _send(uri, headers: headers ?? this.headers, body: body);
      },
    );

    print('[flutter_data] save $T: $uri [HTTP ${response.statusCode}]');

    return withResponse<T>(response, (data) {
      if (data == null) {
        // return "old" model if response was empty
        return localAdapter._init(model);
      }
      // provide key of the existing model
      return deserialize(data as Map<String, dynamic>, key: model.key);
    });
  }

  Future<void> delete(dynamic id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) async {
    // ignore: unawaited_futures
    localAdapter.delete(manager.dataId<T>(id).key);

    if (remote) {
      final uri = urlDesign.resource(type, id.toString());
      final response = await withHttpClient(
        (client) => client.delete(uri, headers: headers ?? this.headers),
      );

      print('[flutter_data] delete $T: $uri [HTTP ${response.statusCode}]');

      return withResponse<void>(response, (_) {
        return;
      });
    }
  }

  @mustCallSuper
  Future<void> dispose() {
    return localAdapter.dispose();
  }

  // helpers

  @protected
  Future<R> withHttpClient<R>(OnRequest<R> onRequest) async {
    final client = http.Client();
    try {
      return await onRequest(client).timeout(requestTimeout);
    } on TimeoutException catch (e) {
      throw DataException(e);
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
}
