part of flutter_data;

typedef FutureFn<R> = FutureOr<R> Function();

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String type]) {
    if (T == dynamic && type == null) {
      return null;
    }
    type ??= T.toString();
    type = type.decapitalize();
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

class OfflineException extends DataException {
  final DataModel model;
  final String id;
  OfflineException({Object error, this.model, this.id}) : super(error);
  @override
  String toString() {
    return 'OfflineException: $error';
  }
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
