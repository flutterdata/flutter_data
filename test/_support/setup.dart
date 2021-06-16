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

late ProviderContainer container;
late GraphNotifier graph;

late RemoteAdapter<House> houseRemoteAdapter;
late RemoteAdapter<Family> familyRemoteAdapter;
late RemoteAdapter<Person> personRemoteAdapter;

late Repository<Family> familyRepository;
late Repository<House> houseRepository;
late Repository<Person> personRepository;
late Repository<Dog> dogRepository;
late Repository<Node> nodeRepository;
late Repository<Author> authorRepository;
late Repository<Book> bookRepository;

Function? dispose;

void setUpFn() async {
  container = createContainer();
  graph = container.read(graphNotifierProvider);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  // Equivalent to generated in `main.data.dart`

  final adapterGraph = <String, RemoteAdapter<DataModel>>{
    'houses': container.read(housesRemoteAdapterProvider),
    'families': container.read(familiesRemoteAdapterProvider),
    'people': container.read(peopleRemoteAdapterProvider),
    'dogs': container.read(dogsRemoteAdapterProvider),
  };

  houseRemoteAdapter = container.read(housesRemoteAdapterProvider);
  familyRemoteAdapter = container.read(familiesRemoteAdapterProvider);
  personRemoteAdapter = container.read(peopleRemoteAdapterProvider);

  await container.read(graphNotifierProvider).initialize();

  houseRepository = await container.read(housesRepositoryProvider).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
      );

  familyRepository =
      await container.read(familiesRepositoryProvider).initialize(
            remote: false,
            verbose: false,
            adapters: adapterGraph,
          );

  personRepository = await container.read(peopleRepositoryProvider).initialize(
        remote: false,
        verbose: false,
        adapters: adapterGraph,
      );

  dogRepository = await container.read(dogsRepositoryProvider).initialize(
        remote: false,
        verbose: true,
        adapters: adapterGraph,
      );

  nodeRepository = await container.read(nodesRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'nodes': container.read(nodesRemoteAdapterProvider),
    },
  );

  authorRepository = await container.read(authorsRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'authors': container.read(authorsRemoteAdapterProvider),
      'books': container.read(booksRemoteAdapterProvider),
    },
  );

  bookRepository = await container.read(booksRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'authors': container.read(authorsRemoteAdapterProvider),
      'books': container.read(booksRemoteAdapterProvider),
    },
  );
}

void tearDownFn() async {
  // Equivalent to generated in `main.data.dart`
  dispose?.call();
  houseRepository.dispose();
  familyRepository.dispose();
  personRepository.dispose();
  dogRepository.dispose();
  nodeRepository.dispose();
  graph.dispose();
}

//

class TestResponse {
  final String Function(http.Request) text;
  final int statusCode;

  const TestResponse({required this.text, this.statusCode = 200});

  factory TestResponse.text(String text) {
    return TestResponse(text: (_) => text);
  }
}

final responseProvider =
    StateProvider<TestResponse>((_) => TestResponse.text(''));

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
      graphNotifierProvider.overrideWithProvider(Provider(
          (ref) => TestDataGraphNotifier(ref.read(hiveLocalStorageProvider)))),

      // model-specific

      housesLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => HouseLocalAdapter(ref))),
      familiesLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => FamilyLocalAdapter(ref))),
      peopleLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => PersonLocalAdapter(ref))),
      dogsLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => DogLocalAdapter(ref))),
      nodesLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => NodeLocalAdapter(ref))),
      authorsLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => AuthorLocalAdapter(ref))),
      booksLocalAdapterProvider
          .overrideWithProvider(Provider((ref) => BookLocalAdapter(ref))),

      //

      housesRemoteAdapterProvider.overrideWithProvider(Provider((ref) =>
          TokenHouseRemoteAdapter(ref.read(housesLocalAdapterProvider)))),
      familiesRemoteAdapterProvider.overrideWithProvider(Provider((ref) =>
          FamilyRemoteAdapter(ref.read(familiesLocalAdapterProvider)))),
      peopleRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => PersonRemoteAdapter(ref.read(peopleLocalAdapterProvider)))),
      dogsRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => DogRemoteAdapter(ref.read(dogsLocalAdapterProvider)))),
      nodesRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => $NodeRemoteAdapter(ref.read(nodesLocalAdapterProvider)))),
      authorsRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => AuthorRemoteAdapter(ref.read(authorsLocalAdapterProvider)))),
      booksRemoteAdapterProvider.overrideWithProvider(Provider(
          (ref) => $BookRemoteAdapter(ref.read(booksLocalAdapterProvider)))),
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
class AuthorRemoteAdapter = $AuthorRemoteAdapter with TestRemoteAdapter;

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
    isA<DataState<T>>().having(feature, '', matcher);
// TODO null => '' ???
