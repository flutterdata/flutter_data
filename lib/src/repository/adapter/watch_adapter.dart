part of flutter_data;

mixin WatchAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  @override
  DataStateNotifier<Iterable<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    remote ??= _remote;

    final _notifier = DataStateNotifier<Set<T>>(
      DataState(localFindAll().toSet()),
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

    manager.graph.forEach((event) {
      if (!_notifier.mounted) {
        return;
      }

      // filter by keys (that are not IDs)
      final keys = event.keys.where((key) =>
          key.startsWith(type) && !event.graph.hasEdge(key, metadata: 'key'));

      if (keys.isNotEmpty) {
        if ([
          DataGraphEventType.addNode,
          DataGraphEventType.updateNode,
          DataGraphEventType.removeNode
        ].contains(event.type)) {
          _notifier.data = _notifier.data
              .copyWith(model: localFindAll().toSet(), isLoading: false);
        }
      }
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

    // lazy key access
    String _key;
    Object id;

    String key() {
      if (model is T) {
        id = model.id;
        return _key ??=
            id != null ? manager.getKeyForId(type, id) : keyFor(model);
      } else {
        id = model;
        return _key ??= manager.getKeyForId(type, id);
      }
    }

    final _alsoWatchFilters = <String>{};

    final _notifier = DataStateNotifier<T>(
      DataState(localGet(key())),
      reload: (notifier) async {
        if (remote == false) return;
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

    void _tryInitializeWatch(T model) {
      if (alsoWatch != null && model != null) {
        for (var rel in alsoWatch(model)) {
          _alsoWatchFilters.add(rel._name);
        }
      }
    }

    // kick off

    _tryInitializeWatch(_notifier.data.model);
    _notifier.reload();

    manager.graph.where((event) {
      if (key() == null) {
        return false;
      }

      // if either the currently-watched key OR any of the nodes
      // connected to it (by additional filters) are mentioned in
      // the `event.keys` iterable, then send for further processing
      final filteredConnectedKeys = event.graph
          .connectedKeys(key(), metadatas: _alsoWatchFilters)
            ..add(key());
      return event.keys.any(filteredConnectedKeys.contains);
    }).forEach((event) {
      if (!_notifier.mounted) {
        return;
      }

      if (event.keys.containsFirst(key())) {
        if (event.type == DataGraphEventType.addNode ||
            event.type == DataGraphEventType.updateNode) {
          final model = localGet(key());
          if (model != null) {
            _tryInitializeWatch(model);
            _notifier.data = _notifier.data.copyWith(model: model);
          }
        }
        if (event.type == DataGraphEventType.removeNode) {
          _notifier.data =
              _notifier.data.copyWith(model: null, isLoading: false);
        }
        if ([
              DataGraphEventType.addEdge,
              DataGraphEventType.updateEdge,
              DataGraphEventType.removeEdge
            ].contains(event.type) &&
            _alsoWatchFilters.contains(event.metadata)) {
          // simply refresh
          _notifier.data = _notifier.data;
        }
      }
    });

    return _notifier;
  }
}
