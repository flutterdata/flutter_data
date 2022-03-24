library data_state;

import 'package:equatable/equatable.dart';
import 'package:state_notifier/state_notifier.dart';

class DataState<T> with EquatableMixin {
  final T model;
  final bool isLoading;
  final DataException? exception;
  final StackTrace? stackTrace;

  const DataState(
    this.model, {
    this.isLoading = false,
    this.exception,
    this.stackTrace,
  });

  bool get hasException => exception != null;

  bool get hasModel => model != null;

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
    return 'DataException: $error ${statusCode != null ? " [HTTP $statusCode]" : ""}\n${stackTrace ?? ''}';
  }
}

class DataStateNotifier<T> extends StateNotifier<DataState<T>> {
  DataStateNotifier({
    required DataState<T> data,
    Future<void> Function(DataStateNotifier<T>)? reload,
  })  : _reloadFn = reload,
        super(data);

  final Future<void> Function(DataStateNotifier<T>)? _reloadFn;
  void Function()? onDispose;

  DataState<T> get data => super.state;

  void updateWith({
    Object? model = stamp,
    bool? isLoading,
    Object? exception = stamp,
    Object? stackTrace = stamp,
  }) {
    super.state = DataState<T>(
      model == stamp ? state.model : model as T,
      isLoading: isLoading ?? state.isLoading,
      exception:
          exception == stamp ? state.exception : exception as DataException?,
      stackTrace:
          stackTrace == stamp ? state.stackTrace : stackTrace as StackTrace?,
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
    final dispose =
        super.addListener(listener, fireImmediately: fireImmediately);
    return () {
      dispose();
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
        W _model;

        if (_typesEqual<W, List<T>>()) {
          _model = (state.model as List<T>).where(test).toList() as W;
        } else if (_typesEqual<W, T?>()) {
          _model = test(state.model as T) ? state.model : null as W;
        } else {
          throw UnsupportedError('W must either be T? or List<T>');
        }

        super.state = DataState(_model,
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
        W _model;

        if (_typesEqual<W, List<T>>()) {
          _model = (state.model as List<T>).map(convert).toList() as W;
        } else if (_typesEqual<W, T>()) {
          _model = convert(state.model as T) as W;
        } else {
          throw UnsupportedError('W must either be T or List<T>');
        }

        super.state = DataState(_model,
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
    _source.dispose();
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
