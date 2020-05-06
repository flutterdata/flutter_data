part of flutter_data;

mixin ReactiveAdapter<T extends DataSupportMixin<T>> on RemoteAdapter<T> {
  static const _oneFrameDuration = Duration(milliseconds: 16);

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, dynamic> headers}) {
    remote ??= _remote;

    final _notifier = DataStateNotifier<List<T>>(
      DataState(
        model: box.values.map(_init).toList(),
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

    box.watch().buffer(Stream.periodic(_oneFrameDuration)).forEach((events) {
      final keys = events.map((event) => event.key);
      if (_notifier.mounted && keys.isNotEmpty) {
        final _models = _notifier.state.model;
        for (var event in events) {
          final key = event.key.toString();
          if (event.deleted) {
            _models.removeWhere((model) => model.key == key);
          } else {
            _models.add(_init(box.safeGet(key)));
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
      WithRelationships andAlso}) {
    remote ??= _remote;
    final key = manager.dataId<T>(id).key;
    // var relsok = false;

    final _notifier = DataStateNotifier<T>(
        DataState(
          model: _init(box.safeGet(key)),
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
    _notifier.reload();

    box
        .watch(key: key)
        .buffer(Stream.periodic(_oneFrameDuration))
        .forEach((events) {
      final model = box.safeGet(events.last.key.toString());

      if (_notifier.mounted && model != null) {
        _notifier.state = _notifier.state.copyWith(
            model: events.last.deleted ? null : _init(model), isLoading: false);
      }
    }).catchError((Object e) {
      if (_notifier.mounted) {
        _notifier.state = _notifier.state.copyWith(exception: DataException(e));
      }
    });
    return _notifier;
  }
}
