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
    final token = await ref.watch(tokenFutureProvider.future);
    return await super.defaultHeaders
      ..addAll({'Authorization': token});
  }

  @override
  FutureOr<Map<String, dynamic>> get defaultParams async {
    final token = await ref.read(tokenFutureProvider.future);
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

ProviderContainer container;
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
  container = createContainer();
  graph = container.read(graphProvider);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  final adapterGraph = <String, RemoteAdapter<DataModel>>{
    'houses': container.read(houseRemoteAdapterProvider),
    'families': container.read(familyRemoteAdapterProvider),
    'people': container.read(personRemoteAdapterProvider),
    'dogs': container.read(dogRemoteAdapterProvider),
  };

  houseRemoteAdapter = container.read(houseRemoteAdapterProvider);
  familyRemoteAdapter = container.read(familyRemoteAdapterProvider);
  personRemoteAdapter = container.read(personRemoteAdapterProvider);

  houseRepository = await container.read(houseRepositoryProvider).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
      );

  familyRepository = await container.read(familyRepositoryProvider).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
      );

  personRepository = await container.read(personRepositoryProvider).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
      );

  dogRepository = await container.read(dogRepositoryProvider).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
      );

  nodeRepository = await container.read(nodeRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'nodes': container.read(nodeRemoteAdapterProvider),
    },
  );
}

Function dispose;

void tearDownFn() async {
  dispose?.call();
  houseRepository?.dispose();
  familyRepository?.dispose();
  personRepository?.dispose();
  dogRepository?.dispose();
  nodeRepository?.dispose();
}

//

ProviderContainer createContainer() {
  return ProviderContainer(
    overrides: [
      hiveLocalStorageProvider
          .overrideWithProvider(Provider((_) => TestHiveLocalStorage())),
      graphProvider.overrideWithProvider(Provider(
          (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),
      //
      houseLocalAdapterProvider.overrideWithProvider(Provider((ref) =>
          HouseLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      familyLocalAdapterProvider.overrideWithProvider(Provider((ref) =>
          FamilyLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      personLocalAdapterProvider.overrideWithProvider(Provider((ref) =>
          PersonLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      dogLocalAdapterProvider.overrideWithProvider(Provider((ref) =>
          DogLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      nodeLocalAdapterProvider.overrideWithProvider(Provider((ref) =>
          NodeLocalAdapter(
              ref.read(hiveLocalStorageProvider), ref.read(graphProvider)))),
      //
      houseRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => HouseRemoteAdapter(ref.read(houseLocalAdapterProvider)))),
      familyRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => FamilyRemoteAdapter(ref.read(familyLocalAdapterProvider)))),
      personRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => PersonRemoteAdapter(ref.read(personLocalAdapterProvider)))),
      dogRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => DogRemoteAdapter(ref.read(dogLocalAdapterProvider)))),
      nodeRemoteAdapterProvider.overrideWithProvider(Provider(
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
