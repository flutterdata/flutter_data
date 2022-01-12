part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static const uuid = Uuid();

  static String getTypeFromClass<T>() {
    return T.toString().decapitalize().pluralize();
  }

  static String getTypeFromString(String type) {
    return type.decapitalize().pluralize();
  }

  static String generateKeyFromClass<T>() {
    return StringUtils.typify(getTypeFromClass<T>(), uuid.v1().substring(0, 8));
  }

  static String generateKeyFromString(String type) {
    return StringUtils.typify(getTypeFromString(type), uuid.v1().substring(0, 8));
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

typedef OneProvider<T extends DataModel<T>> = AutoDisposeStateNotifierProvider<DataStateNotifier<T?>, DataState<T?>>
    Function(
  dynamic id, {
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  AlsoWatch<T>? alsoWatch,
});

typedef AllProvider<T extends DataModel<T>>
    = AutoDisposeStateNotifierProvider<DataStateNotifier<List<T>>, DataState<List<T>>> Function({
  bool? remote,
  Map<String, dynamic>? params,
  Map<String, String>? headers,
  bool? syncLocal,
});
