import 'dart:async';
import 'dart:convert';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

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
late CoreNotifier core;
late LocalStorage storage;
Function? dispose;

final logging = [];

Future<void> setUpFn() async {
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
      localStorageProvider.overrideWith((ref) => InMemoryLocalStorage()),
    ],
  );

  // Equivalent to generated in `main.data.dart`
  storage = await container.read(localStorageProvider).initialize();

  DataHelpers.setInternalType<House>('houses');
  DataHelpers.setInternalType<Familia>('familia');
  DataHelpers.setInternalType<Person>('people');
  DataHelpers.setInternalType<Dog>('dogs');
  DataHelpers.setInternalType<BookAuthor>('bookAuthors');
  DataHelpers.setInternalType<Book>('books');
  DataHelpers.setInternalType<Library>('libraries');

  final adapterGraph = <String, Adapter<DataModelMixin>>{
    'houses': container.read(housesAdapterProvider),
    'familia': container.read(familiaAdapterProvider),
    'people': container.read(peopleAdapterProvider),
    'dogs': container.read(dogsAdapterProvider),
    'bookAuthors': container.read(bookAuthorsAdapterProvider),
    'books': container.read(booksAdapterProvider),
    'libraries': container.read(librariesAdapterProvider),
  };

  final ref = container.read(refProvider);

  internalAdapters['houses'] = await container
      .read(housesAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);
  internalAdapters['familia'] = await container
      .read(familiaAdapterProvider)
      .initialize(remote: true, adapters: adapterGraph, ref: ref);
  internalAdapters['people'] = await container
      .read(peopleAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);
  final dogsAdapter = internalAdapters['dogs'] = await container
      .read(dogsAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);
  internalAdapters['bookAuthors'] = await container
      .read(bookAuthorsAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);
  internalAdapters['books'] = await container
      .read(booksAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);
  internalAdapters['libraries'] = await container
      .read(librariesAdapterProvider)
      .initialize(remote: false, adapters: adapterGraph, ref: ref);

  const nodesKey = _kIsWeb ? 'node1s' : 'nodes';
  DataHelpers.setInternalType<Node>(nodesKey);
  internalAdapters[nodesKey] =
      await container.read(nodesAdapterProvider).initialize(
          remote: false,
          adapters: {
            nodesKey: container.read(nodesAdapterProvider),
          },
          ref: ref);

  core = container.read(housesAdapterProvider).core;

  dogsAdapter.logLevel = 2;
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
  core.dispose();
  await storage.destroy();

  logging.clear();
  await oneMs();
}

// utils

/// Waits 1 millisecond (tests have a throttle of Duration.zero)
Future<void> oneMs() async {
  await Future.delayed(const Duration(milliseconds: 1));
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
  final Adapter<Familia> adapter;
  Bloc(this.adapter);
}

final responseProvider =
    StateProvider<TestResponse>((_) => TestResponse.json(''));

final refProvider = Provider((ref) => ref);

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
  Adapter<House> get houses =>
      _watch(housesAdapterProvider)..internalWatch = _watch;
  Adapter<Familia> get familia =>
      _watch(familiaAdapterProvider)..internalWatch = _watch;
  Adapter<Person> get people =>
      _watch(peopleAdapterProvider)..internalWatch = _watch;
  Adapter<Dog> get dogs => _watch(dogsAdapterProvider)..internalWatch = _watch;

  Adapter<Node> get nodes =>
      _watch(nodesAdapterProvider)..internalWatch = _watch;
  Adapter<BookAuthor> get bookAuthors =>
      _watch(bookAuthorsAdapterProvider)..internalWatch = _watch;
  Adapter<Book> get books =>
      _watch(booksAdapterProvider)..internalWatch = _watch;
  Adapter<Library> get libraries =>
      _watch(librariesAdapterProvider)..internalWatch = _watch;
}

class Listener<T> extends Mock {
  void call(T value);
}
