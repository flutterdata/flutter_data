part of flutter_data;

mixin WatchAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  static const oneFrameDuration = Duration(milliseconds: 16);

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    remote ??= _remote;

    final _notifier = DataStateNotifier<List<T>>(
      DataState(
        model: box.values.map(init).toList(),
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
    _notifier.reload();

    box.watch().buffer(Stream.periodic(oneFrameDuration)).forEach((events) {
      if (_notifier.mounted && events.isNotEmpty) {
        final _models = _notifier.state.model;
        for (var event in events) {
          if (event.deleted) {
            _models.remove(event.value);
          } else {
            _models.add(event.value as T);
          }
        }
        _notifier.state =
            _notifier.state.copyWith(model: _models, isLoading: false);
      }
    }).catchError((Object e) {
      if (_notifier.mounted) {
        _notifier.state = _notifier.state.copyWith(exception: DataException(e));
      }
    });
    return _notifier;
  }

  @override
  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers,
      AlsoWatch<T> alsoWatch}) {
    remote ??= _remote;
    final key = manager.dataId<T>(id).key;

    final _notifier = DataStateNotifier<T>(
        DataState(
          model: init(box.safeGet(key)),
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

    // kick off
    _notifier.reload();
    if (_notifier.state.model != null) {
      _tryWatchRelationships(_notifier.state.model);
    }

    box
        .watch(key: key)
        .buffer(Stream.periodic(oneFrameDuration))
        .forEach((events) {
      if (events.isEmpty) {
        return;
      }
      // we only care about the latest event in the window
      final model = events.last.value as T;

      if (_notifier.mounted && model != null) {
        if (events.last.deleted) {
          _notifier.state =
              _notifier.state.copyWith(model: null, isLoading: false);
        } else {
          _notifier.state =
              _notifier.state.copyWith(model: init(model), isLoading: false);
          _tryWatchRelationships(model);
        }
      }
    }).catchError((Object e) {
      if (_notifier.mounted) {
        _notifier.state = _notifier.state.copyWith(exception: DataException(e));
      }
    });
    return _notifier;
  }
}
