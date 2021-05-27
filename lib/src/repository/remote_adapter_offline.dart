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
    if (!graph._hasNode(_offlineAdapterKey)) {
      graph._addNode(_offlineAdapterKey);
    }
  }

  @override
  FutureOr<R> sendRequest<R>(
    final Uri uri, {
    DataRequestMethod method = DataRequestMethod.GET,
    Map<String, String> headers,
    bool omitDefaultParams = false,
    DataRequestType requestType = DataRequestType.adhoc,
    String key,
    String body,
    OnRawData<R> onSuccess,
    OnDataError<R> onError,
  }) async {
    // default key to type#s3mth1ng
    key ??= DataHelpers.generateKey(internalType);

    // execute request
    return super.sendRequest(
      uri,
      method: method,
      headers: headers,
      requestType: requestType,
      omitDefaultParams: omitDefaultParams,
      key: key,
      body: body,
      onSuccess: (data) {
        // remove all operations with this
        // requestType/offlineKey metadata
        OfflineOperation<T>(
          requestType: requestType,
          offlineKey: key,
          adapter: this,
        ).removeAll();

        // yield
        return onSuccess?.call(data);
      },
      onError: (e) {
        if (isNetworkError(e.error)) {
          // queue a new operation if this is
          // a network error and we're offline
          OfflineOperation<T>(
            requestType: requestType,
            offlineKey: key,
            request: '${method.toShortString()} $uri',
            body: body,
            timestamp: DateTime.now(),
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
              return findAll(remote: false, init: true) as Future<R>;
            case DataRequestType.findOne:
            case DataRequestType.save:
              // call without type (ie 3 not users#3)
              return findOne(key.detypify(), remote: false, init: true)
                  as Future<R>;
            default:
              return null;
          }
        }

        // if it was not a network error

        // remove all operations with this
        // requestType/offlineKey metadata
        OfflineOperation<T>(
          requestType: requestType,
          offlineKey: key,
          adapter: this,
        ).removeAll();

        // return handler call
        return (onError ?? this.onError).call(e);
      },
    );
  }

  /// Determines whether [error] was a network error.
  @protected
  @visibleForTesting
  bool isNetworkError(error) {
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
  List<OfflineOperation<T>> get offlineOperations {
    final node = graph._getNode(_offlineAdapterKey);
    return node.entries.where((e) {
      // extract type from e.g. _offline:users#4:findOne
      return e.key.split(':')[1].startsWith(internalType);
    }).map((e) {
      // get first edge value
      final map = json.decode(e.value.first) as Map<String, dynamic>;
      return OfflineOperation.fromJson(map, this);
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

/// Represents an offline request that is pending to be retried.
class OfflineOperation<T extends DataModel<T>> with EquatableMixin {
  final DataRequestType requestType;
  final String offlineKey;
  final String body;
  final String request;
  final DateTime timestamp;
  final Map<String, String> headers;
  final Function onSuccess;
  final Function onError;
  final _RemoteAdapterOffline<T> adapter;

  const OfflineOperation({
    @required this.offlineKey,
    @required this.requestType,
    this.request,
    this.body,
    this.timestamp,
    this.headers,
    this.onSuccess,
    this.onError,
    this.adapter,
  });

  /// Metadata format:
  /// _offline:users#_:findAll
  /// _offline:users#4:findOne
  /// _offline:users#ab9c31:save
  /// _offline:users#4:delete
  /// _offline:users#a92e98ff:adhoc
  String get metadata => '_offline:$offlineKey:${requestType.toShortString()}';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      't': requestType.toShortString(),
      'r': request,
      'b': body,
      'k': offlineKey,
      'd': timestamp.toIso8601String(),
      'h': headers,
    };
  }

  factory OfflineOperation.fromJson(
      Map<String, dynamic> json, _RemoteAdapterOffline<T> adapter) {
    return OfflineOperation(
      requestType: _getDataRequestType(json['t'] as String),
      request: json['r'] as String,
      offlineKey: json['k'] as String,
      body: json['b'] as String,
      timestamp: DateTime.parse(json['d'] as String),
      headers:
          json['h'] == null ? null : Map<String, String>.from(json['h'] as Map),
      adapter: adapter,
    );
  }

  Uri get uri {
    return request.split(' ').last.asUri;
  }

  DataRequestMethod get method {
    return DataRequestMethod.values.singleWhere(
        (m) => m.toShortString() == request.split(' ').first,
        orElse: () => null);
  }

  Future<void> retry<R>() async {
    final fns = adapter.ref.read(_offlineCallbackProvider).state[metadata];

    // offlineKey of format different than users#ab9c31
    // will return null
    var _body = body;
    if (_body == null) {
      final model = adapter.localAdapter.findOne(offlineKey);
      if (model != null) {
        _body = json.encode(adapter.serialize(model));
      }
    }

    await adapter.sendRequest<R>(
      uri,
      method: method,
      headers: headers,
      requestType: requestType,
      key: offlineKey,
      body: body,
      onSuccess: fns?.first as OnRawData<R>,
      onError: fns?.last as OnDataError<R>,
    );
  }

  /// Adds an edge from the `_offlineAdapterKey` to the `key` for save/delete
  /// and stores header/param metadata. Also stores callbacks.
  void add() {
    final node = json.encode(toJson());

    // remove all previous operations with this metadata
    removeAll();

    adapter.graph._addEdge(_offlineAdapterKey, node, metadata: metadata);

    // keep callbacks in memory
    adapter.ref.read(_offlineCallbackProvider).state[metadata] = [
      onSuccess,
      onError,
    ];
  }

  /// Removes all edges from the `_offlineAdapterKey` for
  /// current metadata, as well as callbacks from memory.
  void removeAll() {
    adapter.graph._removeEdges(_offlineAdapterKey, metadata: metadata);
    adapter.ref.read(_offlineCallbackProvider).state.remove(metadata);
  }

  /// This getter ONLY makes sense for `findOne` and `save` operations
  T get model {
    switch (requestType) {
      case DataRequestType.findOne:
        return adapter.localAdapter.findOne(adapter.graph
            .getKeyForId(adapter.internalType, offlineKey.detypify()));
      case DataRequestType.save:
        return adapter.localAdapter.findOne(offlineKey);
      default:
        return null;
    }
  }

  @override
  List<Object> get props => [metadata];
}

extension OfflineOperationsX on List<OfflineOperation<DataModel>> {
  /// Retries all offline operations for current type.
  FutureOr<void> retry() async {
    if (isNotEmpty) {
      await Future.wait(map((operation) {
        return operation.retry();
      }));
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
    for (final metadata in node.keys.toImmutableList()) {
      adapter.graph._removeEdges(_offlineAdapterKey, metadata: metadata);
    }
    adapter.ref.read(_offlineCallbackProvider).state.clear();
  }

  /// Filter by [requestType].
  List<OfflineOperation> only(DataRequestType requestType) {
    return where((_) => _.requestType == requestType).toImmutableList();
  }
}

// stores onSuccess/onError function combos
final _offlineCallbackProvider =
    StateProvider<Map<String, List<Function>>>((_) => {});

/// Every time there is an offline operation added to the
/// queue, this will notify clients with all pending types
/// such that they can implement their retry strategy.
final pendingOfflineTypesProvider =
    StateNotifierProvider<ValueStateNotifier<Set<String>>>((ref) {
  final _graph = ref.read(graphNotifierProvider);

  Set<String> _pendingTypes() {
    final node = _graph._getNode(_offlineAdapterKey);
    // obtain types from metadata e.g. _offline:users#4:findOne
    return node.keys.map((m) => m.split(':')[1].split('#')[0]).toSet();
  }

  final notifier = ValueStateNotifier(<String>{});
  Timer.run(() {
    notifier.value = _pendingTypes();
  });

  final _dispose = _graph.where((event) {
    // filter the right events
    return event.type == DataGraphEventType.addEdge &&
        event.keys.length == 2 &&
        event.keys.containsFirst(_offlineAdapterKey);
  }).addListener((_) {
    notifier.value = _pendingTypes();
  });

  notifier.onDispose = _dispose;

  return notifier;
});
