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

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(T state) : super(state);
  T get value => super.state;
  set value(T value) => super.state = value;
  Function? onDispose;

  @override
  void dispose() {
    super.dispose();
    onDispose?.call();
  }
}
