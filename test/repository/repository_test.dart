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

    container.read(responseProvider).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final families = await familyRepository.findAll(remote: true);

    expect(families, [family1, family2]);

    await familyRepository.clear();
    expect(await familyRepository.findAll(), isEmpty);
  });

  test('findAll with and without syncLocal', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    container.read(responseProvider).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''');
    final families1 = await familyRepository.findAll(remote: true);

    expect(families1, [family1, family2]);

    container.read(responseProvider).state = TestResponse.text('''
        [{ "id": "1", "surname": "Smith" }]
      ''');
    final families2 =
        await familyRepository.findAll(remote: true, syncLocal: false);

    expect(families2, [family1]);

    // since `syncLocal: false` and `family2` was present from an older call, it remains in local storage
    expect(await familyRepository.findAll(remote: false), [family1, family2]);

    final families3 = await familyRepository.findAll(remote: true);

    expect(families3, [family1]);

    // using the default `syncLocal: true` the result is equal to the contents of local storage
    expect(await familyRepository.findAll(remote: false), families3);
  });

  test('findOne', () async {
    container.read(responseProvider).state = TestResponse.text('''
        { "id": "1", "surname": "Smith" }
      ''');
    final family = await familyRepository.findOne('1', remote: true);
    expect(family, Family(id: '1', surname: 'Smith'));

    // and it can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));
  });

  test('findOne with empty response', () async {
    container.read(responseProvider).state = TestResponse.text('');
    final family = await familyRepository.findOne('1', remote: true);
    expect(family, null);
  });

  test('findOne with includes', () async {
    container.read(responseProvider).state = TestResponse.text('''
        { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
      ''');
    final family = await familyRepository.findOne('1',
        params: {'include': 'people'}, remote: true);
    expect(family, Family(id: '1', surname: 'Smith'));

    // can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));

    // as well as the included Person
    expect(await personRepository.findOne('1', remote: false),
        Person(id: '1', name: 'Stan', age: 31));
  });

  test('findOne with errors', () async {
    try {
      container.read(responseProvider).state = TestResponse(
          text: (_) => '''&*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }''',
          statusCode: 203);
      await familyRepository.findOne('1', remote: true);
    } catch (e) {
      expect(
          e,
          isA<DataException>()
              .having((e) => e.error, 'error', isA<FormatException>())
              .having((e) => e.statusCode, 'status code', 203));
    }

    // not found

    try {
      container.read(responseProvider).state = TestResponse(
          text: (_) => '{ "error": "not found" }', statusCode: 404);
      await familyRepository.findOne('2', remote: true);
    } catch (e) {
      expect(
        e,
        isA<DataException>().having(
          (e) => e.error,
          'error',
          {'error': 'not found'},
        ).having((e) => e.statusCode, 'status code', 404),
      );
    }

    // no record locally
    expect(await familyRepository.findOne('1', remote: false), isNull);
  });

  test('socket exception', () async {
    try {
      container.read(responseProvider).state =
          TestResponse(text: (_) => throw SocketException('unreachable'));
      await familyRepository.findOne('error', remote: true);
    } catch (e) {
      expect(
          e,
          isA<DataException>().having(
            (e) => e.error,
            'SocketException',
            isA<SocketException>(),
          ));
    }
  });

  test('save', () async {
    // family with id=1 does not exist
    expect(await familyRepository.findOne('1'), isNull);

    // with empty response
    final family = Family(id: '1', surname: 'Smith');
    container.read(responseProvider).state = TestResponse.text('');
    await familyRepository.save(family, remote: true);
    // and it can be found again locally
    expect(family, await familyRepository.findOne('1', remote: false));

    // with non-empty response
    container.read(responseProvider).state =
        TestResponse.text('{"id": "2", "surname": "Jones Saved"}');
    await familyRepository.save(Family(id: '2', surname: 'Jones'),
        remote: true);
    // and it can be found again locally
    final family2 = await familyRepository.findOne('2', remote: false);
    expect(family2.surname, 'Jones Saved');
  });

  test('save with error', () async {
    final family = Family(id: '1', surname: 'Smith');
    container.read(responseProvider).state = TestResponse.text('@**&#*#&');

    // overrides error handling with notifier
    final listener = Listener<DataState<List<Family>>>();
    final notifier = familyRepository.watchAll(remote: false);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: false))).called(1);

    await familyRepository.save(family, remote: true, onError: (e) async {
      await oneMs();
      notifier.updateWith(exception: e);
    });
    await oneMs();

    verify(listener(DataState([family], isLoading: false))).called(1);

    verify(listener(argThat(
      isA<DataState>().having((s) {
        return s.exception.error;
      }, 'exception', isA<FormatException>()),
    ))).called(1);
  });

  test('delete', () async {
    // init a person
    final person = Person(id: '1', name: 'John', age: 21).init(container.read);
    // it does have a key
    expect(keyFor(person), isNotNull);

    // now delete
    container.read(responseProvider).state = TestResponse.text('');
    await personRepository.delete(person.id, remote: true);

    // so fetching by id again is null
    expect(await personRepository.findOne(person.id), isNull);
  });

  test('watchAll', () async {
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');
    final notifier = familyRepository.watchAll(remote: true);

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

  test('watchAll with error', () async {
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider).state = TestResponse.text('''
        '^@!@#(#(@#)#@'
      ''');
    final notifier = familyRepository.watchAll(remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    verify(listener(argThat(isA<DataState<List<Family>>>().having(
            (s) => s.exception.error, 'exception', isA<FormatException>()))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne', () async {
    final listener = Listener<DataState<Person>>();

    container.read(responseProvider).state = TestResponse.text(
      '''{ "_id": "1", "name": "Charlie", "age": 23 }''',
    );
    final notifier = personRepository.watchOne('1', remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(DataState(Person(id: '1', name: 'Charlie', age: 23),
            isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);

    await personRepository.save(Person(id: '1', name: 'Charlie', age: 24));
    await oneMs();

    verify(listener(argThat(withState<Person>((s) => s.model.age, 24))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne with error', () async {
    final listener = Listener<DataState<Person>>();

    container.read(responseProvider).state = TestResponse(
      text: (_) => throw Exception('whatever'),
    );
    final notifier = personRepository.watchOne('1', remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(argThat(isA<DataState>().having(
            (s) => s.exception.error.toString(),
            'exception',
            'Exception: whatever'))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne with alsoWatch relationships', () async {
    // simulate Family that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    graph.getKeyForId('families', '22', keyIfAbsent: 'families#a1a1a1');
    await (familyRepository.remoteAdapter.localAdapter as HiveLocalAdapter)
        .box
        .put('families#a1a1a1',
            Family(id: '22', surname: 'Paez', persons: HasMany()));

    final listener = Listener<DataState<Family>>();

    container.read(responseProvider).state =
        TestResponse.text('''{ "id": "22", "surname": "Paez" }''');
    final notifier = familyRepository.watchOne(
      '22',
      remote: true,
      alsoWatch: (family) => [family.persons],
    );

    dispose = notifier.addListener(listener, fireImmediately: true);

    // verify loading
    verify(listener(argThat(
      withState<Family>((s) => s.isLoading, true),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    final f1 = await familyRepository.findOne('22', remote: false);
    f1.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(
            withState<Family>((s) => s.model.persons, hasLength(1))
                .having((s) => s.isLoading, 'loading', false))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAll updates isLoading even in an empty response', () async {
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider).state = TestResponse.text('[]');
    final notifier = familyRepository.watchAll(remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(argThat(
      isA<DataState<List<Family>>>()
          .having((s) => s.isLoading, 'loading', true),
    ))).called(1);

    await oneMs();

    verify(listener(argThat(
      isA<DataState<List<Family>>>()
          .having((s) => s.model, 'empty', isEmpty)
          .having((s) => s.isLoading, 'loading', false),
    ))).called(1);
  });

  test('watchAll syncLocal', () async {
    final listener = Listener<DataState<List<Family>>>();

    container.read(responseProvider).state = TestResponse.text(
        '''[{ "id": "22", "surname": "Paez" }, { "id": "12", "surname": "Brunez" }]''');
    final notifier = familyRepository.watchAll(remote: true);

    dispose = notifier.addListener(listener, fireImmediately: true);
    await oneMs();

    verify(listener(DataState([
      Family(id: '22', surname: 'Paez'),
      Family(id: '12', surname: 'Brunez'),
    ], isLoading: false)))
        .called(1);

    container.read(responseProvider).state =
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
    container.read(responseProvider).state =
        TestResponse.text('''{"id": "2", "surname": "Oslo"}''');
    await familyRepository.findOne('1', remote: true);
    // (no model will show up in a watchOne('1') situation)

    // 1 was requested, but finally 2 was updated
    expect(
        await familyRepository.findOne('2'), Family(id: '2', surname: 'Oslo'));
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
    container.read(responseProvider).state =
        TestResponse.text('''{"id": "1", "surname": "Oslo"}''');
    await familyRepository.save(family2, remote: true);

    // keys are reconciled and now both keys are equal
    expect(keyFor(family1), keyFor(family2));
  });

  test('custom login adapter with repo extension', () async {
    // this crappy login uses password as token
    container.read(responseProvider).state =
        TestResponse.text('''{ "token": "zzz1" }''');

    final token = await personRepository.login('email@email.com', 'zzz1');
    expect(token, 'zzz1');
  });

  test('custom login adapter with custom onError', () async {
    // sending a null email will trigger an error
    // and custom onError will throw an UnsupportedError
    // (instead of the standard DataException)
    expect(() async {
      container.read(responseProvider).state =
          TestResponse.text('''&*@%%*#@!''');
      await personRepository.login(null, null);
    }, throwsA(isA<UnsupportedError>()));

    await personRepository.doNothing(null, 1);
  });

  test('mock repository', () async {
    final bloc = Bloc(MockFamilyRepository());
    when(bloc.repo.findAll())
        .thenAnswer((_) => Future(() => [Family(surname: 'Smith')]));
    final families = await bloc.repo.findAll();
    expect(families, predicate((list) => list.first.surname == 'Smith'));
    verify(bloc.repo.findAll());
  });

  test('verbose', overridePrint(() async {
    Dog(id: '3', name: 'Bowie').init(container.read);
    container.read(responseProvider).state = TestResponse.text('');
    await dogRepository.delete('3', params: {'a': 1}, remote: true);
    expect(verbose, ['[flutter_data] Dog: DELETE /dogs/3?a=1 [HTTP 200]']);

    try {
      container.read(responseProvider).state =
          TestResponse(text: (_) => '^@!@#(#(@#)#@', statusCode: 500);
      await dogRepository.findOne('1', remote: true);
    } catch (e) {
      expect(verbose.last, contains('DataException'));
    }
  }));

  test('override baseUrl', () {
    // node repo has no baseUrl (doesn't mix in TestRemoteAdapter)
    expect(() async {
      container.read(responseProvider).state = TestResponse.text('');
      return await nodeRepository.findOne('1', remote: true);
    }, throwsA(isA<UnsupportedError>()));
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
