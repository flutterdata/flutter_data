import 'dart:async';
import 'dart:io';

import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import '../models/family.dart';

// test impls

class TestDataManager extends DataManager {
  TestDataManager(this.locator) : super.delegate() {
    debugGraph = DataGraphNotifier(metaBox);
  }

  @override
  final Locator locator;
  @override
  final metaBox = FakeBox();

  @override
  Future<DataManager> init(FutureOr<Directory> baseDir, Locator locator,
      {bool clear, bool verbose}) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() async {}
}

// fakes

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <String, T>{};
  final _subject = BehaviorSubject<T>();

  @override
  T get(key, {T defaultValue}) {
    return _map[key.toString()] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _subject.add(value);
    _map[key.toString()] = value;
  }

  @override
  Future<void> delete(key) async {
    _map.remove(key);
  }

  @override
  Map<String, T> toMap() => _map;

  @override
  Iterable<String> get keys => _map.keys;

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
  Future<int> clear() {
    _map.clear();
    return Future.value(0);
  }

  @override
  Future<void> close() => Future.value();
}

// mocks

class HiveMock extends Mock implements HiveInterface {}

class MockFamilyRepository extends Mock implements Repository<Family> {}
