library notifier_extension;

import 'dart:async';

import 'package:state_notifier/state_notifier.dart';
import 'package:data_state/data_state.dart';

class _FunctionalStateNotifier<T> extends StateNotifier<T> {
  final StateNotifier<T> _source;
  _FunctionalStateNotifier(this._source) : super(null);
  RemoveListener _disposeFn;
  Timer _timer;
  bool _dirty = false;
  // StreamController<T> _controller;

  StateNotifier<T> where(bool Function(T) test) {
    _disposeFn = _source.addListener((_state) {
      if (test(_state)) {
        state = _state;
      }
    }, fireImmediately: false);
    return this;
  }

  void forEach(void Function(T) action) {
    _disposeFn = _source.addListener(action, fireImmediately: false);
  }

  StateNotifier<T> map(T Function(T) convert) {
    _disposeFn = _source.addListener((state) {
      super.state = convert(state);
    }, fireImmediately: false);
    return this;
  }

  T _unthrottledState;

  StateNotifier<T> throttle(int delay) {
    _disposeFn = _source.addListener((state) {
      if (_timer == null) {
        _dirty = false;
        super.state = state;
        _timer = _makeTimer(delay);
      } else {
        _dirty = true;
      }
      _unthrottledState = state;
    }, fireImmediately: false);
    return this;
  }

  Timer _makeTimer(int delay) {
    return Timer(Duration(seconds: delay), () {
      if (mounted) {
        if (_dirty) {
          _dirty = false;
          _timer = _makeTimer(delay);
          super.state = _unthrottledState;
        } else {
          _timer = null;
        }
      }
    });
  }

  // stream support

  // Stream<T> get stream {
  //   // lazy init
  //   return (_controller ??= StreamController<T>(onCancel: dispose)).stream;
  // }

  // @override
  // set state(T value) {
  //   super.state = value;
  //   _controller?.add(state);
  // }

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
    return _FunctionalStateNotifier<T>(this).where(test);
  }

  StateNotifier<T> map(T Function(T) convert) {
    return _FunctionalStateNotifier<T>(this).map(convert);
  }

  void forEach(void Function(T) action) {
    return _FunctionalStateNotifier<T>(this).forEach(action);
  }

  // updates state maximum once per [delay]
  StateNotifier<T> throttle(int delay) {
    return _FunctionalStateNotifier<T>(this).throttle(delay);
  }

  Stream<T> get stream {
    return _FunctionalStateNotifier<T>(this).stream;
  }
}

//

class TestStateNotifier extends DataStateNotifier<int> {
  TestStateNotifier() : super(DataState<int>(model: 0)) {
    Timer.periodic(
        Duration(seconds: 1), (i) => state = state.copyWith(model: i.tick));
  }
}

void main() {
  TestStateNotifier()
      .map((state) => state.copyWith(model: state.model * 3))
      .where((state) => state.model % 2 == 0)
      .throttle(1)
      .forEach(print);
}
