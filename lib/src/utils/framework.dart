part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

typedef OnData<R> = FutureOr<R> Function(dynamic);

typedef OnDataError<R> = FutureOr<R> Function(DataException);

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String type]) {
    if (T == dynamic && type == null) {
      return null;
    }
    type ??= T.toString();
    if (type.isNotEmpty) {
      type = type[0].toLowerCase() + type.substring(1);
    }
    return type.pluralize();
  }

  static String generateKey<T>([String type]) {
    type = getType<T>(type);
    if (type != null) {
      return '$type#${uuid.v1().substring(0, 8)}';
    }
    return null;
  }
}

class OfflineException<T extends DataModel<T>> extends DataException {
  final T model;
  OfflineException({this.model, Object source}) : super(source);
}

abstract class _Lifecycle<T> {
  bool _isInit = false;

  @mustCallSuper
  // ignore: missing_return
  FutureOr<T> initialize() async {
    _isInit = true;
  }

  @protected
  @visibleForTesting
  bool get isInitialized => _isInit;

  @mustCallSuper
  void dispose() {
    _isInit = false;
  }
}
