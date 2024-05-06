part of flutter_data;

class DataState<T> with EquatableMixin {
  final T model;
  final bool isLoading;
  final DataException? exception;
  final StackTrace? stackTrace;
  final String? message;

  const DataState(
    this.model, {
    this.isLoading = false,
    this.exception,
    this.stackTrace,
    this.message,
  });

  bool get hasException => exception != null;

  bool get hasModel => model != null;

  bool get hasMessage => message != null;

  DataState<T> merge(DataState<T> value) {
    // only optional values do not get overwritten
    return DataState(
      value.model,
      isLoading: value.isLoading,
      exception: value.exception ?? exception,
      stackTrace: value.stackTrace ?? stackTrace,
      message: value.message ?? message,
    );
  }

  @override
  List<Object?> get props => [model, isLoading, exception];

  @override
  bool get stringify => true;
}

class DataException with EquatableMixin implements Exception {
  final Object error;
  final StackTrace? stackTrace;
  final int? statusCode;

  const DataException(this.error, {this.stackTrace, this.statusCode});

  @override
  List<Object?> get props => [error, stackTrace, statusCode];

  @override
  String toString() {
    return 'DataException: $error${statusCode != null ? " [HTTP $statusCode]" : ""}';
  }
}

class DataStateNotifier<T> extends StateNotifier<DataState<T>> {
  DataStateNotifier({
    required DataState<T> data,
    Future<void> Function(DataStateNotifier<T> notifier)? reload,
  })  : _reloadFn = reload,
        super(data);

  // ignore: prefer_final_fields
  Future<void> Function(DataStateNotifier<T>)? _reloadFn;
  void Function()? onDispose;

  DataState<T> get data => super.state;

  void updateWith({
    Object? model = stamp,
    bool? isLoading,
    Object? exception = stamp,
    Object? stackTrace = stamp,
    Object? message = stamp,
  }) {
    super.state = DataState<T>(
      model == stamp ? state.model : model as T,
      isLoading: isLoading ?? state.isLoading,
      exception:
          exception == stamp ? state.exception : exception as DataException?,
      stackTrace:
          stackTrace == stamp ? state.stackTrace : stackTrace as StackTrace?,
      message: message == stamp ? state.message : message as String?,
    );
  }

  Future<void> reload() async {
    return _reloadFn?.call(this);
  }

  @override
  RemoveListener addListener(
    Listener<DataState<T>> listener, {
    bool fireImmediately = true,
  }) {
    Function? dispose;
    if (mounted) {
      dispose = super.addListener(listener, fireImmediately: fireImmediately);
    }
    return () {
      dispose?.call();
      onDispose?.call();
    };
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
  }
}

class _Stamp {
  const _Stamp();
}

const stamp = _Stamp();

class _FunctionalDataStateNotifier<T, W> extends DataStateNotifier<W> {
  final DataStateNotifier<W> _source;
  late RemoveListener _sourceDisposeFn;

  _FunctionalDataStateNotifier(this._source)
      : super(data: _source.data, reload: _source._reloadFn);

  DataStateNotifier<W> where(bool Function(T) test) {
    _sourceDisposeFn = _source.addListener((state) {
      if (state.hasModel) {
        W model;

        if (_typesEqual<W, List<T>>()) {
          model = (state.model as List<T>).where(test).toList() as W;
        } else if (_typesEqual<W, T?>()) {
          model = test(state.model as T) ? state.model : null as W;
        } else {
          throw UnsupportedError('W must either be T? or List<T>?');
        }

        super.state = DataState(model,
            isLoading: state.isLoading,
            exception: state.exception,
            stackTrace: state.stackTrace);
      }
    });
    return this;
  }

  DataStateNotifier<W> map(T Function(T) convert) {
    _sourceDisposeFn = _source.addListener((state) {
      if (state.hasModel) {
        W model;

        if (_typesEqual<W, List<T>>()) {
          model = (state.model as List<T>).map(convert).toList() as W;
        } else if (_typesEqual<W, T>()) {
          model = convert(state.model as T) as W;
        } else {
          throw UnsupportedError('W must either be T or List<T>?');
        }

        super.state = DataState(model,
            isLoading: state.isLoading,
            exception: state.exception,
            stackTrace: state.stackTrace);
      }
    });
    return this;
  }

  bool _typesEqual<T1, T2>() => T1 == T2;

  @override
  RemoveListener addListener(
    Listener<DataState<W>> listener, {
    bool fireImmediately = true,
  }) {
    final dispose =
        super.addListener(listener, fireImmediately: fireImmediately);
    return () {
      dispose.call();
      _sourceDisposeFn.call();
    };
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
    if (_source.mounted) {
      _source.dispose();
    }
  }
}

/// Functional utilities for [DataStateNotifier]
extension DataStateNotifierListX<T> on DataStateNotifier<List<T>> {
  /// Filters all models of the list (if present) through [test]
  DataStateNotifier<List<T>> where(bool Function(T) test) {
    return _FunctionalDataStateNotifier<T, List<T>>(this).where(test);
  }

  /// Maps all models of the list (if present) through [convert]
  DataStateNotifier<List<T>> map(T Function(T) convert) {
    return _FunctionalDataStateNotifier<T, List<T>>(this).map(convert);
  }
}

/// Functional utilities for [DataStateNotifier]
extension DataStateNotifierX<T> on DataStateNotifier<T> {
  /// Filters all models of the list (if present) through [test]
  DataStateNotifier<T> where(bool Function(T) test) {
    return _FunctionalDataStateNotifier<T, T>(this).where(test);
  }

  /// Maps all models of the list (if present) through [convert]
  DataStateNotifier<T> map(T Function(T) convert) {
    return _FunctionalDataStateNotifier<T, T>(this).map(convert);
  }
}
