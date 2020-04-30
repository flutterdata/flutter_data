part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  String get type => DataId.getType<T>();

  @visibleForTesting
  @protected
  final LocalAdapter<T> localAdapter;
  Repository(this.localAdapter);

  // url

  String get baseUrl => 'http://127.0.0.1:8080/';

  List<String> urlForFindAll(type) => ['GET', '$type'];
  List<String> urlForFindOne(type, id) => ['GET', '$type/$id'];
  List<String> urlForSave(type, id) =>
      id != null ? ['PATCH', '$type/$id'] : ['POST', '$type'];
  List<String> urlForDelete(type, id) => ['DELETE', '$type/$id'];

  Map<String, String> get headers => {};

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
        urlForFindAll(type),
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
        urlForFindOne(type, id),
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
        urlForSave(type, model.id),
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
          urlForDelete(type, id),
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

  Future<http.Response> _executeRequest(http.Client client, List<String> tuple,
      {Map<String, dynamic> params,
      Map<String, dynamic> headers,
      String body}) async {
    final verb = tuple.first;
    final _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    var uri = Uri.parse('$_baseUrl${tuple.last}');
    if (params != null) {
      uri = uri.replace(queryParameters: parseQueryParameters(params));
    }
    final _headers = headers?.cast<String, String>() ?? this.headers;

    http.Response response;
    switch (verb) {
      case 'GET':
        response = await client.get(uri, headers: _headers);
        break;
      case 'PUT':
        response = await client.put(uri, headers: _headers, body: body);
        break;
      case 'POST':
        response = await client.post(uri, headers: _headers, body: body);
        break;
      case 'PATCH':
        response = await client.patch(uri, headers: _headers, body: body);
        break;
      case 'DELETE':
        response = await client.delete(uri, headers: _headers);
        break;
      default:
        response = null;
        break;
    }

    if (response != null) {
      print('[flutter_data] $T: $verb $uri [HTTP ${response.statusCode}]');
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
