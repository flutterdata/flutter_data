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
  dynamic id, {
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
