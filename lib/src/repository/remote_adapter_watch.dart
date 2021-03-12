part of flutter_data;

mixin _RemoteAdapterWatch<T extends DataModel<T>> on _RemoteAdapter<T> {
  @protected
  @visibleForTesting
  Duration get throttleDuration =>
      const Duration(milliseconds: 16); // 1 frame at 60fps

  @protected
  @visibleForTesting
  StateNotifier<List<DataGraphEvent>> get throttledGraph =>
      graph.throttle(throttleDuration);

  DataStateNotifier<List<T>> watchAll(
      {final bool remote,
      final Map<String, dynamic> params,
      final Map<String, String> headers,
      final bool Function(T) filterLocal,
      final bool syncLocal}) {
    _assertInit();

    final _notifier = DataStateNotifier<List<T>>(
      DataState(localAdapter
          .findAll()
          .map((m) => initializeModel(m, save: true))
          .toList()),
      reload: (notifier) async {
        try {
          final _future = findAll(
              params: params,
              headers: headers,
              remote: remote,
              syncLocal: syncLocal,
              init: true);
          if (remote ?? true) {
            notifier.updateWith(isLoading: true);
          }
          await _future;
          // trigger doneLoading to ensure state is updated with isLoading=false
          graph._notify([type], DataGraphEventType.doneLoading);
        } catch (e, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          if (notifier.mounted) {
            notifier.updateWith(
              isLoading: false,
              exception: e is DataException ? e.error : e,
              stackTrace: e is DataException ? e.stackTrace : stackTrace,
            );
          } else {
            rethrow;
          }
        }
      },
    );

    // kick off
    _notifier.reload();

    final _graphNotifier = throttledGraph.forEach((events) {
      if (!_notifier.mounted) {
        return;
      }

      final models = localAdapter.findAll();
      if (!const DeepCollectionEquality()
              .equals(models, _notifier.data.model) ||
          events.where((e) {
            // ensure the done signal belongs to this notifier
            return e.type == DataGraphEventType.doneLoading &&
                e.keys.first == type;
          }).isNotEmpty) {
        final filtered =
            filterLocal != null ? models.where(filterLocal).toList() : models;
        _notifier.updateWith(model: filtered, isLoading: false);
      }
    });

    _notifier.onDispose = _graphNotifier.dispose;
    return _notifier;
  }

  DataStateNotifier<T> watchOne(final dynamic model,
      {final bool remote,
      final Map<String, dynamic> params,
      final Map<String, String> headers,
      final AlsoWatch<T> alsoWatch}) {
    _assertInit();
    assert(model != null);

    final id = model is T ? model.id : model;

    // lazy key access
    String _key;
    String key() => _key ??=
        graph.getKeyForId(type, id) ?? (model is T ? model._key : null);

    final _alsoWatchFilters = <String>{};

    final _notifier = DataStateNotifier<T>(
      DataState(initializeModel(localAdapter.findOne(key()), save: true)),
      reload: (notifier) async {
        if (id == null) return;
        try {
          final _future = findOne(
            id,
            params: params,
            headers: headers,
            remote: remote,
            init: true,
          );
          if (remote ?? true) {
            notifier.updateWith(isLoading: true);
          }
          await _future;
          // trigger doneLoading to ensure state is updated with isLoading=false
          graph._notify([key()], DataGraphEventType.doneLoading);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          if (notifier.mounted) {
            notifier.updateWith(
              isLoading: false,
              exception: error,
              stackTrace: stackTrace,
            );
          }
        }
      },
    );

    void _initializeRelationshipsToWatch(T model) {
      if (alsoWatch != null &&
          _alsoWatchFilters.isEmpty &&
          model != null &&
          model._isInitialized) {
        _alsoWatchFilters.addAll(alsoWatch(model).map((rel) {
          return rel?._name;
        }));
      }
    }

    // kick off

    // try to find relationships to watch
    _initializeRelationshipsToWatch(_notifier.data.model);

    // trigger local + async loading
    _notifier.reload();

    // start listening to graph for further changes
    final _graphNotifier = throttledGraph.forEach((events) {
      if (!_notifier.mounted) {
        return;
      }

      // buffers
      var modelBuffer = _notifier.data.model;
      var refresh = false;

      for (final event in events) {
        if (event.keys.containsFirst(key())) {
          // add/update
          if (event.type == DataGraphEventType.addNode ||
              event.type == DataGraphEventType.updateNode) {
            final model = localAdapter.findOne(key());
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
              event.keys.first == key() &&
              event.type == DataGraphEventType.doneLoading) {
            refresh = true;
          }
        }

        // updates on all models of specific relationships of this model
        if (event.type == DataGraphEventType.updateNode &&
            _relatedKeys(_notifier.data.model).any(event.keys.contains)) {
          refresh = true;
        }
      }

      // NOTE: because of this comparison, use field equality
      // rather than key equality (which wouldn't update)
      if (modelBuffer != _notifier.data.model || refresh) {
        _notifier.updateWith(model: modelBuffer, isLoading: false);
      }
    });

    _notifier.onDispose = _graphNotifier.dispose;
    return _notifier;
  }

  Set<String> _relatedKeys(T model) {
    return localAdapter
        .relationshipsFor(model)
        .values
        .map((meta) => (meta['instance'] as Relationship)?.keys)
        .filterNulls
        .expand((key) => key)
        .toSet();
  }
}

typedef AlsoWatch<T> = List<Relationship> Function(T);
