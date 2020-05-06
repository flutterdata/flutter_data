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

    box.watch().forEach((state) {
      if (_notifier.mounted) {
        // final models = state.model.map(_init).toList();
        // _notifier.state =
        //     _notifier.state.copyWith(model: models, isLoading: false);
      }
    });

    // .catchError((Object e) {
    //   if (_watchAllNotifier.mounted) {
    //     _watchAllNotifier.state =
    //         _watchAllNotifier.state.copyWith(exception: DataException(e));
    //   }
    // });
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
          model: _init(box.get(key)),
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

    box.watch(key: key).forEach((state) {
      // final model = state.model;

      // if (_notifier.mounted && model != null) {
      //   _notifier.state =
      //       _notifier.state.copyWith(model: _init(model), isLoading: false);
      // }
    });

    // .catchError((Object e) {
    //   if (_watchOneNotifier.mounted) {
    //     _watchOneNotifier.state =
    //         _watchOneNotifier.state.copyWith(exception: DataException(e));
    //   }
    // });
    return _notifier;
  }
}
