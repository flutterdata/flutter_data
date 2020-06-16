import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:flutter_data/src/util/notifier_extension.dart';

mixin OfflineAdapter<T extends DataSupportMixin<T>> on WatchAdapter<T> {
  Duration retryAfter(int i) {
    final list = [0, 1, 2, 2, 2, 2, 2, 4, 4, 4, 8, 8, 16, 16, 24];
    final index = i < list.length ? i : list.length - 1;
    return Duration(seconds: list[index]);
  }

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
          Future.delayed(retryAfter(_i), _load);
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

  final writeNotifier = DataStateNotifier<T>(DataState(null));
  DataGraphNotifier _graphNotifier;

  @override
  void initialize() {
    // _graphNotifier = manager.graph
    //   ..addListener((state) {
    //     final pending =
    //         state.graph.nodes.where((e) => e.startsWith('offline#'));
    //     if (pending.isNotEmpty) {
    //       for (var key in pending) {
    //         final actualFDKey =
    //             manager.graph.getEdge(key, metadata: 'offline').first;
    //         // fetch actualFDKey from local and re-attempt to save remote
    //         // remove from graph if succeeded
    //       }
    //     }
    //   });
  }

  DataStateNotifier<T> watchSave(T model,
      {Map<String, dynamic> params, Map<String, String> headers}) {
    final _attemptSave = () async {
      if (_i == 0) {
        return;
      }

      try {
        final newModel = await super
            .save(model, remote: true, params: params, headers: headers);
        // and we're back online!
        // remove from queue
        // _graphNotifier.removeNode();  // keyFor(model)
        _i = 0;
        writeNotifier.data =
            writeNotifier.data.copyWith(model: newModel, exception: null);
      } on DataException catch (e) {
        // notify error and remove isLoading state
        writeNotifier.data = writeNotifier.data
            .copyWith(exception: DataException(e), isLoading: false);
      }
    };

    writeNotifier.forEach((state) {
      if (state.hasException) {
        final errors = (state.exception as DataException).errors;
        if (errors is SocketException || errors is TimeoutException) {
          // add to queue

          _i++;
          // re-attempt
          Future.delayed(retryAfter(_i), _attemptSave);
        }
      }
    });

    //
    _attemptSave();
    return writeNotifier;
  }

  @override
  Future<T> save(T model,
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    try {
      // first ensure model is stored locally (and initialized)
      model = await model.save(remote: false);
      // then try to reach the network
      return await super
          .save(model, remote: true, params: params, headers: headers);
    } on DataException {
      // queue = queue..[keyFor(model)] = 'SAVE';
      rethrow;
    }
  }
}
