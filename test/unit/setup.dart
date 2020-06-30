import 'dart:async';
import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../models/family.dart';
import '../models/house.dart';
import '../models/person.dart';
import '../models/pet.dart';
import 'mocks.dart';

final injection = DataServiceLocator();

DataManager manager;
Repository<House> houseRepository;
Repository<Family> familyRepository;
Repository<Person> personRepository;
Repository<Dog> dogRepository;

final Function() setUpAllFn = () {
  injection.register(HiveMock());
  manager = TestDataManager(injection.locator);
  injection.register<DataManager>(manager);

  injection.register<Repository<House>>(HouseRepository(
    manager,
    remote: false,
    box: FakeBox<House>(),
  ));
  houseRepository = injection.locator<Repository<House>>();

  injection.register<Repository<Family>>(FamilyRepository(
    manager,
    remote: false,
    box: FakeBox<Family>(),
  ));
  familyRepository = injection.locator<Repository<Family>>();

  injection.register<Repository<Person>>(PersonRepository(
    manager,
    remote: false,
    box: FakeBox<Person>(),
  ));
  personRepository = injection.locator<Repository<Person>>();

  injection.register<Repository<Dog>>($DogRepository(
    manager,
    remote: false,
    box: FakeBox<Dog>(),
  ));
  dogRepository = injection.locator<Repository<Dog>>();
};

final Function() setUpFn = () async {
  manager.debugClearGraph();
  for (final repo in [
    houseRepository,
    familyRepository,
    personRepository,
    dogRepository
  ]) {
    await repo.box.clear();
    expect(repo.box.keys, isEmpty);
  }
};

final Function() tearDownAllFn = () async {
  await injection.locator<Repository<House>>().dispose();
  await injection.locator<Repository<Family>>().dispose();
  await injection.locator<Repository<Person>>().dispose();
  await injection.locator<Repository<Dog>>().dispose();
  injection.clear();
};

// adapters

mixin NoThrottleAdapter<T extends DataSupport<T>> on WatchAdapter<T> {
  @override
  Duration get throttleDuration => Duration.zero;
}

class HouseRepository = $HouseRepository with NoThrottleAdapter;

class FamilyRepository = $FamilyRepository with NoThrottleAdapter;

class PersonRepository = $PersonRepository
    with TestLoginAdapter, NoThrottleAdapter;

// utils

/// Runs `fn` and waits by default 1 millisecond (tests have a throttle of Duration.zero)
Future<void> runAndWait(Function fn,
    [Duration duration = const Duration(milliseconds: 1)]) async {
  await fn.call();
  await Future.delayed(duration);
}
