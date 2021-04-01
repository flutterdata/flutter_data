part of flutter_data;

mixin _RemoteAdapterOffline<T extends DataModel<T>> on _RemoteAdapter<T> {
  String get _offlineAdapterKey => '_offline:keys';

  String get _offlineHeadersMetadata => '_offline:headers';
  String get _offlineParamsMetadata => '_offline:params';
  String get _offlineSaveMetadata => '_offline:save_$type';
  String get _offlineDeleteMetadata => '_offline:delete_$type';

  @override
  @mustCallSuper
  Future<void> onInitialized() async {
    await super.onInitialized();
    // ensure offline nodes exist
    if (!graph._hasNode(_offlineAdapterKey)) {
      graph._addNode(_offlineAdapterKey);
    }
  }

  @override
  Future<List<T>> findAll({
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
    bool syncLocal,
    bool init,
    OnDataError onError,
  }) async {
    return super.findAll(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
      init: init,
      onError: (e) {
        if (isNetworkError(e.error)) {
          e = OfflineException(error: e.error);
        }
        (onError ?? this.onError).call(e);
      },
    );
  }

  @override
  Future<T> findOne(
    final dynamic model, {
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
    bool init,
    OnDataError onError,
  }) async {
    return super.findOne(
      model,
      remote: remote,
      params: params,
      headers: headers,
      init: init,
      onError: (e) {
        if (isNetworkError(e.error)) {
          e = OfflineException(error: e.error);
        }
        (onError ?? this.onError).call(e);
      },
    );
  }

  @override
  Future<T> save(
    final T model, {
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
    OnDataSave<T> onSuccess,
    OnDataError onError,
    bool init,
  }) async {
    return await super.save(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: (newModel) {
        final key = newModel._key;
        // save request succeeded, remove meta
        graph._removeEdge(_offlineAdapterKey, key,
            metadata: _offlineSaveMetadata, notify: false);
        _removeAllMeta(key);

        ref.read(_offlineCallbackProvider).state.remove(key);
        return onSuccess?.call(newModel) ?? newModel;
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          // save request failed, add meta
          graph._addEdge(_offlineAdapterKey, model._key,
              metadata: _offlineSaveMetadata, notify: false);
          _saveMeta(model._key, _offlineHeadersMetadata, headers);
          _saveMeta(model._key, _offlineParamsMetadata, params);

          // keep callbacks in memory
          ref.read(_offlineCallbackProvider).state[model._key] = [
            onSuccess,
            onError
          ];
          // produce the offline exception
          e = OfflineException(error: e.error, model: model);
        }
        onError?.call(e);
      },
      init: init,
    );
  }

  @override
  Future<void> delete(
    final dynamic model, {
    bool remote,
    Map<String, dynamic> params,
    Map<String, String> headers,
    OnDataDelete onSuccess,
    OnDataError onError,
  }) async {
    return super.delete(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: (_) {
        // delete request succeeded, remove meta
        final id = (model is T ? model.id : model).toString();
        final namespacedId = graph.namespace('id', graph.typify(type, id));

        graph._removeEdge(_offlineAdapterKey, namespacedId,
            metadata: _offlineDeleteMetadata, notify: false);
        _removeAllMeta(namespacedId);

        // also remove id from graph
        graph.removeId(type, id);
        ref.read(_offlineCallbackProvider).state.remove(namespacedId);
        onSuccess?.call(id);
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          // delete request failed, add meta
          final id = (model is T ? model.id : model).toString();
          final namespacedId = graph.namespace('id', graph.typify(type, id));

          graph._addEdge(_offlineAdapterKey, namespacedId,
              metadata: _offlineDeleteMetadata, notify: false);
          _saveMeta(namespacedId, _offlineHeadersMetadata, headers);
          _saveMeta(namespacedId, _offlineParamsMetadata, params);

          ref.read(_offlineCallbackProvider).state[namespacedId] = [
            onSuccess,
            onError
          ];
          // produce the offline exception with the ID
          e = OfflineException(error: e.error, id: id);
        }
        onError?.call(e);
      },
    );
  }

  @protected
  bool isNetworkError(error) {
    // timeouts via http's `connectionTimeout` are
    // also socket exceptions
    // we check the exception like this in order not to import `dart:io`
    return error.toString().startsWith('SocketException:');
  }

  //

  @protected
  @visibleForTesting
  List<T> get offlineSaved {
    final keys =
        graph._getEdge(_offlineAdapterKey, metadata: _offlineSaveMetadata);
    return keys.map(localAdapter.findOne).filterNulls.toList();
  }

  List<String> get offlineDeleted {
    return graph
        .getEdge(_offlineAdapterKey, metadata: _offlineDeleteMetadata)
        .map((id) {
      return graph.detypify(graph.denamespace(id));
    }).toList();
  }

  @protected
  @visibleForTesting
  Future<List<DataException>> offlineSync() async {
    final exceptions = <DataException>[];

    final keysToSave =
        graph._getEdge(_offlineAdapterKey, metadata: _offlineSaveMetadata);

    final allSaved = keysToSave.map((key) {
      final model = localAdapter.findOne(key);

      if (model == null) {
        // if key was deleted in the meantime,
        // do not attempt to save, return noop
        return Future.value();
      }

      final headers =
          _getMeta(key, _offlineHeadersMetadata).cast<String, String>();
      final params =
          _getMeta(key, _offlineParamsMetadata).cast<String, dynamic>();

      final _ = ref.read(_offlineCallbackProvider).state[key];
      final onSuccess = _.first as OnDataSave<T>;
      final onError = _.last as OnDataError;

      return save(
        model,
        params: params,
        headers: headers,
        onSuccess: onSuccess,
        onError: (e) {
          exceptions.add(e);
          onError?.call(e);
        },
        init: true,
        remote: true,
      );
    });

    final idsToDelete =
        graph._getEdge(_offlineAdapterKey, metadata: _offlineDeleteMetadata);

    final allDeleted = idsToDelete.map((namespacedId) {
      final id = graph.detypify(graph.denamespace(namespacedId));

      final headers = _getMeta(namespacedId, _offlineHeadersMetadata)
          .cast<String, String>();
      final params = _getMeta(namespacedId, _offlineParamsMetadata)
          .cast<String, dynamic>();

      final _ = ref.read(_offlineCallbackProvider).state[namespacedId];
      final onSuccess = _.first as OnDataDelete;
      final onError = _.last as OnDataError;

      return delete(
        id,
        params: params,
        headers: headers,
        onSuccess: onSuccess,
        onError: (e) {
          exceptions.add(e);
          onError?.call(e);
        },
        remote: true,
      );
    });

    await Future.wait([...allSaved, ...allDeleted]);
    return exceptions;
  }

  @protected
  @visibleForTesting
  void offlineClear() {
    graph._removeEdges(_offlineAdapterKey, metadata: _offlineSaveMetadata);
    graph._removeEdges(_offlineAdapterKey, metadata: _offlineDeleteMetadata);
  }

  // utils

  Map _getMeta(String key, String metadata) {
    final values = graph._getEdge(key, metadata: metadata);
    return values.isNotEmpty ? json.decode(values.first) as Map : {};
  }

  void _saveMeta(String key, String metadata, Map map) {
    if (map != null && map.isNotEmpty) {
      final mapNode = json.encode(map);
      graph._addNode(mapNode);
      graph._addEdge(key, mapNode, metadata: metadata);
    }
  }

  void _removeAllMeta(String key) {
    if (graph._hasNode(key)) {
      graph._removeEdges(key, metadata: _offlineHeadersMetadata, notify: false);
      graph._removeEdges(key, metadata: _offlineParamsMetadata, notify: false);
    }
  }
}

typedef OnDataSave<R> = FutureOr<R> Function(R model);
typedef OnDataDelete = void Function(dynamic id);

final _offlineCallbackProvider =
    StateProvider<Map<String, List<Function>>>((_) => {});
