part of flutter_data;

/// For exclusive internal use of global service locator
/// integration such as `get_it`'s
dynamic debugGlobalServiceLocatorInstance;

class DataHelpers {
  static final uuid = Uuid();

  static String getType<T>([String type]) {
    if (T == dynamic && type == null) {
      return null;
    }
    return (type ?? T.toString()).toLowerCase().pluralize();
  }

  static String generateKey<T>([String type]) {
    final ts = getType<T>(type);
    if (ts == null) {
      return null;
    }
    return '${getType<T>(type)}#${uuid.v1().substring(0, 8)}';
  }
}

@protected
mixin NothingMixin {}

// private utilities

abstract class _Lifecycle<T> {
  bool _isInit = false;

  @mustCallSuper
  // ignore: missing_return
  FutureOr<T> initialize() async {
    _isInit = true;
  }

  @protected
  bool get isInitialized => _isInit;

  @mustCallSuper
  Future<void> dispose() async {}
}

extension _IterableX<T> on Iterable<T> {
  bool containsFirst(T model) => isNotEmpty ? first == model : false;
  Iterable<T> get filterNulls => where((elem) => elem != null);
  List<T> toImmutableList() => List.unmodifiable(this);
}

extension StringUtilsX on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  String pluralize() => inflection.pluralize(this);
  String singularize() => inflection.singularize(this);
}

// state notifier utils

class ValueStateNotifier<E> extends StateNotifier<E> {
  ValueStateNotifier([E state]) : super(state);
  E get value => state;
  set value(E value) => state = value;
}

class RepositoryInitializerNotifier extends ValueStateNotifier<bool> {
  RepositoryInitializerNotifier(bool value) : super(value);
  bool get isLoading => !value;
}
