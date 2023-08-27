import 'dart:async';

import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <dynamic, T>{};

  @override
  bool isOpen = true;

  @override
  T? get(key, {T? defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key] = value;
  }

  @override
  bool delete(key) {
    _map.remove(key);
    return true;
  }

  @override
  int deleteAll(keys) {
    for (final key in keys) {
      _map.remove(key);
    }
    return keys.length;
  }

  @override
  List<String> get keys => _map.keys.cast<String>().toList();

  @override
  bool containsKey(key) => _map.containsKey(key);

  @override
  int get length => _map.length;

  @override
  Future<void> deleteFromDisk() async {
    clear();
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  void clear({bool notify = false}) {
    _map.clear();
  }

  @override
  Future<void> close() async {
    isOpen = false;
  }
}

class HiveFake extends Fake implements Hive {}

class Listener<T> extends Mock {
  void call(T value);
}
