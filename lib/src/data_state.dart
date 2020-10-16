library data_state;

import 'package:state_notifier/state_notifier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_state.freezed.dart';

@freezed
abstract class DataState<T> with _$DataState<T> {
  factory DataState(
    @nullable T model, {
    @Default(false) bool isLoading,
    Object exception,
    StackTrace stackTrace,
  }) = _DataState<T>;

  @late
  bool get hasException => exception != null;

  @late
  bool get hasModel => model != null;
}

class DataStateNotifier<T> extends StateNotifier<DataState<T>> {
  DataStateNotifier(
    DataState<T> initialData, {
    Future<void> Function(DataStateNotifier<T>) reload,
  })  : _reloadFn = reload,
        super(initialData ?? DataState<T>(null));

  final Future<void> Function(DataStateNotifier<T>) _reloadFn;
  void Function() onDispose;

  DataState<T> get data => super.state;

  set data(DataState<T> value) {
    super.state = value;
  }

  Future<void> reload() async {
    return _reloadFn?.call(this) ?? ((_) {});
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
  @mustCallSuper
  void dispose() {
    if (mounted) {
      super.dispose();
    }
    onDispose?.call();
  }
}
