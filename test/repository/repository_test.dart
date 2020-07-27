import 'dart:async';
import 'dart:io';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/family.dart';
import '../_support/mocks.dart';
import '../_support/person.dart';
import '../_support/pet.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('initialization', () {
    expect(familyRepository.isInitialized, isTrue);
  });

  test('findAll & clear', () async {
    final family1 = Family(id: '1', surname: 'Smith');
    final family2 = Family(id: '2', surname: 'Jones');

    final families = await familyRepository.findAll(remote: true, headers: {
      'response': '''
        [{ "id": "1", "surname": "Smith" }, { "id": "2", "surname": "Jones" }]
      ''',
    });

    expect(families, [family1, family2]);

    await familyRepository.clear();
    expect(await familyRepository.findAll(), isEmpty);
  });

  test('findOne', () async {
    final family = await familyRepository.findOne('1', remote: true, headers: {
      'response': '''
        { "id": "1", "surname": "Smith" }
      ''',
    });
    expect(family, Family(id: '1', surname: 'Smith'));

    // and it can be found again locally
    expect(family, await familyRepository.findOne('1'));
  });

  test('findOne with includes', () async {
    final family = await familyRepository.findOne('1',
        params: {'include': 'people'},
        remote: true,
        headers: {
          'response': '''
        { "id": "1", "surname": "Smith", "persons": [{"_id": "1", "name": "Stan", "age": 31}] }
      ''',
        });
    expect(family, Family(id: '1', surname: 'Smith'));

    // can be found again locally
    expect(family, await familyRepository.findOne('1'));

    // as well as the included Person
    expect(await personRepository.findOne('1'),
        Person(id: '1', name: 'Stan', age: 31));
  });

  test('findOne with errors', () async {
    try {
      await familyRepository.findOne('1', remote: true, headers: {
        'response': '''
        &*@~&^@^&!(@*(@#{ "id": "1", "surname": "Smith" }
      ''',
        'status': '203'
      });
    } catch (e) {
      expect(
          e,
          isA<DataException>()
              .having((e) => e.error, 'error', isA<FormatException>())
              .having((e) => e.statusCode, 'status code', 203));
    }

    // not found

    try {
      await familyRepository.findOne('2',
          remote: true,
          headers: {'response': '{ "error": "not found" }', 'status': '404'});
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
    expect(await familyRepository.findOne('1'), isNull);
  });

  test('socket exception', () async {
    try {
      await familyRepository
          .findOne('error', remote: true, headers: {'response': null});
    } catch (e) {
      expect(
          e,
          isA<DataException>()
              .having((e) => e.error, 'error', isA<SocketException>()));
    }
  });

  test('save', () async {
    // family with id=1 does not exist
    expect(await familyRepository.findOne('1'), isNull);

    // with empty response
    final family = Family(id: '1', surname: 'Smith');
    await familyRepository
        .save(family, remote: true, headers: {'response': '', 'status': '204'});
    // and it can be found again locally
    expect(family, await familyRepository.findOne('1'));

    // with non-empty response
    await familyRepository.save(Family(id: '2', surname: 'Jones'),
        remote: true,
        headers: {
          'response': '{"id": "2", "surname": "Jones Saved"}',
          'status': '200'
        });
    // and it can be found again locally
    expect((await familyRepository.findOne('2')).surname, 'Jones Saved');
  });

  test('delete', () async {
    // init a person
    final person = Person(id: '1', name: 'John', age: 21).init(owner);
    // it does have a key
    expect(keyFor(person), isNotNull);

    // now delete
    await personRepository
        .delete(person.id, remote: true, headers: {'response': ''});

    // so fetching by id again is null
    expect(await personRepository.findOne(person.id), isNull);
  });

  test('watchAll', () async {
    final listener = Listener<DataState<List<Family>>>();

    final notifier = familyRepository.watchAll(remote: true, headers: {
      'response': '''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''',
    });

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

    final notifier = familyRepository.watchAll(remote: true, headers: {
      'response': '^@!@#(#(@#)#@',
    });

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState([], isLoading: true))).called(1);
    await oneMs();

    verify(listener(argThat(isA<DataState>()
            .having((s) => s.exception, 'exception', isA<DataException>()))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne', () async {
    final listener = Listener<DataState<Person>>();

    final notifier = personRepository.watchOne('1', remote: true, headers: {
      'response': '''{ "_id": "1", "name": "Charlie", "age": 23 }''',
    });

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

    final notifier = personRepository.watchOne('1', remote: true, headers: {
      'response': '^@!@#(#(@#)#@',
    });

    dispose = notifier.addListener(listener, fireImmediately: true);

    verify(listener(DataState(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(argThat(isA<DataState>()
            .having((s) => s.exception, 'exception', isA<DataException>()))))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne with alsoWatch relationships', () async {
    // simulate Family that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    graph.getKeyForId('families', '22', keyIfAbsent: 'families#a1a1a1');
    await (familyRepository.internalAdapter.localAdapter as HiveLocalAdapter)
        .box
        .put('families#a1a1a1',
            Family(id: '22', surname: 'Paez', persons: HasMany()));

    final listener = Listener<DataState<Family>>();

    final notifier = familyRepository.watchOne(
      '22',
      remote: true,
      headers: {
        'response': '''{ "id": "22", "surname": "Paez" }''',
      },
      alsoWatch: (family) => [family.persons],
    );

    dispose = notifier.addListener(listener, fireImmediately: false);

    await oneMs(); // wait for response

    // not called as incoming model (watchOne) is identical
    // to the one in local storage
    verifyNever(listener(argThat(isA<DataState<Family>>())));
    verifyNoMoreInteractions(listener);

    final f1 = await familyRepository.findOne('22', remote: false);
    f1.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(
      withState<Family>((s) => s.model.persons, hasLength(1)),
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('remote can return a different ID', () async {
    Family(id: '1', surname: 'Corleone').init(owner);
    Family(id: '2', surname: 'Moletto').init(owner);

    await familyRepository.findOne('1', remote: true, headers: {
      // returns 2, not the requested 1
      'response': '''
        {"id": "2", "surname": "Oslo"}
      ''',
    });
    // (no model will show up in a watchOne('1') situation)

    // 1 was requested, but finally 2 was updated
    expect(
        await familyRepository.findOne('2'), Family(id: '2', surname: 'Oslo'));
  });

  test('reconcile keys under same ID', () async {
    // id=1 exists locally, has a key
    final family1 = Family(id: '1', surname: 'Corleone').init(owner);

    // an id-less Family is created (obviously with new key)
    final family2 = Family(surname: 'Moletto').init(owner);

    // therefore these objects have different keys
    expect(keyFor(family2), isNotNull);
    expect(keyFor(family1), isNot(keyFor(family2)));

    // it's saved to the server
    await familyRepository.save(family2, remote: true, headers: {
      // server decides it has an id=1
      'response': '''
        {"id": "1", "surname": "Oslo"}
      ''',
    });

    // keys are reconciled and now both keys are equal
    expect(keyFor(family1), keyFor(family2));
  });

  test('custom login adapter with repo extension', () async {
    // this crappy login uses password as token
    final token = await personRepository.login('email@email.com', 'zzz1');
    expect(token, 'zzz1');
  });

  test('custom login adapter with custom onError', () async {
    // sending a null email will trigger an error
    // and custom onError will throw an UnsupportedError
    // (instead of the standard DataException)
    expect(() async {
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
    Dog(id: '3', name: 'Bowie').init(owner);
    await dogRepository.delete(
      '3',
      params: {'a': 1},
      remote: true,
      headers: {'response': ''},
    );
    expect(verbose, ['[flutter_data] Dog: DELETE dogs/3?a=1 [HTTP 200]']);
  }));

  test('override baseUrl', () {
    // node repo has no baseUrl (doesn't mix in TestRemoteAdapter)
    expect(() async {
      return await nodeRepository
          .findOne('1', remote: true, headers: {'response': ''});
    }, throwsA(isA<UnsupportedError>()));
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
