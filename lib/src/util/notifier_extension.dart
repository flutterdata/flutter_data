library notifier_extension;

import 'dart:async';

import 'package:state_notifier/state_notifier.dart';
import 'package:data_state/data_state.dart';

class _FunctionalStateNotifier<S, T> extends StateNotifier<T> {
  final StateNotifier<S> _source;
  _FunctionalStateNotifier(this._source) : super(null);
  RemoveListener _disposeFn;
  Timer _timer;
  StreamController<T> _controller;

  StateNotifier<T> where(bool Function(S) test) {
    _disposeFn = _source.addListener((_state) {
      if (test(_state)) {
        state = _state as T;
      }
    }, fireImmediately: false);
    return this;
  }

  void forEach(void Function(S) action) {
    _disposeFn = _source.addListener(action, fireImmediately: false);
  }

  StateNotifier<T> map(T Function(S) convert) {
    _disposeFn = _source.addListener((state) {
      super.state = convert(state);
    }, fireImmediately: false);
    return this;
  }

  final _bufferedState = <S>[];

  StateNotifier<T> throttle(Duration duration) {
    _timer = _makeTimer(duration);
    _disposeFn = _source.addListener((model) {
      _bufferedState.add(model);
    }, fireImmediately: false);
    return this;
  }

  Timer _makeTimer(Duration duration) {
    return Timer(duration, () {
      if (mounted) {
        super.state = _bufferedState as T; // since T == List<S>
        _bufferedState.clear(); // clear buffer
        _timer = _makeTimer(duration); // reset timer
      }
    });
  }

  // stream support

  Stream<T> get stream {
    // lazy init
    return (_controller ??= StreamController<T>(onCancel: dispose)).stream;
  }

  @override
  set state(T value) {
    super.state = value;
    _controller?.add(state);
  }

  // @override
  // void Function(dynamic, StackTrace) get onError =>
  //     (error, trace) => _controller?.addError(error, trace);

  @override
  void dispose() {
    _timer?.cancel();
    _disposeFn?.call();
    super.dispose();
  }
}

extension StateNotifierX<T> on StateNotifier<T> {
  StateNotifier<T> where(bool Function(T) test) {
    return _FunctionalStateNotifier<T, T>(this).where(test);
  }

  StateNotifier<T> map(T Function(T) convert) {
    return _FunctionalStateNotifier<T, T>(this).map(convert);
  }

  void forEach(void Function(T) action) {
    _FunctionalStateNotifier<T, void>(this).forEach(action);
  }

  /// Updates state maximum once per [duration]
  StateNotifier<List<T>> throttle(Duration duration) {
    return _FunctionalStateNotifier<T, List<T>>(this).throttle(duration);
  }

  Stream<T> get stream {
    return _FunctionalStateNotifier<T, T>(this).stream;
  }
}

//

class TestStateNotifier extends DataStateNotifier<int> {
  TestStateNotifier() : super(DataState(0)) {
    Timer.periodic(
        Duration(seconds: 1), (i) => state = state.copyWith(model: i.tick));
  }
}

void main() {
  TestStateNotifier()
      .map((state) => state.copyWith(model: state.model * 3))
      .where((state) => state.model % 2 == 0)
      .throttle(Duration(seconds: 8))
      .forEach((numbers) => print(numbers.map((e) => e.model).join(', ')));
}
