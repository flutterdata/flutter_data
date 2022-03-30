import 'dart:async';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../mocks.dart';
import 'book.dart';
import 'family.dart';
import 'house.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

// copied from https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html
const _kIsWeb = identical(0, 0.0);

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
late Repository<BookAuthor> bookAuthorRepository;
late Repository<Book> bookRepository;

Function? dispose;

void setUpFn() async {
  container = ProviderContainer(
    overrides: [
      httpClientProvider.overrideWithProvider(Provider((ref) {
        return MockClient((req) async {
          try {
            final response = ref.watch(responseProvider);
            final text = response.text(req);
            return http.Response(text, response.statusCode,
                headers: response.headers);
          } on ProviderException catch (e) {
            // unwrap provider exception
            // ignore: only_throw_errors
            throw e.exception;
          }
        });
      })),
      hiveProvider.overrideWithValue(HiveFake()),
    ],
  );

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
            remote: true,
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

  const nodesKey = _kIsWeb ? 'node1s' : 'nodes';
  nodeRepository = await container.read(nodesRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      nodesKey: container.read(nodesRemoteAdapterProvider),
    },
  );

  bookAuthorRepository =
      await container.read(bookAuthorsRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'bookAuthors': container.read(bookAuthorsRemoteAdapterProvider),
      'books': container.read(booksRemoteAdapterProvider),
    },
  );

  bookRepository = await container.read(booksRepositoryProvider).initialize(
    remote: false,
    verbose: false,
    adapters: {
      'bookAuthors': container.read(bookAuthorsRemoteAdapterProvider),
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

// utils

/// Waits 1 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
}

final responseProvider =
    StateProvider<TestResponse>((_) => TestResponse.text(''));

class TestResponse {
  final String Function(http.Request) text;
  final int statusCode;
  final Map<String, String> headers;

  const TestResponse({
    required this.text,
    this.statusCode = 200,
    this.headers = const {},
  });

  factory TestResponse.text(String text) {
    return TestResponse(text: (_) => text);
  }
}
