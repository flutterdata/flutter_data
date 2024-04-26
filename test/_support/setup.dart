import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_data/flutter_data.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matcher/expect.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';
import 'package:test/test.dart';

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
final disposeFns = <Function>[];

final logging = [];

Future<void> setUpFn() async {
  container = ProviderContainer(
    overrides: [
      httpClientFactoryProvider.overrideWith((ref) {
        return () => MockClient((req) async {
              final response = ref.watch(responseProvider);
              final text = await response.callback(req);
              if (text is String) {
                return http.Response(text, response.statusCode,
                    headers: response.headers);
              }
              return http.Response.bytes(text as Uint8List, response.statusCode,
                  headers: response.headers);
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

  final adapterProvidersMap = <String, Provider<Adapter<DataModelMixin>>>{
    'houses': housesAdapterProvider,
    'familia': familiaAdapterProvider,
    'people': peopleAdapterProvider,
    'dogs': dogsAdapterProvider,
    'bookAuthors': bookAuthorsAdapterProvider,
    'books': booksAdapterProvider,
    'libraries': librariesAdapterProvider,
    '${_kIsWeb ? 'node1s' : 'nodes'}': nodesAdapterProvider
  };

  await container.read(initializeFlutterData(adapterProvidersMap).future);

  container.read(dogsAdapterProvider).logLevel = 2;

  core = container.read(housesAdapterProvider).core;
}

Future<void> tearDownFn() async {
  for (final fn in disposeFns) {
    fn.call();
  }

  core.dispose();
  core.storage.dispose();
  await core.storage.destroy();

  logging.clear();
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

//

class DataStateNotifierTester<T> {
  final DataStateNotifier<T> notifier;

  var completer = Completer();
  var initial = true;

  DataStateNotifierTester(this.notifier, {bool fireImmediately = false}) {
    final dispose = notifier.addListener((_) {
      // print('received: $_');
      if (fireImmediately && initial) {
        Future.microtask(() {
          completer.complete(_);
          completer = Completer();
          initial = false;
        });
      } else {
        completer.complete(_);
        completer = Completer();
      }
    }, fireImmediately: fireImmediately);
    disposeFns.add(dispose);
  }

  Future<void> expectDataState(dynamic model,
      {dynamic isLoading, dynamic exception}) async {
    var m = isA<DataState<T>>();
    if (model != null) {
      if (model is List<(Function(T), dynamic)>) {
        for (final (fn, arg) in model) {
          m = m.having((s) => fn(s.model), 'model arg', arg);
        }
      } else {
        m = m.having((s) => s.model, 'model', model);
      }
    }
    if (isLoading != null) {
      m = m.having((s) => s.isLoading, 'isLoading', isLoading);
    }
    if (exception != null) {
      m = m.having((s) => s.exception, 'exception', exception);
    }
    return expectLater(completer.future, completion(m));
  }
}

extension SX<T> on DataStateNotifier<T> {
  DataStateNotifierTester tester({bool fireImmediately = false}) =>
      DataStateNotifierTester(this, fireImmediately: fireImmediately);
}
