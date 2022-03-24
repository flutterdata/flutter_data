part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String? type]) {
    if (T == dynamic && type == null) {
      throw UnsupportedError('Please supply a type');
    }
    type ??= T.toString();
    type = type.decapitalize();
    return type.pluralize();
  }

  static String generateKey<T>([String? type]) {
    type = getType<T>(type);
    return StringUtils.typify(type, uuid.v1().substring(0, 8));
  }
}

class OfflineException extends DataException {
  OfflineException({required Object error}) : super(error);
  @override
  String toString() {
    return 'OfflineException: $error';
  }
}

abstract class _Lifecycle {
  @protected
  @visibleForTesting
  bool get isInitialized;

  void dispose();
}

typedef Watcher = W Function<W>(ProviderListenable<W> provider);

typedef OneProvider<T extends DataModel<T>>
    = AutoDisposeStateNotifierProvider<DataStateNotifier<T?>, DataState<T?>>
        Function(
  Object id, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<T>? alsoWatch,
});

typedef AllProvider<T extends DataModel<T>> = AutoDisposeStateNotifierProvider<
        DataStateNotifier<List<T>>, DataState<List<T>>>
    Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
});

// strategies

class DataStrategies<T extends DataModel<T>> {
  DataStrategies._();

  final Map<String, DataFinderAll<T>> _findersAll = {};
  final Map<String, DataFinderOne<T>> _findersOne = {};
  final Map<String, DataWatcherAll<T>> watchersAll = {};
  final Map<String, DataWatcherOne<T>> watchersOne = {};

  DataStrategies<T> add({
    DataFinderOne<T>? finderOne,
    DataFinderAll<T>? finderAll,
    DataWatcherAll<T>? watcherAll,
    DataWatcherOne<T>? watcherOne,
    required String name,
  }) {
    if (finderOne != null) _findersOne[name] = finderOne;
    if (finderAll != null) _findersAll[name] = finderAll;
    if (watcherAll != null) watchersAll[name] = watcherAll;
    if (watcherOne != null) watchersOne[name] = watcherOne;
    return this;
  }
}

typedef DataFinderAll<T extends DataModel<T>> = Future<List<T>> Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  OnDataError<List<T>>? onError,
});

typedef DataFinderOne<T extends DataModel<T>> = Future<T?> Function(
  Object model, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  OnDataError<T?>? onError,
});

typedef DataWatcherAll<T extends DataModel<T>> = DataStateNotifier<List<T>>
    Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
});

typedef DataWatcherOne<T extends DataModel<T>> = DataStateNotifier<T?> Function(
  Object model, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<T>? alsoWatch,
  String? finder,
});
