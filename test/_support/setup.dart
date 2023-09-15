import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;

import 'book.dart';
import 'familia.dart';
import 'house.dart';
import 'node.dart';
import 'person.dart';
import 'pet.dart';

// copied from https://api.flutter.dev/flutter/foundation/kIsWeb-constant.html
const _kIsWeb = identical(0, 0.0);
const kTestsPath = '/tmp';

// keyFor alias
final keyFor = DataModel.keyFor;

late ProviderContainer container;
late GraphNotifier graph;
Function? dispose;

final logging = [];

Future<void> setUpFn() async {
  await setUpIsar();
  container = ProviderContainer(
    overrides: [
      httpClientProvider.overrideWith((ref) {
        return MockClient((req) async {
          // try {
          final response = ref.watch(responseProvider);
          final text = await response.callback(req);
          if (text is String) {
            return http.Response(text, response.statusCode,
                headers: response.headers);
          } else if (text is List<int>) {
            return http.Response.bytes(text, response.statusCode,
                headers: response.headers);
          } else {
            throw UnsupportedError('text is not of right type');
          }
        });
      }),
      hiveLocalStorageProvider.overrideWith(
        (ref) => HiveLocalStorage(
          baseDirFn: () => kTestsPath,
          clear: LocalStorageClearStrategy.always,
        ),
      ),
    ],
  );

  graph = container.read(graphNotifierProvider);
  // IMPORTANT: disable namespace assertions
  // in order to test un-namespaced (key, id)
  graph.debugAssert(false);

  // Equivalent to generated in `main.data.dart`

  await container.read(graphNotifierProvider).initialize();

  DataHelpers.setInternalType<House>('houses');
  DataHelpers.setInternalType<Familia>('familia');
  DataHelpers.setInternalType<Person>('people');
  DataHelpers.setInternalType<Dog>('dogs');
  DataHelpers.setInternalType<BookAuthor>('bookAuthors');
  DataHelpers.setInternalType<Book>('books');
  DataHelpers.setInternalType<Library>('libraries');

  final adapterGraph = <String, RemoteAdapter<DataModelMixin>>{
    'houses': container.read(internalHousesRemoteAdapterProvider),
    'familia': container.read(internalFamiliaRemoteAdapterProvider),
    'people': container.read(internalPeopleRemoteAdapterProvider),
    'dogs': container.read(internalDogsRemoteAdapterProvider),
    'bookAuthors': container.read(internalBookAuthorsRemoteAdapterProvider),
    'books': container.read(internalBooksRemoteAdapterProvider),
    'libraries': container.read(internalLibrariesRemoteAdapterProvider),
  };

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
  internalRepositories['libraries'] =
      await container.read(librariesRepositoryProvider).initialize(
            remote: false,
            adapters: adapterGraph,
          );

  const nodesKey = _kIsWeb ? 'node1s' : 'nodes';
  DataHelpers.setInternalType<Node>(nodesKey);
  internalRepositories[nodesKey] =
      await container.read(nodesRepositoryProvider).initialize(
    remote: false,
    adapters: {
      nodesKey: container.read(internalNodesRemoteAdapterProvider),
    },
  );

  dogsRepository.logLevel = 2;
}

Future<void> setUpIsar() async {
  // create flutter_data dir for Isar files
  final dir = Directory(path.join(kTestsPath, 'flutter_data'));
  dir.createSync();

  // initialize Isar Core
  final binaryName = Platform.isWindows
      ? 'isar.dll'
      : Platform.isMacOS
          ? 'libisar.dylib'
          : 'libisar.so';

  final p = File('tmp/$binaryName').absolute.path;
  await Isar.initialize(p);
}

Future<void> tearDownIsar() async {
  final dir = Directory(path.join(kTestsPath, 'flutter_data'));
  dir.deleteSync(recursive: true);
}

Future<void> tearDownFn() async {
  // Equivalent to generated in `main.data.dart`
  dispose?.call();
  container.houses.dispose();
  container.familia.dispose();
  container.people.dispose();
  container.dogs.dispose();

  container.nodes.dispose();
  container.books.dispose();
  container.bookAuthors.dispose();
  container.libraries.dispose();
  graph.dispose();

  logging.clear();
  await oneMs();

  await tearDownIsar();
}

// utils

/// Waits 10 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 10));
}

// home baked watcher
E _watch<E>(ProviderListenable<E> provider) {
  if (provider is ProviderBase<E>) {
    return container.readProviderElement(provider).readSelf();
  }
  return container.listen<E>(provider, ((_, next) => next)).read();
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
    StateProvider<TestResponse>((_) => TestResponse.json(''));

class TestResponse {
  final Future<Object> Function(http.Request) callback;
  final int statusCode;
  final Map<String, String> headers;

  const TestResponse(
    this.callback, {
    this.statusCode = 200,
    this.headers = const {},
  });

  factory TestResponse.json(String text) =>
      TestResponse((_) async => utf8.encode(text));
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

  Repository<Node> get nodes =>
      _watch(nodesRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<BookAuthor> get bookAuthors =>
      _watch(bookAuthorsRepositoryProvider)
        ..remoteAdapter.internalWatch = _watch;
  Repository<Book> get books =>
      _watch(booksRepositoryProvider)..remoteAdapter.internalWatch = _watch;
  Repository<Library> get libraries =>
      _watch(librariesRepositoryProvider)..remoteAdapter.internalWatch = _watch;
}
