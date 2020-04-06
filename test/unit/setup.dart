import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';

class HiveMock extends Mock implements HiveInterface {}

class FakeBox<T> extends Fake implements Box<T> {
  var _map = <String, T>{};
  @override
  T get(key, {T defaultValue}) {
    return _map[key] ?? defaultValue;
  }

  @override
  Future<void> put(key, T value) async {
    _map[key.toString()] = value;
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
  Future<void> close() => Future.value();
}

class TestDataManager extends DataManager {
  TestDataManager(this.locator) : super.delegate(false);
  final Locator locator;
  final Box<String> keysBox = FakeBox<String>();

  @override
  Future<DataManager> init(FutureOr<Directory> baseDir, Locator locator,
      {bool clear = true}) {
    throw UnimplementedError();
  }

  @override
  Future<LocalAdapter<T>> initAdapter<T extends DataSupportMixin<T>>(
      bool clear, LocalAdapter<T> Function(Box<T>) callback) {
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

  final houseLocalAdapter = $HouseLocalAdapter(FakeBox<House>(), manager);
  final familyLocalAdapter = $FamilyLocalAdapter(FakeBox<Family>(), manager);
  final personLocalAdapter = $PersonLocalAdapter(FakeBox<Person>(), manager);

  injection.register<LocalAdapter<House>>(houseLocalAdapter);
  injection.register<LocalAdapter<Family>>(familyLocalAdapter);
  injection.register<LocalAdapter<Person>>(personLocalAdapter);

  injection.register<Repository<House>>($HouseRepository(houseLocalAdapter));
  injection.register<Repository<Family>>($FamilyRepository(familyLocalAdapter));
  injection.register<Repository<Person>>($PersonRepository(personLocalAdapter));

  injection.register<FamilyRepositoryWithStandardJSONAdapter>(
      FamilyRepositoryWithStandardJSONAdapter(familyLocalAdapter));
};

final Function() tearDownAllFn = () async {
  await injection.locator<Repository<House>>().dispose();
  await injection.locator<Repository<Family>>().dispose();
  await injection.locator<Repository<Person>>().dispose();
  injection.clear();
};

class FamilyRepositoryWithStandardJSONAdapter = $FamilyRepository
    with StandardJSONAdapter;
