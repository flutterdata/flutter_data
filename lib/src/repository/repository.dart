part of flutter_data;

abstract class Repository<T extends DataSupport<T>> with RemoteAdapter<T> {
  @visibleForTesting
  @protected
  final LocalAdapter<T> localAdapter;
  Repository(this.localAdapter);

  // abstract members, to be overriden by adapters

  @visibleForTesting
  @protected
  Map<String, dynamic> relationshipMetadata;

  @visibleForTesting
  @protected
  void setOwnerInRelationships(DataId<T> owner, T model);

  @visibleForTesting
  @protected
  void setOwnerInModel(DataId owner, T model);

  @visibleForTesting
  @protected
  @override
  Locator get locator => manager.locator;

  @visibleForTesting
  @protected
  DataManager get manager => localAdapter.manager;

  // repository methods

  @override
  Future<List<T>> findAll(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) async {
    var _result = localAdapter.findAll();

    if (remote == false) {
      return _result;
    }

    if (_result.isEmpty) {
      _result = await loadAll(params: params, headers: headers);
    } else {
      // load in background
      // ignore: unawaited_futures
      loadAll(params: params, headers: headers);
    }
    return _result;
  }

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    final notifier = DataStateNotifier<List<T>>();

    final _load = () async {
      if (remote == false) {
        return;
      }
      notifier.state = notifier.state.copyWith(isLoading: true);
      // we're only interested in capturing errors
      // as models will pop up via localAdapter.watchAll()
      try {
        await loadAll(params: params, headers: headers);
      } catch (e) {
        notifier.state = notifier.state.copyWith(exception: DataException(e));
      }
    };

    notifier.state = DataState(
      model: localAdapter.findAll(),
      reload: _load,
    );

    _load();

    localAdapter.watchAll().forEach((model) {
      notifier.state = notifier.state.copyWith(model: model, isLoading: false);
    }).catchError((Object e) {
      notifier.state = notifier.state.copyWith(exception: DataException(e));
    });
    return notifier;
  }

  @override
  Future<List<T>> loadAll(
      {Map<String, String> params, Map<String, String> headers}) async {
    final uri = QueryParameters(params ?? const {}).addToUri(
      urlDesign.collection(type),
    );

    final response = await withHttpClient(
      (client) => client.get(uri, headers: headers ?? this.headers),
    );

    print('[flutter_data] findAll $T: $uri [HTTP ${response.statusCode}]');

    return _withResponse<List<T>>(response, (data) {
      final models = (data as Iterable).map((map) {
        return deserialize(
          map as Map<String, dynamic>,
          key: manager.dataId<T>(map['id'].toString()).key,
          relationshipMetadata: relationshipMetadata,
        )._init(this);
      });
      return models.toList();
    });
  }

  // one

  @override
  Future<T> findOne(String id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) async {
    assert(id != null);
    var _result = localAdapter.findOne(manager.dataId<T>(id).key);

    if (remote == false) {
      return _result;
    }

    if (_result == null) {
      _result = await loadOne(id, params: params, headers: headers);
    } else {
      // load in background
      // ignore: unawaited_futures
      loadOne(id, params: params, headers: headers);
    }
    return _result;
  }

  @override
  DataStateNotifier<T> watchOne(String id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    final key = manager.dataId<T>(id).key;
    final notifier = DataStateNotifier<T>();

    final _load = () async {
      if (remote == false) {
        return;
      }
      notifier.state = notifier.state.copyWith(isLoading: true);
      // we're only interested in capturing errors
      // as models will pop up via localAdapter.watchOne(_key)
      try {
        await loadOne(id, params: params, headers: headers);
      } catch (e) {
        notifier.state = notifier.state.copyWith(exception: DataException(e));
      }
    };

    notifier.state = DataState(
      model: localAdapter.findOne(key),
      reload: _load,
    );

    _load();

    localAdapter.watchOne(key).forEach((model) {
      notifier.state = notifier.state.copyWith(model: model, isLoading: false);
    }).catchError((Object e) {
      notifier.state = notifier.state.copyWith(exception: DataException(e));
    });
    return notifier;
  }

  @override
  Future<T> loadOne(String id,
      {Map<String, String> params, Map<String, String> headers}) async {
    final uri = QueryParameters(params ?? const {}).addToUri(
      urlDesign.resource(type, id.toString()),
    );

    final response = await withHttpClient(
      (client) => client.get(uri, headers: headers ?? this.headers),
    );

    print('[flutter_data] loadOne $T: $uri [HTTP ${response.statusCode}]');

    return _withResponse<T>(response, (data) {
      return deserialize(
        data as Map<String, dynamic>,
        key: manager.dataId<T>(data['id'].toString()).key,
        relationshipMetadata: relationshipMetadata,
      )._init(this);
    });
  }

  // save & delete

  @override
  Future<T> save(T model,
      {bool remote = true,
      Map<String, String> params = const {},
      Map<String, String> headers}) async {
    // ignore: unawaited_futures
    localAdapter.save(manager.dataId<T>(model.id).key, model);

    if (remote == false) {
      return model;
    }

    final map = serialize(model);
    final body = json.encode(map);

    final queryParams = QueryParameters(params);
    Uri uri;
    if (model.id != null) {
      uri = queryParams.addToUri(urlDesign.resource(type, model.id));
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

    return _withResponse<T>(response, (data) {
      if (data == null) {
        // return "old" model if response was empty
        return model;
      }
      return deserialize(
        data as Map<String, dynamic>,
        key: model.key,
        relationshipMetadata: relationshipMetadata,
      )._init(this);
    });
  }

  @override
  Future<void> delete(String id,
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

      return _withResponse<Null>(response, (_) {});
    }
  }

  @mustCallSuper
  @override
  Future<void> dispose() async {
    await localAdapter.dispose();
  }

  // helpers

  @override
  Future<R> withHttpClient<R>(OnRequest<R> onRequest) async {
    final client = http.Client();
    try {
      return await onRequest(client);
    } finally {
      client.close();
    }
  }

  FutureOr<R> _withResponse<R>(
      http.Response response, OnResponseSuccess<R> onSuccess) {
    dynamic data;
    dynamic error;

    try {
      data = json.decode(response.body);
    } on FormatException catch (e) {
      error = e;
    }

    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      return onSuccess(data);
    } else if (code >= 400 && code < 600) {
      throw DataException(error, response.statusCode);
    } else {
      throw UnsupportedError('Failed request for type $R');
    }
  }
}
