import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';

mixin OfflineAdapter<T extends DataSupportMixin<T>> on Repository<T> {
  Duration retryAfter(int i) {
    final list = [0, 1, 2, 2, 2, 2, 2, 4, 4, 4, 8, 8, 16, 16, 24];
    final index = i < list.length ? i : list.length - 1;
    return Duration(seconds: list[index]);
  }

  var _i = 0;

  _addListener(DataStateNotifier notifier, Future Function() loadFn) {
    final _load = () async {
      if (_i == 0) {
        return;
      }

      try {
        await loadFn();
        // and we're back online!
        _i = 0;
        notifier.state = notifier.state.copyWith(exception: null);
      } catch (e) {
        // notify error and remove isLoading state
        notifier.state = notifier.state
            .copyWith(exception: DataException(e), isLoading: false);
      }
    };

    // listener will be disposed with notifier's lifecycle
    notifier.addListener((state) {
      if (state.hasException) {
        final errors = (state.exception as DataException).errors;
        if (errors is SocketException || errors is TimeoutException) {
          _i++;
          Future.delayed(retryAfter(_i), _load);
        }
      }
    }, fireImmediately: false);
  }

  @override
  DataStateNotifier<List<T>> watchAll(
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    final notifier =
        super.watchAll(remote: remote, params: params, headers: headers);
    _addListener(notifier, () => loadAll(params: params, headers: headers));
    return notifier;
  }

  @override
  DataStateNotifier<T> watchOne(String id,
      {bool remote = true,
      Map<String, String> params,
      Map<String, String> headers}) {
    final notifier =
        super.watchOne(id, remote: remote, params: params, headers: headers);
    _addListener(notifier, () => loadOne(id, params: params, headers: headers));
    return notifier;
  }
}
