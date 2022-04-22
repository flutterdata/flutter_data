import 'dart:async';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../mocks.dart';
import 'book.dart';
import 'familia.dart';
import 'house.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

// copied from https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html
const _kIsWeb = identical(0, 0.0);

late ProviderContainer container;
late GraphNotifier graph;

late RemoteAdapter<House> houseRemoteAdapter;
late RemoteAdapter<Familia> familiaRemoteAdapter;
late RemoteAdapter<Person> personRemoteAdapter;

late Repository<Familia> familiaRepository;
late Repository<House> houseRepository;
late Repository<Person> personRepository;
late Repository<Dog> dogRepository;
late Repository<Node> nodeRepository;
late Repository<BookAuthor> bookAuthorRepository;
late Repository<Book> bookRepository;

Function? dispose;

final verbose = [];

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
    'familia': container.read(familiaRemoteAdapterProvider),
    'people': container.read(peopleRemoteAdapterProvider),
    'dogs': container.read(dogsRemoteAdapterProvider),
  };

  houseRemoteAdapter = container.read(housesRemoteAdapterProvider);
  familiaRemoteAdapter = container.read(familiaRemoteAdapterProvider);
  personRemoteAdapter = container.read(peopleRemoteAdapterProvider);

  await container.read(graphNotifierProvider).initialize();

  houseRepository = await container.read(housesRepositoryProvider).initialize(
        remote: false,
        adapters: adapterGraph,
      );

  familiaRepository =
      await container.read(familiaRepositoryProvider).initialize(
            remote: true,
            adapters: adapterGraph,
          );

  personRepository = await container.read(peopleRepositoryProvider).initialize(
        remote: false,
        adapters: adapterGraph,
      );

  dogRepository = await container.read(dogsRepositoryProvider).initialize(
        remote: false,
        adapters: adapterGraph,
      );
  dogRepository.remoteAdapter.verbose = true;

  const nodesKey = _kIsWeb ? 'node1s' : 'nodes';
  nodeRepository = await container.read(nodesRepositoryProvider).initialize(
    remote: false,
    adapters: {
      nodesKey: container.read(nodesRemoteAdapterProvider),
    },
  );

  bookAuthorRepository =
      await container.read(bookAuthorsRepositoryProvider).initialize(
    remote: false,
    adapters: {
      'bookAuthors': container.read(bookAuthorsRemoteAdapterProvider),
      'books': container.read(booksRemoteAdapterProvider),
    },
  );

  bookRepository = await container.read(booksRepositoryProvider).initialize(
    remote: false,
    adapters: {
      'bookAuthors': container.read(bookAuthorsRemoteAdapterProvider),
      'books': container.read(booksRemoteAdapterProvider),
    },
  );

  personRemoteAdapter.internalWatch = _watch;
}

void tearDownFn() async {
  // Equivalent to generated in `main.data.dart`
  dispose?.call();
  houseRepository.dispose();
  familiaRepository.dispose();
  personRepository.dispose();
  dogRepository.dispose();
  nodeRepository.dispose();
  graph.dispose();

  verbose.clear();
}

// utils

/// Waits 1 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
}

// home baked watcher
E _watch<E>(ProviderListenable<E> provider) {
  return container.readProviderElement(provider as ProviderBase<E>).readSelf();
}

Function() overridePrint(dynamic Function() testFn) => () {
      final spec = ZoneSpecification(print: (_, __, ___, String msg) {
        // Add to log instead of printing to stdout
        verbose.add(msg);
      });
      return Zone.current.fork(specification: spec).run(testFn);
    };

class Bloc {
  final Repository<Familia> repo;
  Bloc(this.repo);
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
