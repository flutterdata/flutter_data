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
    // wipe out orphans
    graph.removeOrphanNodes();
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
    OnData<T> onSuccess,
    OnDataError onError,
    bool init,
  }) async {
    return await super.save(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: (newModel) {
        _removeOfflineKey(newModel._key, _offlineSaveMetadata);
        return onSuccess?.call(newModel) ?? newModel;
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          _addOfflineKey(model._key, _offlineSaveMetadata, headers, params,
              onSuccess, onError);
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
    OnData<void> onSuccess,
    OnDataError onError,
  }) async {
    final id = model is T ? model.id : model;
    final key = _keyForModel(model);

    if (key != null) {
      // ensure pending save is removed
      _removeOfflineKey(key, _offlineSaveMetadata);
    }

    return await super.delete(
      model,
      remote: remote,
      params: params,
      headers: headers,
      onSuccess: (_) {
        // delete request succeeded, remove meta
        final namespacedId = graph.namespace('id', graph.typify(type, id));
        _removeOfflineKey(namespacedId, _offlineDeleteMetadata);

        // also remove id from graph
        graph.removeId(type, id);
        onSuccess?.call(_);
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          // delete request failed, add meta
          final namespacedId = graph.namespace('id', graph.typify(type, id));
          _addOfflineKey(namespacedId, _offlineDeleteMetadata, headers, params,
              onSuccess, onError);

          // produce the offline exception with the ID
          e = OfflineException(error: e.error, id: id);
        }
        onError?.call(e);
      },
    );
  }

  @protected
  @visibleForTesting
  bool isNetworkError(error) {
    // timeouts via http's `connectionTimeout` are
    // also socket exceptions
    // we check the exception like this in order not to import `dart:io`
    return error.toString().startsWith('SocketException:');
  }

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

    // prepare save futures
    final allSaved = keysToSave.map((key) {
      final model = localAdapter.findOne(key);

      if (model == null) {
        // if key was deleted in the meantime,
        // do not attempt to save, return noop
        return Future.value();
      }

      // restore metadata
      final headers =
          _getMeta(key, _offlineHeadersMetadata).cast<String, String>();
      final params =
          _getMeta(key, _offlineParamsMetadata).cast<String, dynamic>();

      // restore callbacks
      OnData<T> onSuccess;
      OnDataError onError;
      final fns = ref.read(_offlineCallbackProvider).state[key];
      if (fns != null && fns.length == 2) {
        onSuccess = fns.first as OnData<T>;
        onError = fns.last as OnDataError;
      }

      // reattempt save
      return save(
        model,
        params: params,
        headers: headers,
        onSuccess: onSuccess,
        onError: (e) {
          // add exception to be returned
          exceptions.add(e);
          onError?.call(e);
        },
        init: true,
        remote: true,
      );
    });

    final idsToDelete =
        graph._getEdge(_offlineAdapterKey, metadata: _offlineDeleteMetadata);

    // prepare delete futures
    final allDeleted = idsToDelete.map((namespacedId) {
      final id = graph.detypify(graph.denamespace(namespacedId));

      // restore metadata
      final headers = _getMeta(namespacedId, _offlineHeadersMetadata)
          .cast<String, String>();
      final params = _getMeta(namespacedId, _offlineParamsMetadata)
          .cast<String, dynamic>();

      // restore callbacks
      OnData<void> onSuccess;
      OnDataError onError;
      final fns = ref.read(_offlineCallbackProvider).state[namespacedId];
      if (fns != null && fns.length == 2) {
        onSuccess = fns.first as OnData<void>;
        onError = fns.last as OnDataError;
      }

      // reattempt deletion
      return delete(
        id,
        params: params,
        headers: headers,
        onSuccess: onSuccess,
        onError: (e) {
          // add exception to be returned
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
    final nodes =
        graph._getEdge(_offlineAdapterKey, metadata: _offlineSaveMetadata);
    for (final key in nodes.toSet()) {
      // remove all save and delete offline-related metadata
      _removeOfflineKey(key, _offlineSaveMetadata);
      _removeOfflineKey(key, _offlineDeleteMetadata);
    }
  }

  // utils

  /// Adds an edge from the `_offlineAdapterKey` to the `key` for save/delete
  /// and stores header/param metadata. Also stores callbacks.
  void _addOfflineKey(String key, String metadata, Map<String, String> headers,
      Map<String, dynamic> params, Function onSuccess, Function onError) {
    graph._addEdge(_offlineAdapterKey, key, metadata: metadata, notify: false);
    _saveMeta(key, _offlineHeadersMetadata, headers);
    _saveMeta(key, _offlineParamsMetadata, params);
    // keep callbacks in memory
    ref.read(_offlineCallbackProvider).state[key] = [onSuccess, onError];
  }

  /// Removes the edge from the `_offlineAdapterKey` to the `key` for save/delete
  /// and removes header/param metadata. Also removes callbacks.
  void _removeOfflineKey(String key, String metadata) {
    graph._removeEdge(_offlineAdapterKey, key,
        metadata: metadata, notify: false);
    if (graph._hasNode(key)) {
      graph._removeEdges(key, metadata: _offlineHeadersMetadata, notify: false);
      graph._removeEdges(key, metadata: _offlineParamsMetadata, notify: false);
    }
    // remove callbacks from memory
    ref.read(_offlineCallbackProvider).state.remove(key);
  }

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
}

final _offlineCallbackProvider =
    StateProvider<Map<String, List<Function>>>((_) => {});
