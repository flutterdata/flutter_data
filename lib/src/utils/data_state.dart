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
