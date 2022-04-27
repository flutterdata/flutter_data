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

  static String generateShortKey<T>() {
    return uuid.v1().substring(0, 6);
  }

  static String generateKey<T>([String? type]) {
    type = getType<T>(type);
    return uuid.v1().substring(0, 8).typifyWith(type);
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

class InternalHolder<T extends DataModel<T>> {
  final Map<String, dynamic> finders;
  InternalHolder(this.finders);
}

// finders

class DataFinder {
  const DataFinder();
}

typedef DataFinderAll<T extends DataModel<T>> = Future<List<T>?> Function({
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  OnSuccess<List<T>>? onSuccess,
  OnError<List<T>>? onError,
  DataRequestLabel? label,
});

typedef DataFinderOne<T extends DataModel<T>> = Future<T?> Function(
  Object model, {
  bool? remote,
  bool? background,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  OnSuccess<T>? onSuccess,
  OnError<T?>? onError,
  DataRequestLabel? label,
});

typedef DataWatcherAll<T extends DataModel<T>> = DataStateNotifier<List<T>?>
    Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
  String? finder,
  DataRequestLabel? label,
});

typedef DataWatcherOne<T extends DataModel<T>> = DataStateNotifier<T?> Function(
  Object model, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<T>? alsoWatch,
  String? finder,
  DataRequestLabel? label,
});

// watch

typedef Watcher = W Function<W>(ProviderListenable<W> provider);

typedef AlsoWatch<T extends DataModel<T>> = Iterable<Relationship?> Function(T);

/// This argument holder class is used internally with
/// Riverpod `family`s.
class WatchArgs<T extends DataModel<T>> with EquatableMixin {
  WatchArgs({
    this.key,
    this.remote,
    this.params,
    this.headers,
    this.syncLocal,
    this.alsoWatch,
    this.finder,
    this.label,
  });

  final String? key;
  final bool? remote;
  final Map<String, dynamic>? params;
  final Map<String, String>? headers;
  final bool? syncLocal;
  final AlsoWatch<T>? alsoWatch;
  final String? finder;
  final DataRequestLabel? label;

  @override
  List<Object?> get props =>
      [key, remote, params, headers, syncLocal, finder, label];
}
