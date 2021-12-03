library notifier_extension;

import 'dart:async';

import 'package:state_notifier/state_notifier.dart';

class DelayedStateNotifier<T> extends StateNotifier<T?> {
  DelayedStateNotifier() : super(null);

  @override
  set state(T? value) => super.state = value;

  @override
  RemoveListener addListener(void Function(T) listener,
      {bool fireImmediately = true}) {
    final _listener = (T? value) {
      // if `value` is `null` and `T` is actually a nullable
      // type, then the listener MUST be called with `null`
      if (_typesEqual<T, T?>() && value == null) {
        listener(null as T);
      } else {
        // if `value != null` and `T` is non-nullable, also
        listener(value!);
      }
    };
    return super.addListener(_listener, fireImmediately: false);
  }

  Function? onDispose;

  @override
  void dispose() {
    super.dispose();
    onDispose?.call();
  }

  bool _typesEqual<T1, T2>() => T1 == T2;
}

class _FunctionalStateNotifier<S, T> extends DelayedStateNotifier<T> {
  final DelayedStateNotifier<S> _source;
  final String? name;
  late RemoveListener _sourceDisposeFn;
  Timer? _timer;

  _FunctionalStateNotifier(this._source, {this.name});

  DelayedStateNotifier<T> where(bool Function(S) test) {
    _sourceDisposeFn = _source.addListener((_state) {
      if (test(_state)) {
        state = _state as T;
      }
    }, fireImmediately: false);
    return this;
  }

  DelayedStateNotifier<T> map(T Function(S) convert) {
    _sourceDisposeFn = _source.addListener((state) {
      super.state = convert(state);
    }, fireImmediately: false);
    return this;
  }

  final _bufferedState = <S>[];

  DelayedStateNotifier<T> throttle(Duration Function() durationFn) {
    _timer = _makeTimer(durationFn);
    _sourceDisposeFn = _source.addListener((model) {
      _bufferedState.add(model);
    }, fireImmediately: false);
    return this;
  }

  Timer _makeTimer(Duration Function() durationFn) {
    return Timer(durationFn(), () {
      if (mounted) {
        if (_bufferedState.isNotEmpty) {
          // Cloning the bufferedState list to force
          // calling listeners as workaround (need to figure out
          // where they are previously updated and why
          // super.state == _bufferedState -- and thus no update)
          super.state = [..._bufferedState] as T; // since T == List<S>;
          _bufferedState.clear(); // clear buffer
        }
        _timer = _makeTimer(durationFn); // reset timer
      }
    });
  }

  @override
  RemoveListener addListener(
    Listener<T> listener, {
    bool fireImmediately = true,
  }) {
    final dispose =
        super.addListener(listener, fireImmediately: fireImmediately);
    return () {
      dispose.call();
      _timer?.cancel();
      _sourceDisposeFn.call();
    };
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
    _source.dispose();
    _timer?.cancel();
  }
}

/// Functional utilities for [StateNotifier]
extension StateNotifierX<T> on DelayedStateNotifier<T> {
  /// Filters incoming events by [test]
  DelayedStateNotifier<T> where(bool Function(T) test) {
    return _FunctionalStateNotifier<T, T>(this, name: 'where').where(test);
  }

  /// Maps events of type [T] onto events of type [R] via [convert]
  DelayedStateNotifier<R> map<R>(R Function(T) convert) {
    return _FunctionalStateNotifier<T, R>(this, name: 'map').map(convert);
  }

  /// Buffers all incoming [T] events for a duration obtained via
  /// [durationFn] and emits them as a [List<T>] (unless there were none)
  DelayedStateNotifier<List<T>> throttle(Duration Function() durationFn) {
    return _FunctionalStateNotifier<T, List<T>>(this, name: 'throttle')
        .throttle(durationFn);
  }
}
