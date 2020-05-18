library noti;

import 'dart:async';

import 'package:state_notifier/state_notifier.dart';
import 'package:data_state/data_state.dart';

class _FunctionalStateNotifier<T> extends DataStateNotifier<T> {
  final DataStateNotifier<T> _source;
  _FunctionalStateNotifier(this._source) : super(null);
  RemoveListener _disposeFn;
  Timer _timer;
  bool _dirty = false;

  DataStateNotifier<T> where(bool Function(DataState<T>) test) {
    _disposeFn = _source.addListener((_state) {
      if (test(_state)) {
        state = _state;
      }
    });
    return this;
  }

  void forEach(void Function(DataState<T>) action) {
    _disposeFn = _source.addListener(action);
  }

  DataStateNotifier<T> map(DataState<T> Function(DataState<T>) convert) {
    _disposeFn = _source.addListener((state) {
      super.state = convert(state);
    });
    return this;
  }

  DataState<T> _unthrottledState;

  DataStateNotifier<T> throttle(int delay) {
    _disposeFn = _source.addListener((state) {
      if (_timer == null) {
        _dirty = false;
        super.state = state;
        _timer = _makeTimer(delay);
      } else {
        _dirty = true;
      }
      _unthrottledState = state;
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    _disposeFn?.call();
    super.dispose();
  }
}

extension WhereDataStateNotifierX<T> on DataStateNotifier<T> {
  DataStateNotifier<T> where(bool Function(DataState<T>) test) {
    return _FunctionalStateNotifier<T>(this).where(test);
  }

  DataStateNotifier<T> map(DataState<T> Function(DataState<T>) convert) {
    return _FunctionalStateNotifier<T>(this).map(convert);
  }

  void forEach(void Function(DataState<T>) action) {
    return _FunctionalStateNotifier<T>(this).forEach(action);
  }

  // updates state maximum once per [delay]
  DataStateNotifier<T> throttle(int delay) {
    return _FunctionalStateNotifier<T>(this).throttle(delay);
  }
}

class TestStateNotifier extends DataStateNotifier<int> {
  TestStateNotifier() : super(DataState<int>(model: 0)) {
    Timer.periodic(
        Duration(seconds: 1), (i) => state = state.copyWith(model: i.tick));
  }
}

void main() {
  final notifier = TestStateNotifier()
      .map((state) => state.copyWith(model: state.model * 3))
      .where((state) => state.model % 2 == 0)
      .throttle(1);
  notifier.addListener((state) => print(state.model));
  // notifier.dispose();
}
