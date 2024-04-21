import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      coreNotifierThrottleDurationProvider.overrideWithValue(Duration.zero),
      // NOTE: Can't enable in-memory sqlite as it can't be shared across isolates
      localStorageProvider.overrideWith(
        (ref) => LocalStorage(
            baseDirFn: () => Directory.systemTemp.createTempSync().path),
      ),
    ],
  );

  final adapterProviders = <String, Provider<Adapter<DataModelMixin>>>{
    'houses': housesAdapterProvider,
    'familia': familiaAdapterProvider,
    'people': peopleAdapterProvider,
    'dogs': dogsAdapterProvider,
    'bookAuthors': bookAuthorsAdapterProvider,
    'books': booksAdapterProvider,
    'libraries': librariesAdapterProvider,
    '${_kIsWeb ? 'node1s' : 'nodes'}': nodesAdapterProvider
  };

  await container.read(initializeWith(adapterProviders).future);

  container.read(dogsAdapterProvider).logLevel = 2;

  core = container.read(housesAdapterProvider).core;
}

Future<void> tearDownFn() async {
  dispose?.call();

  core.dispose();
  core.storage.dispose();
  await core.storage.destroy();

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
