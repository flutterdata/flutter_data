library notifier_extension;

import 'dart:async';

import 'package:state_notifier/state_notifier.dart';

class _FunctionalStateNotifier<S, T> extends StateNotifier<T?> {
  final StateNotifier<S> _source;
  final String? name;
  late RemoveListener _sourceDisposeFn;
  Timer? _timer;

  _FunctionalStateNotifier(this._source, {this.name}) : super(null);

  StateNotifier<T?> where(bool Function(S) test) {
    _sourceDisposeFn = _source.addListener((_state) {
      if (test(_state)) {
        state = _state as T;
      }
    }, fireImmediately: false);
    return this;
  }

  StateNotifier<void> forEach(void Function(S) action) {
    _sourceDisposeFn = _source.addListener(action, fireImmediately: false);
    return this;
  }

  StateNotifier<T?> map(T Function(S) convert) {
    _sourceDisposeFn = _source.addListener((state) {
      super.state = convert(state);
    }, fireImmediately: false);
    return this;
  }

  final _bufferedState = <S>[];

  StateNotifier<T?> throttle(Duration Function() durationFn) {
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
          super.state = _bufferedState as T; // since T == List<S>;
          _bufferedState.clear(); // clear buffer
        }
        _timer = _makeTimer(durationFn); // reset timer
      }
    });
  }

  @override
  RemoveListener addListener(
    Listener<T?> listener, {
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
extension StateNotifierX<T> on StateNotifier<T?> {
  /// Filters incoming events by [test]
  StateNotifier<T?> where(bool Function(T?) test) {
    return _FunctionalStateNotifier<T?, T?>(this, name: 'where').where(test);
  }

  /// Maps events of type [T] onto events of type [R] via [convert]
  StateNotifier<R?> map<R>(R Function(T?) convert) {
    return _FunctionalStateNotifier<T?, R>(this, name: 'map').map(convert);
  }

  /// Applies a function [action] to every incoming event of type [T]
  StateNotifier<void> forEach(void Function(T?) action) {
    return _FunctionalStateNotifier<T?, void>(this, name: 'forEach')
        .forEach(action);
  }

  /// Buffers all incoming [T] events for a duration obtained via
  /// [durationFn] and emits them as a [List<T>] (unless there were none)
  StateNotifier<List<T>?> throttle(Duration Function() durationFn) {
    return _FunctionalStateNotifier<T?, List<T>?>(this, name: 'throttle')
        .throttle(durationFn);
  }
}
