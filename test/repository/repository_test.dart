import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/familia.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('initialization', () {
    expect(familiaRepository.isInitialized, isTrue);
  });

  test('findAll & clear', () async {
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final familia = await familiaRepository.findAll();

    expect(familia, [familia1, familia2]);

    await familiaRepository.clear();
    expect(await familiaRepository.findAll(remote: false), isEmpty);
  });

  test('findAll with and without syncLocal', () async {
    final familia1 = Familia(id: '1', surname: 'Smith');
    final familia2 = Familia(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final familia1all = await familiaRepository.findAll();

    expect(familia1all, [familia1, familia2]);

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }]
      ''');
    final familia2all = await familiaRepository.findAll(syncLocal: false);

    expect(familia2all, [familia1]);

    // since `syncLocal: false` and `familia2` was present from an older call, it remains in local storage
    expect(
        await familiaRepository.findAll(remote: false), [familia1, familia2]);

    final familia3 = await familiaRepository.findAll(syncLocal: true);

    expect(familia3, [familia1]);

    // using `syncLocal: true` the result is equal to the contents of local storage
    expect(await familiaRepository.findAll(remote: false), familia3);
  });

  test('findAll with error', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await familiaRepository.findAll();
    }, throwsA(isA<DataException>()));

    await familiaRepository.findAll(
      // ignore: missing_return
      onError: (e) {
        expect(e, isA<DataException>());
        return null;
      },
    );
  });

  test('findOne', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith" }
      ''');
    final familia = await familiaRepository.findOne('1');
    expect(familia, Familia(id: '1', surname: 'Smith'));

    // and it can be found again locally
    expect(familia, await familiaRepository.findOne('1', remote: false));
  });

  test('findOne with empty (non-null) ID works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "", "surname": "Smith" }
      ''');
    final familia = await familiaRepository.findOne('');
    expect(familia, isNotNull);

    // and it can be found again locally
    expect(familia, await familiaRepository.findOne('', remote: false));
  });

  test('findOne with changing IDs works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "new", "surname": "Smith" }
      ''');
    final familia = await familiaRepository.findOne('');
    expect(familia, isNotNull);

    // and it can be found again locally with its new ID
    expect(familia, await familiaRepository.findOne('new', remote: false));
  });

  test('findOne with empty response', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('');
    final familia = await familiaRepository.findOne('1');
    expect(familia, isNull);
  });

  test('findOne with includes', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
      ''');
    final familia =
        await familiaRepository.findOne('1', params: {'include': 'people'});
    expect(familia, Familia(id: '1', surname: 'Smith'));

    // can be found again locally
    expect(familia, await familiaRepository.findOne('1', remote: false));

    // as well as the included Person
    expect(await personRepository.findOne('1', remote: false),
        Person(id: '1', name: 'Stan', age: 31));
  });

  test('findOne with errors', () async {
    final error203 = isA<DataException>()
        .having((e) => e.error, 'error', isA<FormatException>())
        .having((e) => e.statusCode, 'status code', 203);

    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await familiaRepository.findOne('1');
    }, throwsA(error203));

    await oneMs();

    // ignore: missing_return
    await familiaRepository.findOne('1', onError: (e) {
      expect(e, error203);
      return null;
    });
  });

  test('not found does not throw by default', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '{ "error": "not found" }', statusCode: 404);
      await familiaRepository.findOne('2');
    }, returnsNormally);

    // no record locally
    expect(await familiaRepository.findOne('1', remote: false), isNull);

    // now throws with overriden onError

    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '{ "error": "not found" }', statusCode: 404);
      await familiaRepository.findOne('2', onError: (e) => throw e);
    },
        throwsA(isA<DataException>().having(
          (e) => e.error,
          'error',
          {'error': 'not found'},
        ).having((e) => e.statusCode, 'status code', 404)));

    // no record locally
    expect(await familiaRepository.findOne('1', remote: false), isNull);
  });

  test('socket exception does not throw by default', () async {
    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));
    await familiaRepository.findOne('error', onError: (e) {
      expect(e, isA<OfflineException>());
      return null;
    });
  });

  test('save', () async {
    // familia with id=1 does not exist
    expect(await familiaRepository.findOne('1', remote: false), isNull);

    // with empty response
    final familia = Familia(id: '1', surname: 'Smith');
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await familiaRepository.save(familia);
    // and it can be found again locally
    expect(familia, await familiaRepository.findOne('1', remote: false));

    // with non-empty response
    container.read(responseProvider.notifier).state =
        TestResponse.text('{"id": "2", "surname": "Jones Saved"}');
    await familiaRepository.save(Familia(id: '2', surname: 'Jones'));
    // and it can be found again locally
    final familia2 = await familiaRepository.findOne('2', remote: false);
    expect(familia2!.surname, 'Jones Saved');
  });

  test('save with error', () async {
    final familia = Familia(id: '1', surname: 'Smith');
    container.read(responseProvider.notifier).state =
        TestResponse.text('@**&#*#&');

    // overrides error handling with notifier
    final listener = Listener<DataState<List<Familia>>?>();
    final notifier =
        familiaRepository.remoteAdapter.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: false))).called(1);

    // ignore: missing_return
    await familiaRepository.save(familia, onError: (e) async {
      await oneMs();
      notifier.updateWith(exception: e);
      return null;
    });
    await oneMs();

    verify(listener(DataState([familia], isLoading: false))).called(1);

    verify(listener(argThat(
      isA<DataState>().having((s) {
        return s.exception!.error;
      }, 'exception', isA<FormatException>()),
    ))).called(1);
  });

  test('delete', () async {
    // init a person
    final person = Person(id: '1', name: 'John', age: 21).init(container.read);
    // it does have a key
    expect(keyFor(person), isNotNull);

    // now delete
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await personRepository.delete(person.id!, remote: true);

    // so fetching by id again is null
    expect(await personRepository.findOne(person.id!), isNull);
  });

  test('watchAllNotifier', () async {
    final listener = Listener<DataState<List<Familia>>>();

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');
    final notifier = familiaRepository.remoteAdapter.watchAllNotifier();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    verify(listener(DataState([
      Familia(id: '1', surname: 'Corleone'),
      Familia(id: '2', surname: 'Soprano')
    ], isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAllNotifier with error', () async {
    final listener = Listener<DataState<List<Familia>>?>();

    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw Exception('unreachable'));
    final notifier = familiaRepository.remoteAdapter.watchAllNotifier();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    // finished loading but found the network unreachable
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);
    verifyNoMoreInteractions(listener);

    // now server will successfully respond with two familia
    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');

    // reload
    await notifier.reload();

    final familia = Familia(id: '1', surname: 'Corleone');
    final familia2 = Familia(id: '2', surname: 'Soprano');

    // loads again, for now exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);

    await oneMs();

    // now responds with models, loading done, and no exception
    verify(listener(DataState([familia, familia2], isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier', () async {
    final listener = Listener<DataState<Person?>?>();

    container.read(responseProvider.notifier).state = TestResponse.text(
      '''{ "_id": "1", "name": "Charlie", "age": 23 }''',
    );
    final notifier =
        personRepository.remoteAdapter.watchOneNotifier('1', remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(DataState(Person(id: '1', name: 'Charlie', age: 23),
            isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);

    await personRepository.save(Person(id: '1', name: 'Charlie', age: 24));
    await oneMs();

    verify(listener(DataState(Person(id: '1', name: 'Charlie', age: 24),
            isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier with error', () async {
    final listener = Listener<DataState<Familia?>?>();

    container.read(responseProvider.notifier).state = TestResponse(
      text: (_) => throw Exception('whatever'),
    );
    final notifier = familiaRepository.remoteAdapter.watchOneNotifier('1');

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState<Familia?>(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(argThat(isA<DataState>().having(
            (s) => s.exception!.error.toString(),
            'exception',
            'Exception: whatever'))))
        .called(1);
    verifyNoMoreInteractions(listener);

    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw Exception('unreachable'));

    await notifier.reload();
    await oneMs();

    // loads again, for now original exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception!.error.toString(), 'exception',
                startsWith('Exception:')))))
        .called(1);

    await oneMs();
    // finished loading but found the network unreachable
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);
    verifyNoMoreInteractions(listener);

    // now server will successfully respond with a familia
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Corleone" }
      ''');

    // reload
    await notifier.reload();
    await oneMs();

    final familia = Familia(id: '1', surname: 'Corleone');

    // loads again, for now exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);

    await oneMs();

    // now responds with model, loading done, and no exception
    verify(listener(DataState(familia, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier with alsoWatch relationships', () async {
    // simulate Familia that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    final familia = Familia(id: '22', surname: 'Paez', persons: HasMany());
    graph.getKeyForId('familia', '22', keyIfAbsent: 'familia#a1a1a1');
    await (familiaRepository.remoteAdapter.localAdapter as HiveLocalAdapter)
        .box!
        .put('familia#a1a1a1', familia);

    final listener = Listener<DataState<Familia?>?>();

    container.read(responseProvider.notifier).state =
        TestResponse.text('''{ "id": "22", "surname": "Paez" }''');
    final notifier = familiaRepository.remoteAdapter.watchOneNotifier(
      '22',
      alsoWatch: (f) => [f.persons],
    );

    dispose = notifier.addListener(listener, fireImmediately: true);

    // verify loading
    verify(listener(DataState(familia, isLoading: true))).called(1);
    verifyNoMoreInteractions(listener);

    final f1 = await familiaRepository.findOne('22', remote: false);
    f1!.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(isA<DataState>()
            .having((s) => s.model.persons!, 'rel', hasLength(1))
            .having((s) => s.isLoading, 'loading', false))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAllNotifier updates isLoading even in an empty response',
      () async {
    final listener = Listener<DataState<List<Familia>>?>();

    container.read(responseProvider.notifier).state = TestResponse.text('[]');
    final notifier = familiaRepository.remoteAdapter.watchAllNotifier();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(argThat(
      isA<DataState>().having((s) => s.isLoading, 'loading', true),
    ))).called(1);

    await oneMs();

    verify(listener(argThat(
      isA<DataState>()
          .having((s) => s.model, 'empty', isEmpty)
          .having((s) => s.isLoading, 'loading', false),
    ))).called(1);

    // get a new notifier and try again

    final notifier2 = familiaRepository.remoteAdapter.watchAllNotifier();
    final listener2 = Listener<DataState<List<Familia>>?>();

    dispose?.call();

    dispose = notifier2.addListener(listener2, fireImmediately: true);

    verify(listener2(argThat(
      isA<DataState>().having((s) => s.isLoading, 'loading', true),
    ))).called(1);

    await oneMs();

    verify(listener2(argThat(
      isA<DataState>()
          .having((s) => s.model, 'empty', isEmpty)
          .having((s) => s.isLoading, 'loading', false),
    ))).called(1);
  });

  test('watchAllNotifier syncLocal', () async {
    final listener = Listener<DataState<List<Familia>>>();

    container.read(responseProvider.notifier).state = TestResponse.text(
        '''[{ "id": "22", "surname": "Paez" }, { "id": "12", "surname": "Brunez" }]''');
    final notifier =
        familiaRepository.remoteAdapter.watchAllNotifier(syncLocal: true);

    dispose = notifier.addListener(listener, fireImmediately: true);
    await oneMs();

    verify(listener(DataState([
      Familia(id: '22', surname: 'Paez'),
      Familia(id: '12', surname: 'Brunez'),
    ], isLoading: false)))
        .called(1);

    container.read(responseProvider.notifier).state =
        TestResponse.text('''[{ "id": "22", "surname": "Paez" }]''');
    await notifier.reload();
    await oneMs();

    verify(listener(DataState([
      Familia(id: '22', surname: 'Paez'),
      Familia(id: '12', surname: 'Brunez'),
    ], isLoading: true)))
        .called(1);

    verify(listener(DataState([
      Familia(id: '22', surname: 'Paez'),
    ], isLoading: false)))
        .called(1);
  });

  test('remote can return a different ID', () async {
    Familia(id: '1', surname: 'Corleone').init(container.read);
    Familia(id: '2', surname: 'Moletto').init(container.read);

    // returns 2, not the requested 1
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{"id": "2", "surname": "Oslo"}''');
    await familiaRepository.findOne('1');
    // (no model will show up in a watchOneNotifier('1') situation)

    // 1 was requested, but finally 2 was updated
    expect(await familiaRepository.findOne('2', remote: false),
        Familia(id: '2', surname: 'Oslo'));
  });

  test('reconcile keys under same ID', () async {
    // id=1 exists locally, has a key
    final familia1 = Familia(id: '1', surname: 'Corleone').init(container.read);

    // an id-less Familia is created (obviously with new key)
    final familia2 = Familia(surname: 'Moletto').init(container.read);

    // therefore these objects have different keys
    expect(keyFor(familia2), isNotNull);
    expect(keyFor(familia1), isNot(keyFor(familia2)));

    // it's saved to the server
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{"id": "1", "surname": "Oslo"}''');
    await familiaRepository.save(familia2);

    // keys are reconciled and now both keys are equal
    expect(keyFor(familia1), keyFor(familia2));
  });

  test('custom login adapter with repo extension', () async {
    // this crappy login uses password as token
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{ "token": "zzz1" }''');

    final token = await personRepository.personLoginAdapter
        .login('email@email.com', 'zzz1');
    expect(token, 'zzz1');
  });

  test('custom login adapter with custom onError', () async {
    // sending a null email will trigger an error
    // and custom onError will throw an UnsupportedError
    // (instead of the standard DataException)
    expect(() async {
      container.read(responseProvider.notifier).state =
          TestResponse.text('''&*@%%*#@!''');
      await personRepository.personLoginAdapter.login(null, null);
    }, throwsA(isA<UnsupportedError>()));

    await personRepository.genericDoesNothingAdapter.doNothing(null, 1);
  });

  test('verbose', overridePrint(() async {
    Dog(id: '3', name: 'Bowie').init(container.read);
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await dogRepository.delete('3', params: {'a': 1}, remote: true);
    expect(verbose, [
      '[flutter_data] [dogs] DELETE https://override-base-url-in-adapter/dogs/3?a=1 [HTTP 200]'
    ]);

    try {
      container.read(responseProvider.notifier).state =
          TestResponse(text: (_) => '^@!@#(#(@#)#@', statusCode: 500);
      await dogRepository.findOne('1', remote: true);
    } catch (_) {
      expect(verbose.last, contains('DataException'));
    }
  }));

  test('find one with utf8 characters', () async {
    container.read(responseProvider.notifier).state = TestResponse(
      text: (req) => '{ "id": "1", "surname": "عمر" }',
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
    final familia = await familiaRepository.findOne(1);

    expect(familia, Familia(id: '1', surname: 'عمر'));
  });

  test('dispose', () {
    familiaRepository.dispose();
    expect(familiaRepository.isInitialized, isFalse);
  });
}

final verbose = [];

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
