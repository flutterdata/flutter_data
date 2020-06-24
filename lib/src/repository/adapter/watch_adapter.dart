part of flutter_data;

mixin WatchAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  @protected
  @visibleForTesting
  Duration get throttleDuration =>
      Duration(milliseconds: 16); // 1 frame at 60fps

  StateNotifier<List<DataGraphEvent>> get _throttledGraph =>
      manager._graph.throttle(throttleDuration);

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    remote ??= _remote;

    final _notifier = DataStateNotifier<List<T>>(
      DataState(localFindAll().toList()),
      reload: (notifier) async {
        if (remote == false) {
          return;
        }
        notifier.data = notifier.data.copyWith(isLoading: true);

        try {
          await findAll(params: params, headers: headers, remote: remote);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via box events
          notifier.data = notifier.data.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
    );

    // kick off
    _notifier.reload();

    _throttledGraph.forEach((events) {
      if (!_notifier.mounted) {
        return;
      }

      // filter by keys (that are not IDs)
      final filteredEvents = events.where((event) =>
          event.type.isNode &&
          event.keys.first.startsWith(type) &&
          !event.graph.hasEdge(event.keys.first, metadata: 'key'));

      if (filteredEvents.isEmpty) {
        return;
      }

      final list = _notifier.data.model;

      for (final event in filteredEvents) {
        final key = event.keys.first;
        assert(key != null);
        switch (event.type) {
          case DataGraphEventType.addNode:
            list.add(localFindOne(key));
            break;
          case DataGraphEventType.updateNode:
            final idx = list.indexWhere((model) => model?._key == key);
            list[idx] = localFindOne(key);
            break;
          case DataGraphEventType.removeNode:
            list..removeWhere((model) => model?._key == key);
            break;
          default:
        }
      }

      _notifier.data = _notifier.data.copyWith(model: list, isLoading: false);
    });

    return _notifier;
  }

  @override
  DataStateNotifier<T> watchOne(dynamic model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    remote ??= _remote;
    assert(model != null);

    final id = model is T ? model.id : model;

    // lazy key access
    String _key;
    String key() => _key ??=
        manager.getKeyForId(type, id) ?? (model is T ? model._key : null);

    final _alsoWatchFilters = <String>{};
    var _relatedKeys = <String>{};

    final _notifier = DataStateNotifier<T>(
      DataState(localFindOne(key())),
      reload: (notifier) async {
        if (remote == false || id == null) return;
        notifier.data = notifier.data.copyWith(isLoading: true);

        try {
          await findOne(id, params: params, headers: headers, remote: remote);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via box events
          notifier.data = notifier.data.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
    );

    void _initializeRelationshipsToWatch(T model) {
      if (alsoWatch != null && _alsoWatchFilters.isEmpty) {
        _alsoWatchFilters.addAll(alsoWatch(model).map((rel) => rel._name));
      }
    }

    // kick off

    // try to find relationships to watch
    if (_notifier.data.model != null) {
      _initializeRelationshipsToWatch(_notifier.data.model);
    }

    // trigger local + async loading
    _notifier.reload();

    // start listening to graph for further changes
    _throttledGraph.forEach((events) {
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
            final model = localFindOne(key());
            if (model != null) {
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
            // calculate current related models
            _relatedKeys = relationshipsFor(_notifier.data.model)
                .values
                .map((meta) => (meta['instance'] as Relationship)?.keys)
                .where((keys) => keys != null)
                .expand((key) => key)
                .toSet();

            refresh = true;
          }
        }

        // updates on all models of specific relationships of this model
        if (event.type == DataGraphEventType.updateNode &&
            _relatedKeys.any(event.keys.contains)) {
          refresh = true;
        }
      }

      if (modelBuffer != _notifier.data.model || refresh) {
        _notifier.data = _notifier.data
            .copyWith(model: modelBuffer, isLoading: false, exception: null);
      }
    });

    return _notifier;
  }
}
