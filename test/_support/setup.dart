import 'dart:async';
import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matcher/matcher.dart';
import 'package:riverpod/riverpod.dart' hide Family;

import 'family.dart';
import 'house.dart';
import 'mocks.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

// adapters

class TestHiveLocalStorage extends HiveLocalStorage {
  @override
  HiveInterface get hive => HiveMock();

  @override
  HiveAesCipher get encryptionCipher => null;

  @override
  Future<String> Function() get baseDirFn => () async => '';
}

mixin TestMetaBox on GraphNotifier {
  @override
  // ignore: must_call_super
  Future<GraphNotifier> initialize() async {
    await super.initialize();
    box = FakeBox<Map>();
    return this;
  }
}

mixin TestHiveLocalAdapter<T extends DataModel<T>> on HiveLocalAdapter<T> {
  @override
  // ignore: must_call_super
  Future<TestHiveLocalAdapter<T>> initialize() async {
    await graph.initialize();
    await super.initialize();
    box = FakeBox<T>();
    return this;
  }
}

mixin TestRemoteAdapter<T extends DataModel<T>> on RemoteAdapter<T> {
  @override
  Duration get throttleDuration => Duration.zero;

  @override
  String get baseUrl => '';

  @override
  http.Client get httpClient => MockClient((req) async {
        if (req.url.toString().endsWith('error')) {
          throw SocketException('unreachable');
        }
        return http.Response(
            req.headers['response'], int.parse(req.headers['status'] ?? '200'));
      });
}

// sample token future provider
final tokenFutureProvider = FutureProvider((_) => Future.value('s3cr4t'));

mixin TokenAdapter<T extends DataModel<T>> on RemoteAdapter<T> {
  @override
  FutureOr<Map<String, String>> get defaultHeaders async {
    final token = await ref.read(tokenFutureProvider);
    return await super.defaultHeaders
      ..addAll({'Authorization': token});
  }

  @override
  FutureOr<Map<String, dynamic>> get defaultParams async {
    final token = await ref.read(tokenFutureProvider);
    return await super.defaultParams
      ..addAll({'Authorization': token});
  }
}

//

class TestDataGraphNotifier = GraphNotifier with TestMetaBox;

// ignore: must_be_immutable
class HouseLocalAdapter = $HouseHiveLocalAdapter
    with TestHiveLocalAdapter<House>;
class HouseRemoteAdapter = $HouseRemoteAdapter
    with TestRemoteAdapter, TokenAdapter;

// ignore: must_be_immutable
class FamilyLocalAdapter = $FamilyHiveLocalAdapter
    with TestHiveLocalAdapter<Family>;
class FamilyRemoteAdapter = $FamilyRemoteAdapter with TestRemoteAdapter;

// ignore: must_be_immutable
class PersonLocalAdapter = $PersonHiveLocalAdapter
    with TestHiveLocalAdapter<Person>;
class PersonRemoteAdapter = $PersonRemoteAdapter with TestRemoteAdapter;

// ignore: must_be_immutable
class DogLocalAdapter = $DogHiveLocalAdapter with TestHiveLocalAdapter<Dog>;
class DogRemoteAdapter = $DogRemoteAdapter with TestRemoteAdapter;

// ignore: must_be_immutable
class NodeLocalAdapter = $NodeHiveLocalAdapter with TestHiveLocalAdapter<Node>;

//

ProviderStateOwner owner;
GraphNotifier graph;

RemoteAdapter<House> houseRemoteAdapter;
RemoteAdapter<Family> familyRemoteAdapter;
RemoteAdapter<Person> personRemoteAdapter;

Repository<Family> familyRepository;
Repository<House> houseRepository;
Repository<Person> personRepository;
Repository<Dog> dogRepository;
Repository<Node> nodeRepository;

void setUpFn() async {
  owner = createOwner();
  graph = graphProvider.readOwner(owner);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  final adapterGraph = <String, RemoteAdapter<DataModel>>{
    'houses': houseRemoteAdapterProvider.readOwner(owner),
    'families': familyRemoteAdapterProvider.readOwner(owner),
    'people': personRemoteAdapterProvider.readOwner(owner),
    'dogs': dogRemoteAdapterProvider.readOwner(owner),
  };

  houseRemoteAdapter = houseRemoteAdapterProvider.readOwner(owner);
  familyRemoteAdapter = familyRemoteAdapterProvider.readOwner(owner);
  personRemoteAdapter = personRemoteAdapterProvider.readOwner(owner);

  houseRepository = await houseRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
        ref: owner.ref,
      );

  familyRepository = await familyRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
        ref: owner.ref,
      );

  personRepository = await personRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
        ref: owner.ref,
      );

  dogRepository = await dogRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
        ref: owner.ref,
      );

  nodeRepository = await nodeRepositoryProvider.readOwner(owner).initialize(
        remote: false,
        verbose: false,
        adapters: {
          'nodes': nodeRemoteAdapterProvider.readOwner(owner),
        },
        ref: owner.ref,
      );
}

Function dispose;

void tearDownFn() async {
  dispose?.call();
  await houseRepository?.dispose();
  await familyRepository?.dispose();
  await personRepository?.dispose();
  await dogRepository?.dispose();
  await nodeRepository?.dispose();
}

//

ProviderStateOwner createOwner() {
  return ProviderStateOwner(
    overrides: [
      hiveLocalStorageProvider
          .overrideAs(Provider((_) => TestHiveLocalStorage())),
      graphProvider.overrideAs(Provider(
          (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),
      //
      houseLocalAdapterProvider.overrideAs(Provider((ref) => HouseLocalAdapter(
          ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      familyLocalAdapterProvider.overrideAs(Provider((ref) =>
          FamilyLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      personLocalAdapterProvider.overrideAs(Provider((ref) =>
          PersonLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      dogLocalAdapterProvider.overrideAs(Provider((ref) => DogLocalAdapter(
          ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      nodeLocalAdapterProvider.overrideAs(Provider((ref) => NodeLocalAdapter(
          ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      //
      houseRemoteAdapterProvider.overrideAs(Provider(
          (ref) => HouseRemoteAdapter(ref.read(houseLocalAdapterProvider)))),
      familyRemoteAdapterProvider.overrideAs(Provider(
          (ref) => FamilyRemoteAdapter(ref.read(familyLocalAdapterProvider)))),
      personRemoteAdapterProvider.overrideAs(Provider(
          (ref) => PersonRemoteAdapter(ref.read(personLocalAdapterProvider)))),
      dogRemoteAdapterProvider.overrideAs(Provider(
          (ref) => DogRemoteAdapter(ref.read(dogLocalAdapterProvider)))),
      nodeRemoteAdapterProvider.overrideAs(Provider(
          (ref) => $NodeRemoteAdapter(ref.read(nodeLocalAdapterProvider)))),
    ],
  );
}

// utils

/// Waits 1 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
}

TypeMatcher<DataState<T>> withState<T extends DataModel<T>>(
        Object Function(DataState<T>) feature, matcher) =>
    isA<DataState<T>>().having(feature, null, matcher);
