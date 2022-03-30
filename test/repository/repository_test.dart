import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('initialization', () {
    expect(familyRepository.isInitialized, isTrue);
  });

  test('findAll & clear', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final families = await familyRepository.findAll();

    expect(families, [family1, family2]);

    await familyRepository.clear();
    expect(await familyRepository.findAll(remote: false), isEmpty);
  });

  test('findAll with and without syncLocal', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final families1 = await familyRepository.findAll();

    expect(families1, [family1, family2]);

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }]
      ''');
    final families2 = await familyRepository.findAll(syncLocal: false);

    expect(families2, [family1]);

    // since `syncLocal: false` and `family2` was present from an older call, it remains in local storage
    expect(await familyRepository.findAll(remote: false), [family1, family2]);

    final families3 = await familyRepository.findAll(syncLocal: true);

    expect(families3, [family1]);

    // using `syncLocal: true` the result is equal to the contents of local storage
    expect(await familyRepository.findAll(remote: false), families3);
  });

  test('findAll with error', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await familyRepository.findAll();
    }, throwsA(isA<DataException>()));

    await familyRepository.findAll(
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
    final family = await familyRepository.findOne('1');
    expect(family, Family(id: '1', surname: 'Smith'));

    // and it can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));
  });

  test('findOne with empty (non-null) ID works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "", "surname": "Smith" }
      ''');
    final family = await familyRepository.findOne('');
    expect(family, isNotNull);

    // and it can be found again locally
    expect(family, await familyRepository.findOne('', remote: false));
  });

  test('findOne with changing IDs works', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "new", "surname": "Smith" }
      ''');
    final family = await familyRepository.findOne('');
    expect(family, isNotNull);

    // and it can be found again locally with its new ID
    expect(family, await familyRepository.findOne('new', remote: false));
  });

  test('findOne with empty response', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('');
    final family = await familyRepository.findOne('1');
    expect(family, isNull);
  });

  test('findOne with includes', () async {
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
      ''');
    final family =
        await familyRepository.findOne('1', params: {'include': 'people'});
    expect(family, Family(id: '1', surname: 'Smith'));

    // can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));

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
      await familyRepository.findOne('1');
    }, throwsA(error203));

    await oneMs();

    // ignore: missing_return
    await familyRepository.findOne('1', onError: (e) {
      expect(e, error203);
      return null;
    });
  });

  test('not found does not throw by default', () async {
    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '{ "error": "not found" }', statusCode: 404);
      await familyRepository.findOne('2');
    }, returnsNormally);

    // no record locally
    expect(await familyRepository.findOne('1', remote: false), isNull);

    // now throws with overriden onError

    expect(() async {
      container.read(responseProvider.notifier).state = TestResponse(
          text: (_) => '{ "error": "not found" }', statusCode: 404);
      await familyRepository.findOne('2', onError: (e) => throw e);
    },
        throwsA(isA<DataException>().having(
          (e) => e.error,
          'error',
          {'error': 'not found'},
        ).having((e) => e.statusCode, 'status code', 404)));

    // no record locally
    expect(await familyRepository.findOne('1', remote: false), isNull);
  });

  test('socket exception does not throw by default', () async {
    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw SocketException('unreachable'));
    await familyRepository.findOne('error', onError: (e) {
      expect(e, isA<OfflineException>());
      return null;
    });
  });

  test('save', () async {
    // family with id=1 does not exist
    expect(await familyRepository.findOne('1', remote: false), isNull);

    // with empty response
    final family = Family(id: '1', surname: 'Smith');
    container.read(responseProvider.notifier).state = TestResponse.text('');
    await familyRepository.save(family);
    // and it can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));

    // with non-empty response
    container.read(responseProvider.notifier).state =
        TestResponse.text('{"id": "2", "surname": "Jones Saved"}');
    await familyRepository.save(Family(id: '2', surname: 'Jones'));
    // and it can be found again locally
    final family2 = await familyRepository.findOne('2', remote: false);
    expect(family2!.surname, 'Jones Saved');
  });

  test('save with error', () async {
    final family = Family(id: '1', surname: 'Smith');
    container.read(responseProvider.notifier).state =
        TestResponse.text('@**&#*#&');

    // overrides error handling with notifier
    final listener = Listener<DataState<List<Family>>?>();
    final notifier =
        familyRepository.remoteAdapter.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: false))).called(1);

    // ignore: missing_return
    await familyRepository.save(family, onError: (e) async {
      await oneMs();
      notifier.updateWith(exception: e);
      return null;
    });
    await oneMs();

    verify(listener(DataState([family], isLoading: false))).called(1);

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
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');
    final notifier = familyRepository.remoteAdapter.watchAllNotifier();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    verify(listener(DataState([
      Family(id: '1', surname: 'Corleone'),
      Family(id: '2', surname: 'Soprano')
    ], isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAllNotifier with error', () async {
    final listener = Listener<DataState<List<Family>>?>();

    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw Exception('unreachable'));
    final notifier = familyRepository.remoteAdapter.watchAllNotifier();

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    // finished loading but found the network unreachable
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);
    verifyNoMoreInteractions(listener);

    // now server will successfully respond with two families
    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');

    // reload
    await notifier.reload();

    final family = Family(id: '1', surname: 'Corleone');
    final family2 = Family(id: '2', surname: 'Soprano');

    // loads again, for now exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);

    await oneMs();

    // now responds with models, loading done, and no exception
    verify(listener(DataState([family, family2], isLoading: false))).called(1);
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
    final listener = Listener<DataState<Family?>?>();

    container.read(responseProvider.notifier).state = TestResponse(
      text: (_) => throw Exception('whatever'),
    );
    final notifier = familyRepository.remoteAdapter.watchOneNotifier('1');

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState<Family?>(null, isLoading: true))).called(1);
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

    // now server will successfully respond with a family
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Corleone" }
      ''');

    // reload
    await notifier.reload();
    await oneMs();

    final family = Family(id: '1', surname: 'Corleone');

    // loads again, for now exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);

    await oneMs();

    // now responds with model, loading done, and no exception
    verify(listener(DataState(family, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier with alsoWatch relationships', () async {
    // simulate Family that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    final family = Family(id: '22', surname: 'Paez', persons: HasMany());
    graph.getKeyForId('families', '22', keyIfAbsent: 'families#a1a1a1');
    await (familyRepository.remoteAdapter.localAdapter as HiveLocalAdapter)
        .box!
        .put('families#a1a1a1', family);

    final listener = Listener<DataState<Family?>?>();

    container.read(responseProvider.notifier).state =
        TestResponse.text('''{ "id": "22", "surname": "Paez" }''');
    final notifier = familyRepository.remoteAdapter.watchOneNotifier(
      '22',
      alsoWatch: (f) => [f.persons],
    );

    dispose = notifier.addListener(listener, fireImmediately: true);

    // verify loading
    verify(listener(DataState(family, isLoading: true))).called(1);
    verifyNoMoreInteractions(listener);

    final f1 = await familyRepository.findOne('22', remote: false);
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
    final listener = Listener<DataState<List<Family>>?>();

    container.read(responseProvider.notifier).state = TestResponse.text('[]');
    final notifier = familyRepository.remoteAdapter.watchAllNotifier();

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

    final notifier2 = familyRepository.remoteAdapter.watchAllNotifier();
    final listener2 = Listener<DataState<List<Family>>?>();

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
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider.notifier).state = TestResponse.text(
        '''[{ "id": "22", "surname": "Paez" }, { "id": "12", "surname": "Brunez" }]''');
    final notifier =
        familyRepository.remoteAdapter.watchAllNotifier(syncLocal: true);

    dispose = notifier.addListener(listener, fireImmediately: true);
    await oneMs();

    verify(listener(DataState([
      Family(id: '22', surname: 'Paez'),
      Family(id: '12', surname: 'Brunez'),
    ], isLoading: false)))
        .called(1);

    container.read(responseProvider.notifier).state =
        TestResponse.text('''[{ "id": "22", "surname": "Paez" }]''');
    await notifier.reload();
    await oneMs();

    verify(listener(DataState([
      Family(id: '22', surname: 'Paez'),
      Family(id: '12', surname: 'Brunez'),
    ], isLoading: true)))
        .called(1);

    verify(listener(DataState([
      Family(id: '22', surname: 'Paez'),
    ], isLoading: false)))
        .called(1);
  });

  test('remote can return a different ID', () async {
    Family(id: '1', surname: 'Corleone').init(container.read);
    Family(id: '2', surname: 'Moletto').init(container.read);

    // returns 2, not the requested 1
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{"id": "2", "surname": "Oslo"}''');
    await familyRepository.findOne('1');
    // (no model will show up in a watchOneNotifier('1') situation)

    // 1 was requested, but finally 2 was updated
    expect(await familyRepository.findOne('2', remote: false),
        Family(id: '2', surname: 'Oslo'));
  });

  test('reconcile keys under same ID', () async {
    // id=1 exists locally, has a key
    final family1 = Family(id: '1', surname: 'Corleone').init(container.read);

    // an id-less Family is created (obviously with new key)
    final family2 = Family(surname: 'Moletto').init(container.read);

    // therefore these objects have different keys
    expect(keyFor(family2), isNotNull);
    expect(keyFor(family1), isNot(keyFor(family2)));

    // it's saved to the server
    container.read(responseProvider.notifier).state =
        TestResponse.text('''{"id": "1", "surname": "Oslo"}''');
    await familyRepository.save(family2);

    // keys are reconciled and now both keys are equal
    expect(keyFor(family1), keyFor(family2));
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
    final families = await familyRepository.findOne(1);

    expect(families, Family(id: '1', surname: 'عمر'));
  });

  test('dispose', () {
    familyRepository.dispose();
    expect(familyRepository.isInitialized, isFalse);
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
  final Repository<Family> repo;
  Bloc(this.repo);
}
