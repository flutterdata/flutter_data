import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'models/pet.dart';

class HiveMock extends Mock implements HiveInterface {}

class FakeBox<T> extends Fake implements Box<T> {
  final _map = <String, T>{};
  final _subject = BehaviorSubject<T>();

  @override
  T get(key, {T defaultValue}) {
    return _map[key] ?? defaultValue;
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
  Stream<BoxEvent> watch({key}) {
    return _subject.stream.map((value) => BoxEvent(null, value, false));
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
  Future<void> deleteFromDisk() async {
    await clear();
  }

  @override
  Future<int> clear() {
    _map.clear();
    return Future.value(0);
  }

  @override
  Future<void> close() => Future.value();
}

class TestDataManager extends DataManager {
  TestDataManager(this.locator) : super.delegate();
  @override
  final Locator locator;
  @override
  final keysBox = FakeBox<String>();

  @override
  Future<DataManager> init(FutureOr<Directory> baseDir, Locator locator,
      {bool clear, bool verbose}) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }
}

final injection = DataServiceLocator();

final Function() setUpAllFn = () {
  injection.register(HiveMock());
  final manager = TestDataManager(injection.locator);
  injection.register<DataManager>(manager);

  final houseLocalAdapter = $HouseLocalAdapter(manager, box: FakeBox<House>());
  final familyLocalAdapter =
      $FamilyLocalAdapter(manager, box: FakeBox<Family>());
  final personLocalAdapter =
      $PersonLocalAdapter(manager, box: FakeBox<Person>());
  final dogLocalAdapter = $DogLocalAdapter(manager, box: FakeBox<Dog>());

  injection.register<LocalAdapter<House>>(houseLocalAdapter);
  injection.register<LocalAdapter<Family>>(familyLocalAdapter);
  injection.register<LocalAdapter<Person>>(personLocalAdapter);
  injection.register<LocalAdapter<Dog>>(dogLocalAdapter);

  injection.register<Repository<House>>(
      $HouseRepository(houseLocalAdapter, remote: false));
  injection.register<Repository<Family>>($FamilyRepository(familyLocalAdapter));
  injection.register<Repository<Person>>($PersonRepository(personLocalAdapter));
  injection.register<Repository<Dog>>($DogRepository(dogLocalAdapter));

  injection.register<FamilyRepositoryWithStandardJSONAdapter>(
      FamilyRepositoryWithStandardJSONAdapter(familyLocalAdapter));
};

final Function() tearDownAllFn = () async {
  await injection.locator<Repository<House>>().dispose();
  await injection.locator<Repository<Family>>().dispose();
  await injection.locator<Repository<Person>>().dispose();
  await injection.locator<Repository<Dog>>().dispose();
  injection.clear();
};

class FamilyRepositoryWithStandardJSONAdapter = $FamilyRepository
    with StandardJSONAdapter;
