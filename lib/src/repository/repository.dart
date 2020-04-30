part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  String get type => DataId.getType<T>();

  @visibleForTesting
  @protected
  final LocalAdapter<T> localAdapter;
  Repository(this.localAdapter);

  // url

  String get baseUrl => 'http://127.0.0.1:8080/';

  String urlForFindAll(params) => '$type';
  DataRequestMethod methodForFindAll(params) => DataRequestMethod.GET;

  String urlForFindOne(id, params) => '$type/$id';
  DataRequestMethod methodForFindOne(id, params) => DataRequestMethod.GET;

  String urlForSave(id, params) => id != null ? '$type/$id' : type;
  DataRequestMethod methodForSave(id, params) =>
      id != null ? DataRequestMethod.PATCH : DataRequestMethod.POST;

  String urlForDelete(id, params) => '$type/$id';
  DataRequestMethod methodForDelete(id, params) => DataRequestMethod.DELETE;

  Map<String, dynamic> get params => {};
  Map<String, dynamic> get headers => {};

  //

  Map<String, dynamic> get relationshipMetadata;

  Map<String, dynamic> serialize(T model) => localAdapter.serialize(model);

  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models) =>
      models.map(serialize);

  T deserialize(dynamic object, {String key, bool initialize = true}) {
    final map = Map<String, dynamic>.from(object as Map);
    final model = localAdapter.deserialize(map);
    if (initialize) {
      // important to initialize (esp for "included" models)
      return _init(model, key: key, save: true);
    }
    return model;
  }

  Iterable<T> deserializeCollection(object) =>
      (object as Iterable).map(deserialize);

  @visibleForTesting
  @protected
  DataManager get manager => localAdapter.manager;

  // repository methods

  Future<List<T>> findAll(
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    if (remote == false) {
      return localAdapter.findAll().map(_init).toList();
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

  DataStateNotifier<List<T>> watchAll(
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    final _watchAllNotifier = DataStateNotifier<List<T>>(
      DataState(
        model: localAdapter.findAll().map(_init).toList(),
      ),
      reload: (notifier) async {
        if (remote == false) {
          return;
        }
        notifier.state = notifier.state.copyWith(isLoading: true);

        try {
          // we're only interested in capturing errors
          // as models will pop up via localAdapter.watchOne(_key)
          await findAll(params: params, headers: headers);
        } catch (error, stackTrace) {
          notifier.state = notifier.state.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
      onError: (notifier, error, stackTrace) {
        notifier.state = notifier.state
            .copyWith(exception: DataException(error), stackTrace: stackTrace);
      },
    );

    // kick off
    _watchAllNotifier.reload();

    localAdapter.watchAll().forEach((models) {
      if (_watchAllNotifier.mounted) {
        models = models.map(_init).toList();
        _watchAllNotifier.state =
            _watchAllNotifier.state.copyWith(model: models, isLoading: false);
      }
    }).catchError((Object e) {
      if (_watchAllNotifier.mounted) {
        _watchAllNotifier.state =
            _watchAllNotifier.state.copyWith(exception: DataException(e));
      }
    });
    return _watchAllNotifier;
  }

  // one

  Future<T> findOne(dynamic id,
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    assert(id != null);
    final key = manager.dataId<T>(id).key;

    if (remote == false) {
      return _init(localAdapter.findOne(key));
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
      return deserialize(data, key: key);
    });
  }

  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    final key = manager.dataId<T>(id).key;

    final _watchOneNotifier = DataStateNotifier<T>(
        DataState(
          model: _init(localAdapter.findOne(key)),
        ), reload: (notifier) async {
      if (remote == false) {
        return;
      }
      notifier.state = notifier.state.copyWith(isLoading: true);

      try {
        // we're only interested in capturing errors
        // as models will pop up via localAdapter.watchOne(_key)
        await findOne(id, params: params, headers: headers);
      } catch (error, stackTrace) {
        notifier.state = notifier.state
            .copyWith(exception: DataException(error), stackTrace: stackTrace);
      }
    }, onError: (notifier, error, stackTrace) {
      notifier.state = notifier.state
          .copyWith(exception: DataException(error), stackTrace: stackTrace);
    });

    // kick off
    _watchOneNotifier.reload();

    localAdapter.watchOne(key).forEach((model) {
      if (_watchOneNotifier.mounted) {
        _watchOneNotifier.state = _watchOneNotifier.state
            .copyWith(model: _init(model), isLoading: false);
      }
    }).catchError((Object e) {
      if (_watchOneNotifier.mounted) {
        _watchOneNotifier.state =
            _watchOneNotifier.state.copyWith(exception: DataException(e));
      }
    });
    return _watchOneNotifier;
  }

  // save & delete

  Future<T> save(T model,
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    final key = model.key;

    if (remote == false) {
      // ignore: unawaited_futures
      localAdapter.save(key, model);
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
        localAdapter.save(key, model);
        return model;
      }
      // deserialize already inits models
      return deserialize(data as Map<String, dynamic>, key: key);
    });
  }

  Future<void> delete(dynamic id,
      {bool remote = true,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) async {
    final dataId = manager.dataId<T>(id);
    // ignore: unawaited_futures
    localAdapter.delete(dataId.key);
    dataId.delete();

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

  bool isNew(T model) => model.id == null;

  void syncRelationships(T model) {
    // set model as "owner" in its relationships
    localAdapter.setOwnerInRelationships(model._dataId, model);
  }

  @mustCallSuper
  Future<void> dispose() {
    return localAdapter.dispose();
  }

  // http

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
    uri = uri.replace(queryParameters: parseQueryParameters(_params));
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

    if (response != null) {
      print(
          '[flutter_data] $T: ${method.toShortString()} $uri [HTTP ${response.statusCode}]');
    }
    return response;
  }

  // initialization

  T _init(T model, {String key, bool save = false}) {
    if (model == null) {
      return null;
    }

    _assertManager();
    model._repository ??= this;
    model._save = save;

    // only init dataId if
    //  - it hasn't been set
    //  - there's an updated key to set
    if (model._dataId == null || (key != null && key != model._dataId.key)) {
      // (1) establish key
      model._dataId = DataId<T>(model.id, manager, key: key);

      // if key was already linked to ID
      // delete the "temporary" local record
      if (key != null && key != model._dataId.key) {
        localAdapter.delete(key);
        DataId.byKey<T>(key, manager)?.delete();
      }

      // (2) sync relationships
      syncRelationships(model);
    }

    // (3) save locally
    if (save) {
      localAdapter.save(model._dataId.key, model);
    }

    return model;
  }

  void _assertManager() {
    final modelAutoInit = _autoModelInitDataManager != null;
    if (modelAutoInit) {
      assert(manager == _autoModelInitDataManager, '''\n
This app has been configured with autoModelInit: true at boot,
which means that model initialization is managed internally.

You supplied an instance of Repository whose manager is NOT the
internal manager.

Either:
 - supply NO repository at all (RECOMMENDED)
 - supply an internally managed repository

If you wish to manually initialize your models, please make
sure $T (and ALL your other models) mix in DataSupportMixin
and you configure Flutter Data to do so, via:

FlutterData.init(autoModelInit: false);
''');
    }
  }
}

// ignore: constant_identifier_names
enum DataRequestMethod { GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS, TRACE }
