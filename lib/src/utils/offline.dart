part of flutter_data;

/// Represents an offline request that is pending to be retried.
class OfflineOperation<T extends DataModelMixin<T>> with EquatableMixin {
  final DataRequestLabel label;
  final String httpRequest;
  final int timestamp;
  final Map<String, String>? headers;
  final String? body;
  late final String? key;
  final _OnSuccessGeneric<T>? onSuccess;
  final _OnErrorGeneric<T>? onError;
  final Adapter<T> adapter;

  OfflineOperation({
    required this.label,
    required this.httpRequest,
    required this.timestamp,
    this.headers,
    this.body,
    String? key,
    this.onSuccess,
    this.onError,
    required this.adapter,
  }) {
    this.key = key ?? label.model?._key;
    if (this.key != null) {
      final model = adapter.findOneLocal(this.key);
      if (model != null) {
        label.model = model;
      }
    }
  }

  // factory OfflineOperation.fromJson(
  //   DataRequestLabel label,
  //   Map<String, dynamic> json,
  //   Adapter<T> adapter,
  // ) {
  //   final operation = OfflineOperation(
  //     label: label,
  //     httpRequest: json['r'] as String,
  //     timestamp: json['t'] as int,
  //     key: json['k'] as String?,
  //     body: json['b'] as String?,
  //     headers:
  //         json['h'] == null ? null : Map<String, String>.from(json['h'] as Map),
  //     adapter: adapter,
  //   );

  //   if (operation.key != null) {
  //     final model = adapter.findOneLocal(operation.key!);
  //     if (model != null) {
  //       operation.label.model = model;
  //     }
  //   }
  //   return operation;
  // }

  Uri get uri {
    return httpRequest.split(' ').last.asUri;
  }

  DataRequestMethod get method {
    return DataRequestMethod.values
        .singleWhere((m) => m.toShortString() == httpRequest.split(' ').first);
  }

  /// Adds an edge from the `_offlineAdapterKey` to the `key` for save/delete
  /// and stores header/param metadata. Also stores callbacks.
  void add() {
    // DO NOT proceed if operation is in queue
    if (!adapter.offlineOperations.contains(this)) {
      adapter.log(label, 'offline/add ${label.requestId}');

      adapter.db.execute(
          'INSERT INTO _offline_operations (label, request, timestamp, headers, body, key) VALUES (?, ?, ?, ?, ?, ?)',
          [
            label.toString(),
            httpRequest,
            timestamp,
            jsonEncode(headers),
            body,
            key
          ]);

      // keep callbacks in memory
      adapter.ref.read(_offlineCallbackProvider)[label.requestId] ??=
          (null, null);
      adapter.ref.read(_offlineCallbackProvider)[label.requestId] =
          (onSuccess, onError);
    }
  }

  /// Removes all edges from the `_offlineAdapterKey` for
  /// current metadata, as well as callbacks from memory.
  static void remove(DataRequestLabel label, Adapter adapter) {
    adapter.db.execute(
        'DELETE FROM _offline_operations WHERE label = ?', [label.toString()]);

    adapter.log(label, 'offline/remove ${label.requestId}');
    adapter.ref.read(_offlineCallbackProvider).remove(label.requestId);
  }

  Future<void> retry() async {
    // look up callbacks (or provide defaults)
    final _cbs = adapter.ref.read(_offlineCallbackProvider);
    final fns = _cbs[label.requestId] ?? (null, null);

    await adapter.sendRequest<T>(
      uri,
      method: method,
      headers: headers,
      label: label,
      body: body,
      onSuccess: fns.$1 as _OnSuccessGeneric<T>?,
      onError: fns.$2 as _OnErrorGeneric<T>?,
    );
  }

  T? get model => label.model as T?;

  @override
  List<Object?> get props => [label];

  @override
  bool get stringify => true;
}

extension OfflineOperationsX on Set<OfflineOperation<DataModelMixin>> {
  /// Retries all offline operations for current type.
  FutureOr<void> retry() async {
    if (isNotEmpty) {
      await Future.wait(map((op) => op.retry()));
    }
  }

  /// Removes all offline operations.
  void reset() {
    if (isEmpty) {
      return;
    }
    final adapter = first.adapter;

    adapter.db.execute('DELETE FROM _offline_operations');

    adapter.ref.read(_offlineCallbackProvider).clear();
  }

  /// Filter by [label] kind.
  List<OfflineOperation> only(DataRequestLabel label) {
    return where((_) => _.label.kind == label.kind).toImmutableList();
  }
}

// stores onSuccess/onError function combos
final _offlineCallbackProvider =
    StateProvider<Map<String, (Function?, Function?)>>((_) => {});

// providers

final offlineRetryProvider = StreamProvider<void>((ref) async* {
  Set<OfflineOperation> _offlineOperations() {
    return _internalAdapters!.values
        .map((adapter) {
          // if the stream is called before initialization
          // (or after disposal) simply return an empty set
          if (!adapter.isInitialized) {
            return <OfflineOperation>{};
          }
          return adapter.offlineOperations;
        })
        .expand((e) => e)
        .toSet();
  }

  final pool = Pool(4, timeout: Duration(seconds: 30));

  var _counter = 0;

  while (true) {
    // sort operations by timestamp
    final ops = _offlineOperations().toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ops.isEmpty) {
      _counter = 0;
      await Future.delayed(Duration(milliseconds: backoffFn(4)));
      continue;
    }

    print(
        '[offline] retrying ${ops.length} operations: ${ops.map((op) => op.label)}');

    try {
      final result = pool.forEach(
        ops,
        (OfflineOperation op) async => op.retry(),
      );
      await for (final _ in result) {}
    } finally {
      final duration =
          Duration(milliseconds: backoffFn(_counter) + ops.length * 50);
      print('[offline] waiting $duration to try again');
      await Future.delayed(duration);
      _counter++;
    }
  }
});

final backoffFn =
    (int i) => [400, 800, 1600, 3200, 6400, 12800, 12800].getSafe(i) ?? 25600;
