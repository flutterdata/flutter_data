part of flutter_data;

const _offlineAdapterKey = '_offline:keys';

mixin _RemoteAdapterOffline<T extends DataModel<T>> on _RemoteAdapter<T> {
  @override
  @mustCallSuper
  Future<void> onInitialized() async {
    await super.onInitialized();
    // wipe out orphans
    graph.removeOrphanNodes();
    // ensure offline nodes exist
    if (!graph.hasNode(_offlineAdapterKey)) {
      graph.addNode(_offlineAdapterKey);
    }
  }

  @override
  FutureOr<R?> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String>? headers,
    bool omitDefaultParams = false,
    DataRequestType requestType = DataRequestType.adhoc,
    String? key,
    String? body,
    OnRawData<R>? onSuccess,
    OnDataError<R>? onError,
  }) async {
    // default key to type#s3mth1ng
    final offlineKey = key ?? DataHelpers.generateKeyFromString(internalType);
    assert(offlineKey.startsWith(internalType));

    // execute request
    return await super.sendRequest<R>(
      uri,
      method: method,
      headers: headers,
      requestType: requestType,
      omitDefaultParams: omitDefaultParams,
      key: key,
      body: body,
      onSuccess: (dynamic data) {
        // remove all operations with this
        // requestType/offlineKey metadata
        OfflineOperation<T>(
          requestType: requestType,
          offlineKey: offlineKey,
          request: '${method.toShortString()} $uri',
          body: body,
          headers: headers,
          onSuccess: onSuccess,
          onError: onError,
          adapter: this,
        ).remove();

        // yield
        return onSuccess?.call(data);
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          // queue a new operation if this is
          // a network error and we're offline
          OfflineOperation<T>(
            requestType: requestType,
            offlineKey: offlineKey,
            request: '${method.toShortString()} $uri',
            body: body,
            headers: headers,
            onSuccess: onSuccess,
            onError: onError,
            adapter: this,
          ).add();

          // wrap error in an OfflineException
          e = OfflineException(error: e.error);

          // call error handler but do not return it
          (onError ?? this.onError).call(e);

          // instead return a fallback model
          switch (requestType) {
            case DataRequestType.findAll:
              return findAll(remote: false, syncLocal: false) as Future<R>;
            case DataRequestType.findOne:
            case DataRequestType.save:
              // call without type (ie 3 not users#3)
              // key! as we know findOne does pass it
              return findOne(key!.detypify(), remote: false) as Future<R?>;
            case DataRequestType.delete:
              return null;
            case DataRequestType.adhoc:
              return null;
          }
        }

        // if it was not a network error

        // remove all operations with this
        // requestType/offlineKey metadata
        OfflineOperation<T>(
          requestType: requestType,
          offlineKey: offlineKey,
          request: '${method.toShortString()} $uri',
          body: body,
          headers: headers,
          onSuccess: onSuccess,
          onError: onError,
          adapter: this,
        ).remove();

        // return handler call
        return (onError ?? this.onError).call(e);
      },
    );
  }

  /// Determines whether [error] was a network error.
  @protected
  @visibleForTesting
  bool isNetworkError(Object error) {
    // timeouts via http's `connectionTimeout` are
    // also socket exceptions
    // we check the exception like this in order not to import `dart:io`
    final _err = error.toString();
    return _err.startsWith('SocketException') ||
        _err.startsWith('Connection closed before full header was received') ||
        _err.startsWith('HandshakeException');
  }

  @protected
  @visibleForTesting
  @nonVirtual
  Set<OfflineOperation<T>> get offlineOperations {
    final node = graph._getNode(_offlineAdapterKey);
    return (node ?? {}).entries.where((e) {
      // extract type from e.g. _offline:users#4:findOne
      return e.key.split(':')[1].startsWith(internalType);
    }).map((e) {
      // get first edge value
      final map = json.decode(e.value.first) as Map<String, dynamic>;
      return OfflineOperation.fromJson(map, this);
    }).toSet();
  }
}

/// Represents an offline request that is pending to be retried.
class OfflineOperation<T extends DataModel<T>> with EquatableMixin {
  const OfflineOperation({
    required this.offlineKey,
    required this.requestType,
    required this.request,
    this.headers,
    this.body,
    this.onSuccess,
    this.onError,
    required this.adapter,
  });

  factory OfflineOperation.fromJson(Map<String, dynamic> json, _RemoteAdapterOffline<T> adapter) {
    return OfflineOperation(
      requestType: _getDataRequestType(json['t'] as String),
      request: json['r'] as String,
      offlineKey: json['k'] as String,
      body: json['b'] as String?,
      headers: json['h'] == null ? null : Map<String, String>.from(json['h'] as Map),
      adapter: adapter,
    );
  }

  final String offlineKey;
  final DataRequestType requestType;
  final String request;
  final Map<String, String>? headers;
  final String? body;
  final OnRawData? onSuccess;
  final OnDataError? onError;
  final _RemoteAdapterOffline<T> adapter;

  /// Metadata format:
  /// _offline:users:d7bcc9a7b72bf90fffd826
  String get metadata => '_offline:${adapter.internalType}:$hash';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      't': requestType.toShortString(),
      'r': request,
      'k': offlineKey,
      'b': body,
      'h': headers,
    };
  }

  Uri get uri {
    return request.split(' ').last.asUri;
  }

  DataRequestMethod get method {
    return DataRequestMethod.values.singleWhere((m) => m.toShortString() == request.split(' ').first);
  }

  /// Adds an edge from the `_offlineAdapterKey` to the `key` for save/delete
  /// and stores header/param metadata. Also stores callbacks.
  void add() {
    // DO NOT proceed if operation is in queue
    if (!adapter.offlineOperations.contains(this)) {
      final node = json.encode(toJson());

      if (adapter._verbose) {
        print('[flutter_data] [${adapter.internalType}] Adding offline operation with metadata: $metadata');
        print('\n\n');
      }

      adapter.graph._addEdge(_offlineAdapterKey, node, metadata: metadata);

      // keep callbacks in memory
      adapter.read(_offlineCallbackProvider)[metadata] ??= [];
      adapter.read(_offlineCallbackProvider)[metadata]!.add([onSuccess, onError]);
    } else {
      // trick
      adapter.graph._notify([_offlineAdapterKey, ''], DataGraphEventType.addEdge);
    }
  }

  /// Removes all edges from the `_offlineAdapterKey` for
  /// current metadata, as well as callbacks from memory.
  void remove() {
    if (adapter.graph._hasEdge(_offlineAdapterKey, metadata: metadata)) {
      adapter.graph._removeEdges(_offlineAdapterKey, metadata: metadata);
      if (adapter._verbose) {
        print('[flutter_data] [${adapter.internalType}] Removing offline operation with metadata: $metadata');
        print('\n\n');
      }

      adapter.read(_offlineCallbackProvider).remove(metadata);
    }
  }

  Future<void> retry() async {
    // look up callbacks (or provide defaults)
    final fns = adapter.read(_offlineCallbackProvider)[metadata] ??
        [
          [null, null]
        ];

    for (final pair in fns) {
      await adapter.sendRequest(
        uri,
        method: method,
        headers: headers,
        requestType: requestType,
        key: offlineKey,
        body: body,
        onSuccess: pair.first as OnRawData?,
        onError: pair.last as OnDataError?,
      );
    }
  }

  /// This getter ONLY makes sense for `findOne` and `save` operations
  T? get model {
    switch (requestType) {
      case DataRequestType.findOne:
        return adapter.localAdapter.findOne(adapter.graph.getKeyForId(adapter.internalType, offlineKey.detypify())!);
      case DataRequestType.save:
        return adapter.localAdapter.findOne(offlineKey);

      case DataRequestType.findAll:
        return null;
      case DataRequestType.delete:
        return null;
      case DataRequestType.adhoc:
        return null;
    }
  }

  @override
  List<Object?> get props => [requestType, request, body, offlineKey, headers];

  @override
  bool get stringify => true;

  // generates a unique memory-independent hash of this object
  String get hash => md5.convert(utf8.encode(toString())).toString();
}

extension OfflineOperationsX on Set<OfflineOperation<DataModel>> {
  /// Retries all offline operations for current type.
  FutureOr<void> retry() async {
    if (isNotEmpty) {
      await Future.wait(
        map((operation) {
          return operation.retry();
        }),
      );
    }
  }

  /// Removes all offline operations.
  void reset() {
    if (isEmpty) {
      return;
    }
    final adapter = first.adapter;
    // removes node and severs edges
    final node = adapter.graph._getNode(_offlineAdapterKey);
    for (final metadata in (node ?? {}).keys.toImmutableList()) {
      adapter.graph._removeEdges(_offlineAdapterKey, metadata: metadata);
    }
    adapter.read(_offlineCallbackProvider).clear();
  }

  /// Filter by [requestType].
  List<OfflineOperation> only(DataRequestType requestType) {
    return where((_) => _.requestType == requestType).toImmutableList();
  }
}

// stores onSuccess/onError function combos
final _offlineCallbackProvider = StateProvider<Map<String, List<List<Function?>>>>((_) => {});

/// Every time there is an offline operation added to/
/// removed from the queue, this will notify clients
/// with all pending types (could be none) such that
/// they can implement their own retry strategy.
final pendingOfflineTypesProvider = StateNotifierProvider<DelayedStateNotifier<Set<String>>, Set<String>?>((ref) {
  final _graph = ref.watch(graphNotifierProvider);

  Set<String> _pendingTypes() {
    final node = _graph._getNode(_offlineAdapterKey)!;
    // obtain types from metadata e.g. _offline:users#4:findOne
    return node.keys.map((m) => m.split(':')[1].split('#')[0]).toSet();
  }

  final notifier = DelayedStateNotifier<Set<String>>();
  // emit initial value
  Timer.run(() {
    if (notifier.mounted) {
      notifier.state = _pendingTypes();
    }
  });

  final _dispose = _graph.where((event) {
    // filter the right events
    return [DataGraphEventType.addEdge, DataGraphEventType.removeEdge].contains(event.type) &&
        event.keys.length == 2 &&
        event.keys.containsFirst(_offlineAdapterKey);
  }).addListener((_) {
    if (notifier.mounted) {
      // recalculate all pending types
      notifier.state = _pendingTypes();
    }
  });

  notifier.onDispose = _dispose;

  return notifier;
});
