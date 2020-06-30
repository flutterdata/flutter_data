part of flutter_data;

mixin OfflineAdapter<T extends DataSupport<T>> on WatchAdapter<T> {
  Duration readRetryAfter(int i) {
    final list = [0, 1, 2, 2, 2, 2, 2, 4, 4, 4, 8, 8, 16, 16, 24];
    final index = i < list.length ? i : list.length - 1;
    return Duration(seconds: list[index]);
  }

  Duration writeRetryAfter(int i) => readRetryAfter(i);

  var _i = 0;

  void _load(DataStateNotifier notifier, Future Function() loadFn) {
    final _load = () async {
      if (_i == 0) {
        return;
      }

      try {
        await loadFn();
        // and we're back online!
        _i = 0;
        notifier.data = notifier.data.copyWith(exception: null);
      } catch (e) {
        // notify error and remove isLoading state
        notifier.data = notifier.data
            .copyWith(exception: DataException(e), isLoading: false);
      }
    };

    notifier.forEach((state) {
      if (state.hasException) {
        final errors = (state.exception as DataException).errors;
        if (errors is SocketException || errors is TimeoutException) {
          _i++;
          Future.delayed(readRetryAfter(_i), _load);
        }
      }
    });
  }

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote, Map<String, dynamic> params, Map<String, String> headers}) {
    final notifier =
        super.watchAll(remote: remote, params: params, headers: headers);
    _load(notifier, () => findAll(params: params, headers: headers));
    return notifier;
  }

  @override
  DataStateNotifier<T> watchOne(dynamic id,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    final notifier = super.watchOne(id,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
    _load(notifier, () => findOne(id, params: params, headers: headers));
    return notifier;
  }

  // write queue

  var _w = 0;
  final _offlineAdapterKey = 'offline:adapter';
  final _offlineSaveMetadata = 'offline:save';

  @override
  void initialize() {
    _save(() async {
      final keys =
          graph.getEdge(_offlineAdapterKey, metadata: _offlineSaveMetadata);
      for (final key in keys) {
        await localFindOne(key)?.save();
        graph.removeEdge(_offlineAdapterKey, key,
            metadata: _offlineSaveMetadata);
      }
    });
  }

  void _save(Future Function() saveFn) async {
    try {
      await saveFn();
      // and we're back online!
      _w = 0;
    } catch (e) {
      if (e is SocketException) {
        _w++;
        Future.delayed(writeRetryAfter(_w), () => _save(saveFn));
      }
    }
  }

  @override
  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    try {
      // first ensure model is stored locally
      // in case we have to retry later
      model = await super.save(model, remote: false);
      // then try to reach the network
      return await super
          .save(model, remote: true, params: params, headers: headers);
    } on DataException {
      // TODO ensure it's server unreachable
      if (!graph.hasNode(_offlineAdapterKey)) {
        graph.addNode(_offlineAdapterKey);
      }
      graph.addEdge(_offlineAdapterKey, keyFor(model),
          metadata: _offlineSaveMetadata);
      initialize();
      rethrow;
    }
  }
}
