import 'dart:async';
import 'package:flutter_data/flutter_data.dart';
import 'package:matcher/matcher.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart' hide Family;
import 'package:http/http.dart' as http;

import '../mocks.dart';
import 'book.dart';
import 'family.dart';
import 'house.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

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
Repository<Author> authorRepository;
Repository<Book> bookRepository;

Function dispose;

void setUpFn() async {
  container = createContainer();
  graph = container.read(graphProvider);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  // Equivalent to generated in `main.data.dart`

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

  authorRepository = await container.read(authorRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'authors': container.read(authorRemoteAdapterProvider),
      'books': container.read(bookRemoteAdapterProvider),
    },
  );

  bookRepository = await container.read(bookRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'authors': container.read(authorRemoteAdapterProvider),
      'books': container.read(bookRemoteAdapterProvider),
    },
  );
}

void tearDownFn() async {
  // Equivalent to generated in `main.data.dart`
  dispose?.call();
  houseRepository?.dispose();
  familyRepository?.dispose();
  personRepository?.dispose();
  dogRepository?.dispose();
  nodeRepository?.dispose();
}

//

class TestResponse {
  final String Function(http.Request) text;
  final int statusCode;

  const TestResponse({this.text, this.statusCode = 200});

  factory TestResponse.text(String text) {
    return TestResponse(text: (_) => text);
  }
}

final responseProvider = StateProvider<TestResponse>((_) => null);

ProviderContainer createContainer() {
  // when testing in Flutter use ProviderScope
  return ProviderContainer(
    overrides: [
      // app-specific
      mockResponseProvider.overrideWithProvider((ref, req) {
        final response = ref.read(responseProvider).state;
        final text = response.text(req);
        return http.Response(text, response.statusCode);
      }),

      // fd infra

      hiveLocalStorageProvider
          .overrideWithProvider(Provider((_) => TestHiveLocalStorage())),
      graphProvider.overrideWithProvider(Provider(
          (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),

      // model-specific

      houseLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => HouseLocalAdapter(ref))),
      familyLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => FamilyLocalAdapter(ref))),
      personLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => PersonLocalAdapter(ref))),
      dogLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => DogLocalAdapter(ref))),
      nodeLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => NodeLocalAdapter(ref))),
      authorLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => AuthorLocalAdapter(ref))),
      bookLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => BookLocalAdapter(ref))),

      //

      houseRemoteAdapterProvider.overrideWithProvider(Provider((ref) =>
          TokenHouseRemoteAdapter(ref.read(houseLocalAdapterProvider)))),
      familyRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => FamilyRemoteAdapter(ref.read(familyLocalAdapterProvider)))),
      personRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => PersonRemoteAdapter(ref.read(personLocalAdapterProvider)))),
      dogRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => DogRemoteAdapter(ref.read(dogLocalAdapterProvider)))),
      nodeRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => $NodeRemoteAdapter(ref.read(nodeLocalAdapterProvider)))),
      authorRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => $AuthorRemoteAdapter(ref.read(authorLocalAdapterProvider)))),
      bookRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => $BookRemoteAdapter(ref.read(bookLocalAdapterProvider)))),
    ],
  );
}

//

// ignore: must_be_immutable
class HouseLocalAdapter = $HouseHiveLocalAdapter
    with TestHiveLocalAdapter<House>;
class HouseRemoteAdapter = $HouseRemoteAdapter with TestRemoteAdapter;

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

// ignore: must_be_immutable
class AuthorLocalAdapter = $AuthorHiveLocalAdapter
    with TestHiveLocalAdapter<Author>;

// ignore: must_be_immutable
class BookLocalAdapter = $BookHiveLocalAdapter with TestHiveLocalAdapter<Book>;

// customizations

class MockFamilyRepository extends Mock implements Repository<Family> {}

class TokenHouseRemoteAdapter = $HouseRemoteAdapter with TestRemoteAdapter;

// utils

/// Waits 1 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
}

TypeMatcher<DataState<T>> withState<T extends DataModel<T>>(
        Object Function(DataState<T>) feature, matcher) =>
    isA<DataState<T>>().having(feature, null, matcher);
