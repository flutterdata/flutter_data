part of flutter_data;

mixin _RemoteAdapterWatch<T extends DataModel<T>> on _RemoteAdapter<T> {
  @protected
  @visibleForTesting
  Duration get throttleDuration {
    // 1 frame at 60fps
    return const Duration(milliseconds: 16);
  }

  @protected
  @visibleForTesting
  @nonVirtual
  DelayedStateNotifier<List<DataGraphEvent>> get throttledGraph {
    var _throttleDuration = throttleDuration;
    if (_isTesting) {
      // do not throttle when testing
      _throttleDuration = Duration.zero;
    }
    return graph.throttle(() => _throttleDuration);
  }

  @protected
  @visibleForTesting
  DataStateNotifier<List<T>> watchAllNotifier({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
    String? finder,
  }) {
    _assertInit();
    remote ??= _remote;
    syncLocal ??= false;
    final _finder = strategies._findersAll[finder] ?? findAll;

    final _notifier = DataStateNotifier<List<T>>(
      data: DataState(localAdapter
          .findAll()
          .map((m) => initializeModel(m, save: true))
          .filterNulls
          .toList()),
      reload: (notifier) async {
        if (!notifier.mounted) {
          return;
        }
        try {
          final _future = _finder(
            params: params,
            headers: headers,
            remote: remote,
            syncLocal: syncLocal,
          );
          if (remote!) {
            notifier.updateWith(isLoading: true);
          }
          await _future;
          // trigger doneLoading to ensure state is updated with isLoading=false
          graph._notify([internalType], DataGraphEventType.doneLoading);
        } on DataException catch (e) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          // (we can catch the exception as we are NOT supplying
          // an `onError` to `findAll`)
          if (notifier.mounted) {
            notifier.updateWith(isLoading: false, exception: e);
          } else {
            rethrow;
          }
        }
      },
    );

    // kick off
    _notifier.reload();

    final _dispose = throttledGraph.addListener((events) {
      if (!_notifier.mounted) {
        return;
      }

      final models = localAdapter.findAll().toImmutableList();
      final modelChanged =
          !const DeepCollectionEquality().equals(models, _notifier.data.model);
      // ensure the done signal belongs to this notifier
      final doneLoading = events
          .where((e) =>
              e.type == DataGraphEventType.doneLoading &&
              e.keys.first == internalType)
          .isNotEmpty;
      if (modelChanged || doneLoading) {
        _notifier.updateWith(model: models, isLoading: false, exception: null);
      }
    });

    _notifier.onDispose = _dispose;
    return _notifier;
  }

  DataState<List<T>> watchAll({
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    bool? syncLocal,
  }) {
    if (internalWatch == null || _allProvider == null) {
      throw UnsupportedError(_watchAllError);
    }
    return internalWatch!(_allProvider!(
      remote: remote,
      params: params,
      headers: headers,
      syncLocal: syncLocal,
    ));
  }

  String get _watchAllError =>
      'Should only be used via `ref.$type.watchAll`. Alternatively use `watch${type.capitalize()}()`.';

  // one

  @protected
  @visibleForTesting
  DataStateNotifier<T?> watchOneNotifier(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
    String? finder,
  }) {
    _assertInit();

    remote ??= _remote;

    final _finder = strategies._findersOne[finder] ?? findOne;

    final id = _resolveId(model);

    // lazy key access
    String? key() {
      return graph.getKeyForId(internalType, id,
          keyIfAbsent: (model is T ? model._key : null));
    }

    var _key = key();

    final _alsoWatchFilters = <String>{};

    final localModel = _key != null ? localAdapter.findOne(_key) : null;
    final _notifier = DataStateNotifier<T?>(
      data: DataState(
          localModel == null ? null : initializeModel(localModel, save: true)),
      reload: (notifier) async {
        if (!notifier.mounted) {
          return;
        }
        try {
          if (id != null) {
            final _future = _finder(
              id,
              remote: remote,
              params: params,
              headers: headers,
            );
            if (remote!) {
              notifier.updateWith(isLoading: true);
            }
            await _future;
          }

          _key ??= key();
          if (_key != null) {
            // trigger doneLoading to ensure state is updated with isLoading=false
            graph._notify([_key!], DataGraphEventType.doneLoading);
          }
        } on DataException catch (e) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          // (we can catch the exception as we are NOT supplying
          // an `onError` to `findOne`)
          if (notifier.mounted) {
            notifier.updateWith(isLoading: false, exception: e);
          } else {
            rethrow;
          }
        }
      },
    );

    void _initializeRelationshipsToWatch(T? model) {
      if (alsoWatch != null &&
          _alsoWatchFilters.isEmpty &&
          model != null &&
          model.isInitialized) {
        _alsoWatchFilters
            .addAll(alsoWatch(model).where((rel) => rel != null).map((rel) {
          return rel!._name;
        }));
      }
    }

    // kick off

    // try to find relationships to watch
    _initializeRelationshipsToWatch(_notifier.data.model);

    // trigger local + async loading
    _notifier.reload();

    // start listening to graph for further changes
    final _dispose = throttledGraph.addListener((events) {
      if (!_notifier.mounted) {
        return;
      }

      // buffers
      var modelBuffer = _notifier.data.model;
      var refresh = false;

      for (final event in events) {
        _key ??= key();
        if (_key != null && event.keys.containsFirst(_key!)) {
          // add/update
          if (event.type == DataGraphEventType.addNode ||
              event.type == DataGraphEventType.updateNode) {
            final model = localAdapter.findOne(_key!);
            if (model != null) {
              initializeModel(model, save: true);
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
            // calculate currently related models
            refresh = true;
          }

          if (modelBuffer != null &&
              // ensure the done signal belongs to this type
              event.keys.first == _key &&
              event.type == DataGraphEventType.doneLoading) {
            refresh = true;
          }
        }

        // updates on all models of specific relationships of this model
        if (event.type == DataGraphEventType.updateNode &&
            _relatedKeys(_notifier.data.model!).any(event.keys.contains)) {
          refresh = true;
        }
      }

      // NOTE: because of this comparison, use field equality
      // rather than key equality (which wouldn't update)
      if (modelBuffer != _notifier.data.model || refresh) {
        _notifier.updateWith(
            model: modelBuffer, isLoading: false, exception: null);
      }
    });

    _notifier.onDispose = _dispose;
    return _notifier;
  }

  DataState<T?> watchOne(
    Object model, {
    bool? remote,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    AlsoWatch<T>? alsoWatch,
  }) {
    if (internalWatch == null || _oneProvider == null) {
      throw UnsupportedError(_watchOneError);
    }
    return internalWatch!(_oneProvider!(
      model,
      remote: remote,
      params: params,
      headers: headers,
      alsoWatch: alsoWatch,
    ));
  }

  String get _watchOneError =>
      'Should only be used via `ref.$type.watchOne`. Alternatively use `watch${type.singularize().capitalize()}()`.';

  Set<String> _relatedKeys(T model) {
    return localAdapter
        .relationshipsFor(model)
        .values
        .map((meta) => (meta['instance'] as Relationship?)?.keys)
        .filterNulls
        .expand((key) => key)
        .toSet();
  }
}

typedef AlsoWatch<T extends DataModel<T>> = List<Relationship?> Function(T);
