import 'dart:async';
import 'dart:io';

import 'package:flutter_data/src/util/graph_notifier.dart';
import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import '../models/family.dart';
import '../models/house.dart';
import '../models/person.dart';
import '../models/pet.dart';

// mocks, fakes and test impls

class HiveMock extends Mock implements HiveInterface {}

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

class Bloc {
  final Repository<Family> repo;
  Bloc(this.repo);
}

class MockFamilyRepository extends Mock implements Repository<Family> {}

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

// repositories

mixin NoThrottleAdapter<T extends DataSupport<T>> on Repository<T> {
  @override
  Duration get throttleDuration => Duration.zero;
}

class HouseRepository = $HouseRepository with NoThrottleAdapter;

class FamilyRepository = $FamilyRepository with NoThrottleAdapter;

class FamilyRepositoryWithStandardJSONAdapter = $FamilyRepository
    with StandardJSONAdapter;

class PersonRepository = $PersonRepository
    with TestLoginAdapter, NoThrottleAdapter;

// global setup and teardown

final injection = DataServiceLocator();

DataManager manager;

final Function() setUpAllFn = () {
  injection.register(HiveMock());
  manager = TestDataManager(injection.locator);
  injection.register<DataManager>(manager);

  injection.register<Repository<House>>(HouseRepository(
    manager,
    remote: false,
    box: FakeBox<House>(),
  ));
  injection.register<Repository<Family>>(FamilyRepository(
    manager,
    remote: false,
    box: FakeBox<Family>(),
  ));
  injection.register<Repository<Person>>(PersonRepository(
    manager,
    remote: false,
    box: FakeBox<Person>(),
  ));
  injection.register<Repository<Dog>>($DogRepository(
    manager,
    remote: false,
    box: FakeBox<Dog>(),
  ));
  injection.register<FamilyRepositoryWithStandardJSONAdapter>(
      FamilyRepositoryWithStandardJSONAdapter(
    manager,
    remote: false,
    box: FakeBox<Family>(),
  ));
};

final Function() tearDownAllFn = () async {
  await injection.locator<Repository<House>>().dispose();
  await injection.locator<Repository<Family>>().dispose();
  await injection.locator<Repository<Person>>().dispose();
  await injection.locator<Repository<Dog>>().dispose();
  injection.clear();
};

// utils

/// Runs `fn` and waits by default 1 millisecond (tests have a throttle of Duration.zero)
Future<void> runAndWait(Function fn,
    [Duration duration = const Duration(milliseconds: 1)]) async {
  await fn.call();
  await Future.delayed(duration);
}
