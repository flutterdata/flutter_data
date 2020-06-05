part of flutter_data;

mixin WatchAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    remote ??= _remote;

    final _notifier = DataStateNotifier<List<T>>(
      DataState(
        model: box.values.map(initModel).toList(),
      ),
      reload: (notifier) async {
        if (remote == false) {
          return;
        }
        notifier.state = notifier.state.copyWith(isLoading: true);

        try {
          await findAll(params: params, headers: headers, remote: remote);
        } catch (error, stackTrace) {
          // we're only interested in notifying errors
          // as models will pop up via box events
          notifier.state = notifier.state.copyWith(
              exception: DataException(error), stackTrace: stackTrace);
        }
      },
    );

    _notifier.onError = Zone.current.handleUncaughtError;

    // kick off
    _notifier.reload();

    _events.forEach((event) {
      if (!_notifier.mounted) {
        return;
      }
      final models = _notifier.state.model;
      for (final key in event.keys) {
        if (event.type == GraphEventType.removed) {
          models.removeWhere((model) => key == keyFor(model));
        } else {
          final model = _localGet(key);
          // until DataState#model is a Set?
          if (model != null && !models.contains(model)) {
            models.add(model);
          }
        }
      }
      _notifier.state =
          _notifier.state.copyWith(model: models, isLoading: false);
    });

    return _notifier;
  }

  @override
  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    remote ??= _remote;

    assert(id != null);
    var key = manager.getKeyForId(type, id);

    final _state = DataState(model: _localGet(key));
    final _notifier = DataStateNotifier<T>(_state, reload: (notifier) async {
      if (remote == false) {
        return;
      }
      notifier.state = notifier.state.copyWith(isLoading: true);

      try {
        await findOne(id, params: params, headers: headers, remote: remote);
      } catch (error, stackTrace) {
        // we're only interested in notifying errors
        // as models will pop up via box events
        notifier.state = notifier.state
            .copyWith(exception: DataException(error), stackTrace: stackTrace);
      }
    });

    var _watching = false;
    void _tryWatchRelationships(T model) {
      if (alsoWatch != null && !_watching) {
        for (var rel in alsoWatch(model)) {
          rel.watch().forEach((_) {
            _notifier.state = _notifier.state;
          });
          _watching = true;
        }
      }
    }

    _notifier.onError = Zone.current.handleUncaughtError;

    // kick off
    _notifier.reload();
    if (_notifier.state.model != null) {
      _tryWatchRelationships(_notifier.state.model);
    }

    _events.where((event) {
      // recalculates key every time
      final key = manager.getKeyForId(type, id);
      return event.keys.contains(key);
    }).forEach((event) {
      if (!_notifier.mounted) {
        return;
      }
      if (event.type == GraphEventType.removed) {
        _notifier.state =
            _notifier.state.copyWith(model: null, isLoading: false);
      } else {
        final model = _localGet(manager.getKeyForId(type, id));
        _notifier.state =
            _notifier.state.copyWith(model: model, isLoading: false);

        // new model, reset relationship watch
        _watching = false;
        _tryWatchRelationships(model);
      }
    });

    return _notifier;
  }

  StateNotifier<GraphEvent> get _events {
    return manager.graphNotifier.map((event) {
      final keys = event.keys.where((key) {
        return key.startsWith(type) && event.graph.hasEdge(key, 'id');
      });
      return GraphEvent(keys: keys, type: event.type, graph: event.graph);
    });
  }
}
