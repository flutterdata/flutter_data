import 'dart:async';
import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart' hide Family;

import '../models/family.dart';
import '../models/house.dart';
import '../models/person.dart';
import '../models/pet.dart';
import 'mocks.dart';

// adapters

class TestHiveLocalStorage implements HiveLocalStorage {
  @override
  HiveInterface get hive => HiveMock();

  @override
  HiveAesCipher get encryptionCipher => null;

  @override
  Future<void> initialize() async {}
}

mixin TestMetaBox on DataGraphNotifier {
  @override
  // ignore: must_call_super
  Future<DataGraphNotifier> initialize() async {
    await super.initialize();
    box = FakeBox<Map>();
    return this;
  }
}

mixin TestHiveLocalAdapter<T extends DataSupport<T>> on HiveLocalAdapter<T> {
  @override
  // ignore: must_call_super
  Future<TestHiveLocalAdapter<T>> initialize() async {
    await graph.initialize();
    box = FakeBox<T>();
    return this;
  }
}

mixin NoThrottleAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  Duration get throttleDuration => Duration.zero;
}

//

class TestDataGraphNotifier = DataGraphNotifier with TestMetaBox;

// ignore: must_be_immutable
class HouseLocalAdapter = $HouseHiveLocalAdapter
    with TestHiveLocalAdapter<House>;
class HouseRemoteAdapter = $HouseRemoteAdapter with NoThrottleAdapter;

// ignore: must_be_immutable
class FamilyLocalAdapter = $FamilyHiveLocalAdapter
    with TestHiveLocalAdapter<Family>;
class FamilyRemoteAdapter = $FamilyRemoteAdapter with NoThrottleAdapter;

// ignore: must_be_immutable
class PersonLocalAdapter = $PersonHiveLocalAdapter
    with TestHiveLocalAdapter<Person>;
class PersonRemoteAdapter = $PersonRemoteAdapter
    with TestLoginAdapter, NoThrottleAdapter;

// ignore: must_be_immutable
class DogLocalAdapter = $DogHiveLocalAdapter with TestHiveLocalAdapter<Dog>;

//

ProviderStateOwner owner;
Box<Map> metaBox;
DataGraphNotifier graph;

LocalAdapter<House> houseLocalAdapter;
LocalAdapter<Family> familyLocalAdapter;
LocalAdapter<Person> personLocalAdapter;
LocalAdapter<Dog> dogLocalAdapter;

RemoteAdapter<House> houseRemoteAdapter;
RemoteAdapter<Family> familyRemoteAdapter;
RemoteAdapter<Person> personRemoteAdapter;

Repository<Family> familyRepository;
Repository<House> houseRepository;
Repository<Person> personRepository;
Repository<Dog> dogRepository;

void setUpFn() async {
  owner = createOwner();
  graph = graphProvider.readOwner(owner);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  final adapterGraph = <String, RemoteAdapter<DataSupport>>{
    'houses': housesRemoteAdapterProvider.readOwner(owner),
    'families': familiesRemoteAdapterProvider.readOwner(owner),
    'people': peopleRemoteAdapterProvider.readOwner(owner),
    'dogs': dogsRemoteAdapterProvider.readOwner(owner),
  };

  houseLocalAdapter = housesLocalAdapterProvider.readOwner(owner);
  familyLocalAdapter = familiesLocalAdapterProvider.readOwner(owner);
  personLocalAdapter = peopleLocalAdapterProvider.readOwner(owner);
  dogLocalAdapter = dogsLocalAdapterProvider.readOwner(owner);

  houseRemoteAdapter = housesRemoteAdapterProvider.readOwner(owner);
  familyRemoteAdapter = familiesRemoteAdapterProvider.readOwner(owner);
  personRemoteAdapter = peopleRemoteAdapterProvider.readOwner(owner);

  houseRepository = await housesRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
      );

  familyRepository =
      await familiesRepositoryProvider.readOwner(owner).initialize(
            remote: false,
            verbose: true,
            adapters: adapterGraph,
          );

  personRepository = await peopleRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
      );

  dogRepository = await dogsRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
      );
}

ProviderStateOwner createOwner() {
  return ProviderStateOwner(
    overrides: [
      hiveLocalStorageProvider
          .overrideAs(Provider((_) => TestHiveLocalStorage())),
      graphProvider.overrideAs(Provider(
          (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),
      housesLocalAdapterProvider.overrideAs(Provider((ref) => HouseLocalAdapter(
          ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      familiesLocalAdapterProvider.overrideAs(Provider((ref) =>
          FamilyLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      peopleLocalAdapterProvider.overrideAs(Provider((ref) =>
          PersonLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      dogsLocalAdapterProvider.overrideAs(Provider((ref) => DogLocalAdapter(
          ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      housesRemoteAdapterProvider.overrideAs(Provider(
          (ref) => HouseRemoteAdapter(ref.read(housesLocalAdapterProvider)))),
      familiesRemoteAdapterProvider.overrideAs(Provider((ref) =>
          FamilyRemoteAdapter(ref.read(familiesLocalAdapterProvider)))),
      peopleRemoteAdapterProvider.overrideAs(Provider(
          (ref) => PersonRemoteAdapter(ref.read(peopleLocalAdapterProvider)))),
    ],
  );
}

// utils

/// Runs `fn` and waits by default 1 millisecond (tests have a throttle of Duration.zero)
Future<void> runAndWait(Function fn,
    [Duration duration = const Duration(milliseconds: 1)]) async {
  await fn.call();
  await Future.delayed(duration);
}
