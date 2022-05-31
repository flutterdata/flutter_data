import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';

import 'book.dart';
import 'familia.dart';
import 'fruit.dart';
import 'house.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

// copied from https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html
const _kIsWeb = identical(0, 0.0);

late ProviderContainer container;
late GraphNotifier graph;
Function? dispose;

final logging = [];

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
      isarLocalStorageProvider.overrideWithValue(
        IsarLocalStorage(
          baseDirFn: () => Directory.systemTemp.createTempSync().path,
          clear: true,
        ),
      ),
    ],
  );

  await Isar.initializeIsarCore(
    libraries: {
      if (Platform.isMacOS)
        Abi.macosX64:
            File('test/_support/resources/isar/libisar.dylib').absolute.path,
      if (Platform.isMacOS)
        Abi.macosArm64:
            File('test/_support/resources/isar/libisar.dylib').absolute.path,
    },
  );

  graph = container.read(graphNotifierProvider);

  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  // Equivalent to generated in `main.data.dart`

  final adapterGraph = <String, RemoteAdapter<DataModel>>{
    'houses': container.read(internalHousesRemoteAdapterProvider),
    'familia': container.read(internalFamiliaRemoteAdapterProvider),
    'people': container.read(internalPeopleRemoteAdapterProvider),
    'dogs': container.read(internalDogsRemoteAdapterProvider),
    'bookAuthors': container.read(internalBookAuthorsRemoteAdapterProvider),
    'books': container.read(internalBooksRemoteAdapterProvider),
  };

  await container.read(isarLocalStorageProvider).initialize([
    ...adapterGraph.values,
    container.read(internalNodesRemoteAdapterProvider),
    container.read(internalFruitsRemoteAdapterProvider),
  ]);

  internalRepositories['houses'] = await container
      .read(housesRepositoryProvider)
      .initialize(remote: false, adapters: adapterGraph);
  internalRepositories['familia'] = await container
      .read(familiaRepositoryProvider)
      .initialize(remote: true, adapters: adapterGraph);
  internalRepositories['people'] = await container
      .read(peopleRepositoryProvider)
      .initialize(remote: false, adapters: adapterGraph);
  final dogsRepository = internalRepositories['dogs'] = await container
      .read(dogsRepositoryProvider)
      .initialize(remote: false, adapters: adapterGraph);
  internalRepositories['bookAuthors'] =
      await container.read(bookAuthorsRepositoryProvider).initialize(
            remote: false,
            adapters: adapterGraph,
          );
  internalRepositories['books'] =
      await container.read(booksRepositoryProvider).initialize(
            remote: false,
            adapters: adapterGraph,
          );

  const nodesKey = _kIsWeb ? 'node1s' : 'nodes';
  internalRepositories[nodesKey] =
      await container.read(nodesRepositoryProvider).initialize(
    remote: false,
    adapters: {
      nodesKey: container.read(internalNodesRemoteAdapterProvider),
    },
  );

  dogsRepository.logLevel = 2;

  internalRepositories['fruits'] =
      await container.read(fruitsRepositoryProvider).initialize(
    remote: false,
    adapters: {
      'fruits': container.read(internalFruitsRemoteAdapterProvider),
    },
  );
}

void tearDownFn() async {
  // Equivalent to generated in `main.data.dart`
  dispose?.call();
  container.houses.dispose();
  container.familia.dispose();
  container.people.dispose();
  container.dogs.dispose();

  container.nodes.dispose();
  container.books.dispose();
  container.bookAuthors.dispose();
  graph.dispose();

  logging.clear();
  await oneMs();

  final path = container.read(isarLocalStorageProvider).path;
  Directory(path).deleteSync(recursive: true);
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
        logging.add(msg);
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

extension ProviderContainerX on ProviderContainer {
  Repository<House> get houses =>
      _watch(housesRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<Familia> get familia =>
      _watch(familiaRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<Person> get people =>
      _watch(peopleRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<Dog> get dogs =>
      _watch(dogsRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<BookAuthor> get bookAuthors =>
      _watch(bookAuthorsRepositoryProvider)
        ..remoteAdapter.internalWatch = _watch;
  Repository<Book> get books =>
      _watch(booksRepositoryProvider)..remoteAdapter.internalWatch = _watch;

  Repository<Node> get nodes =>
      _watch(nodesRepositoryProvider)..remoteAdapter.internalWatch = _watch;

  Repository<Fruit> get fruits =>
      _watch(fruitsRepositoryProvider)..remoteAdapter.internalWatch = _watch;
}
