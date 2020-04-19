part of flutter_data;

abstract class Repository<T extends DataSupportMixin<T>> {
  String get type => DataId.getType<T>();

  @visibleForTesting
  @protected
  final LocalAdapter<T> localAdapter;
  Repository(this.localAdapter);

  // url

  String baseUrl = 'http://127.0.0.1:8080/';

  // FIXME when we get late fields
  UrlDesign _urlDesign;
  UrlDesign get urlDesign =>
      _urlDesign ??= PathBasedUrlDesign(Uri.parse(baseUrl));

  String updateHttpMethod = 'PATCH';

  Map<String, String> get headers => {};

  //

  Map<String, dynamic> get relationshipMetadata;

  Map<String, dynamic> serialize(T model) => localAdapter.serialize(model);

  Iterable<Map<String, dynamic>> serializeCollection(Iterable<T> models) =>
      models.map(serialize);

  T deserialize(dynamic object, {String key}) {
    final map = Map<String, dynamic>.from(object as Map);
    final model = localAdapter.deserialize(map);
    // important to initialize (esp for "included" models)
    return _init(model, key: key, save: true);
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
      return localAdapter.findAll().map(_init).toList();
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
      models = models.map(_init).toList();
      _watchAllNotifier.state =
          _watchAllNotifier.state.copyWith(model: models, isLoading: false);
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
      return _init(localAdapter.findOne(key));
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
      _watchOneNotifier.state = _watchOneNotifier.state
          .copyWith(model: _init(model), isLoading: false);
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
    final key = model.key;
    if (remote == false) {
      // ignore: unawaited_futures
      localAdapter.save(model.key, model);
      return model;
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
        localAdapter.save(key, model);
        return model;
      }
      // deserialize already inits models
      return deserialize(data as Map<String, dynamic>, key: key);
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

  bool isNew(T model) => model.id == null;

  void syncRelationships(T model) {
    // set model as "owner" in its relationships
    localAdapter.setOwnerInRelationships(model._dataId, model);
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

  // initialization

  T _init(T model, {String key, bool save = false}) {
    if (model == null) {
      return null;
    }

    _assertManager();
    model._repository ??= this;
    model._save = save;

    // only init dataId if
    // (1) it hasn't been set
    // (2) there's an updated key to set
    if (model._dataId == null || (key != null && key != model._dataId.key)) {
      // establish key
      model._dataId = manager.dataId<T>(model.id, key: key);

      // if ID was already linked to ID
      // delete the "temporary" local record
      if (key != null && key != model._dataId.key) {
        localAdapter.delete(key);
      }
      // (2) sync relationships
      syncRelationships(model);
    }

    // (3) save locally
    if (save) {
      localAdapter.save(model.key, model);
    }

    return model;
  }

  _assertManager() {
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
