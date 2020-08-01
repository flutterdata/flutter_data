import 'dart:async';

import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';

import 'family.dart';

// fakes

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <dynamic, T>{};

  @override
  T get(key, {T defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(key) async {
    _map.remove(key);
  }

  @override
  Map<dynamic, T> toMap() => _map;

  @override
  Iterable get keys => _map.keys;

  @override
  Iterable<T> get values => _map.values;

  @override
  bool containsKey(key) => _map.containsKey(key);

  @override
  int get length => _map.length;

  @override
  Future<void> deleteFromDisk() async {
    await clear();
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Future<int> clear() {
    _map.clear();
    return Future.value(0);
  }

  @override
  Future<void> close() => Future.value();
}

// mocks

class HiveMock extends Mock implements HiveInterface {
  @override
  bool isBoxOpen(String name) => true;

  @override
  void init(String path) {
    return;
  }
}

class MockFamilyRepository extends Mock implements Repository<Family> {}

class Listener<T> extends Mock {
  void call(T value);
}
