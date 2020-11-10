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
      final Map<String, String> headers}) {
    _assertInit();

    final _notifier = DataStateNotifier<List<T>>(
      DataState(localAdapter
          .findAll()
          .map((m) => initializeModel(m, save: true))
          .toList()),
      reload: (notifier) async {
        try {
          final _future = findAll(
              params: params, headers: headers, remote: remote, init: true);
          notifier.data = notifier.data.copyWith(isLoading: true);
          await _future;
          // trigger doneLoading to ensure state is updated with isLoading=false
          graph._notify([], DataGraphEventType.doneLoading);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          if (notifier.mounted) {
            notifier.data = notifier.data.copyWith(
              isLoading: false,
              exception: error,
              stackTrace: stackTrace,
            );
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

      // filter by keys (that are not IDs)
      final filteredEvents = events.where((event) =>
          event.type.isNode &&
          event.keys.first.startsWith(type) &&
          !event.graph._hasEdge(event.keys.first, metadata: 'key'));

      final list = _notifier.data.model.toList();

      if (list.isEmpty &&
          events.safeFirst.type == DataGraphEventType.doneLoading) {
        _notifier.data = _notifier.data.copyWith(model: [], isLoading: false);
        return;
      }

      if (filteredEvents.isEmpty) {
        return;
      }

      for (final event in filteredEvents) {
        final key = event.keys.first;
        assert(key != null);
        switch (event.type) {
          case DataGraphEventType.addNode:
            list.add(localAdapter.findOne(key));
            break;
          case DataGraphEventType.updateNode:
            final idx = list.indexWhere((model) => model?._key == key);
            list[idx] = localAdapter.findOne(key);
            break;
          case DataGraphEventType.removeNode:
            list..removeWhere((model) => model?._key == key);
            break;
          default:
        }
      }

      _notifier.data = _notifier.data.copyWith(model: list, isLoading: false);
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
    var _relatedKeys = <String>{};

    final _notifier = DataStateNotifier<T>(
      DataState(initializeModel(localAdapter.findOne(key()), save: true)),
      reload: (notifier) async {
        if (id == null) return;
        try {
          final _future = findOne(id,
              params: params, headers: headers, remote: remote, init: true);
          notifier.data = notifier.data.copyWith(isLoading: true);
          await _future;
          // trigger doneLoading to ensure state is updated with isLoading=false
          graph._notify([key()], DataGraphEventType.doneLoading);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via the graph notifier
          if (notifier.mounted) {
            notifier.data = notifier.data.copyWith(
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
            _relatedKeys = localAdapter
                .relationshipsFor(_notifier.data.model)
                .values
                .map((meta) => (meta['instance'] as Relationship)?.keys)
                .where((keys) => keys != null)
                .expand((key) => key)
                .toSet();

            refresh = true;
          }

          if (modelBuffer != null &&
              event.type == DataGraphEventType.doneLoading) {
            refresh = true;
          }
        }

        // updates on all models of specific relationships of this model
        if (event.type == DataGraphEventType.updateNode &&
            _relatedKeys.any(event.keys.contains)) {
          refresh = true;
        }
      }

      // NOTE: because of this comparison, use field equality
      // rather than key equality (which wouldn't update)
      if (modelBuffer != _notifier.data.model || refresh) {
        _notifier.data =
            _notifier.data.copyWith(model: modelBuffer, isLoading: false);
      }
    });

    _notifier.onDispose = _graphNotifier.dispose;
    return _notifier;
  }
}

typedef AlsoWatch<T> = List<Relationship> Function(T);
