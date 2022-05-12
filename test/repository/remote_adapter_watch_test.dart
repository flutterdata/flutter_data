import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';
import '../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('watchAll', () async {
    final listener = Listener<DataState<List<Familia>?>>();

    container.read(responseProvider.notifier).state = TestResponse.text('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');
    final notifier = container.familia.watchAllNotifier();

    dispose = notifier.addListener(listener);

    verify(listener(DataState(null, isLoading: true))).called(1);
    await oneMs();

    verify(listener(DataState([
      Familia(id: '1', surname: 'Corleone'),
      Familia(id: '2', surname: 'Soprano')
    ], isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAll with error', () async {
    final listener = Listener<DataState<List<Familia>?>?>();

    container.read(responseProvider.notifier).state =
        TestResponse(text: (_) => throw Exception('unreachable'));
    final notifier = container.familia.watchAllNotifier();

    dispose = notifier.addListener(listener);

    verify(listener(DataState(null, isLoading: true))).called(1);
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

  test('watchOne with remote=true', () async {
    final listener = Listener<DataState<Person?>?>();

    container.read(responseProvider.notifier).state = TestResponse.text(
      '''{ "_id": "1", "name": "Charlie", "age": 23 }''',
    );

    final notifier = container.people.watchOneNotifier('1', remote: true);

    dispose = notifier.addListener(listener);

    verify(listener(DataState(null, isLoading: true))).called(1);

    await oneMs();

    final charlie = isA<DataState>()
        .having((s) => s.isLoading, 'isLoading', isFalse)
        .having((s) => s.model.id, 'id', '1')
        .having((s) => s.model.age, 'age', 23)
        .having((s) => s.model.name, 'name', 'Charlie')
        // ensure the notifier has been attached
        .having((s) => s.model.notifier, 'notifier', isNotNull);

    verify(listener(argThat(charlie))).called(1);
    verifyNoMoreInteractions(listener);

    Person(id: '1', name: 'Charlie', age: 24).saveLocal();
    await oneMs();

    // unrelated request should not affect the current listener
    await container.familia.findOne('234324', remote: false);
    await oneMs();

    verify(listener(DataState(Person(id: '1', name: 'Charlie', age: 24),
            isLoading: false)))
        .called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne with error', () async {
    final listener = Listener<DataState<Familia?>?>();

    container.read(responseProvider.notifier).state = TestResponse(
      text: (_) => throw Exception('whatever'),
    );
    final notifier = container.familia.watchOneNotifier('1');

    dispose = notifier.addListener(listener);

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
    final familia = Familia(id: '1', surname: 'Corleone');
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": "1", "surname": "Corleone" }
      ''');

    // reload
    await notifier.reload();
    await oneMs();

    // loads again, for now exception remains
    verify(listener(argThat(isA<DataState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.exception, 'exception', isA<Exception>()))))
        .called(1);

    // now responds with model, loading done, and no exception
    verify(listener(DataState(familia, isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOne with alsoWatch relationships', () async {
    // simulate Familia that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    final familia = await Familia(id: '22', surname: 'Paez', persons: HasMany())
        .save(remote: false);

    container.familia.logLevel = 1;

    final listener = Listener<DataState<Familia?>?>();

    container.read(responseProvider.notifier).state =
        TestResponse.text('''{ "id": "22", "surname": "Paez" }''');
    final notifier =
        container.familia.watchOneNotifier('22', alsoWatch: (f) => {f.persons});

    dispose = notifier.addListener(listener);

    // verify loading
    verify(listener(DataState(familia, isLoading: true))).called(1);

    await oneMs();

    verify(listener(argThat(isA<DataState>()
            .having((s) => s.model.persons!, 'rel', isEmpty)
            .having((s) => s.isLoading, 'loading', false))))
        .called(1);
    verifyNoMoreInteractions(listener);

    // add a watched relationship
    var martin =
        Person(id: '1', name: 'Martin', age: 44, familia: familia.asBelongsTo)
            .saveLocal();

    verify(listener(argThat(isA<DataState>()
            .having((s) => s.model.persons!.toSet(), 'rel', {martin}).having(
                (s) => s.isLoading, 'loading', false))))
        .called(1);
    verifyNoMoreInteractions(listener);

    // update person
    martin = Person(id: '1', name: 'Martin', age: 45).saveLocal();

    verify(listener(argThat(isA<DataState>().having(
        (s) => s.model.persons!.toSet(),
        'rel',
        {Person(id: '1', name: 'Martin', age: 45)})))).called(1);
    verifyNoMoreInteractions(listener);

    // update another person through deserialization
    container.read(responseProvider.notifier).state = TestResponse.text(
        '''{ "_id": "2", "name": "Eve", "age": 20, "familia": "22" }''');
    final eve = await container.people.findOne('2', remote: true);
    await oneMs();

    verify(listener(argThat(isA<DataState>().having((s) {
      return s.model.persons!.toSet();
    }, 'rel', unorderedEquals({martin, eve}))))).called(1);
    verifyNoMoreInteractions(listener);

    // create another person
    final maria = Person(id: '3', name: 'Maria', familia: familia.asBelongsTo)
        .saveLocal();
    await oneMs();

    verify(listener(argThat(isA<DataState>().having((s) {
      return s.model.persons!.toSet();
    }, 'rel', unorderedEquals({martin, eve, maria}))))).called(1);
    verifyNoMoreInteractions(listener);

    // remove person
    familia.persons.remove(martin);
    verify(listener(argThat(isA<DataState>().having(
        (s) => s.model.persons!.toSet(), 'rel', {eve, maria})))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier with alsoWatch relationships (remote=false)',
      () async {
    // simulate Familia that exists in local storage
    // important to keep to test `alsoWatch` assignment order
    final familia = Familia(id: '1', surname: 'Paez', persons: HasMany());

    final listener = Listener<DataState<Familia?>?>();

    final notifier = container.familia
        .watchOneNotifier('1', remote: false, alsoWatch: (f) => {f.persons});

    // we don't want it to immediately notify the default local model
    dispose = notifier.addListener(listener, fireImmediately: false);

    familia.persons.add(Person(id: '1', name: 'Ricky'));
    await oneMs();

    verify(listener(DataState(familia))).called(1);

    Person(id: '1', name: 'Ricardo').saveLocal();
    await oneMs();

    verify(listener(DataState(familia))).called(1);
  });

  test('watchAllNotifier updates isLoading even in an empty response',
      () async {
    final listener = Listener<DataState<List<Familia>?>?>();

    container.read(responseProvider.notifier).state = TestResponse.text('[]');
    final notifier = container.familia.watchAllNotifier(remote: true);

    dispose = notifier.addListener(listener);

    verify(listener(argThat(
      isA<DataState>()
          .having((s) => s.isLoading, 'loading', true)
          // local storage should be null at this point
          .having((s) => s.model, 'model', null),
    ))).called(1);

    await oneMs();

    verify(listener(argThat(
      isA<DataState>()
          // empty because the server response was an empty list
          .having((s) => s.model, 'model', isEmpty)
          .having((s) => s.isLoading, 'loading', false),
    ))).called(1);

    // reload and try again

    await notifier.reload();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.isLoading, 'loading', true),
    ))).called(1);

    await oneMs();

    verify(listener(argThat(
      isA<DataState>()
          .having((s) => s.model, 'empty', isEmpty)
          .having((s) => s.isLoading, 'loading', false),
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchAllNotifier syncLocal', () async {
    final listener = Listener<DataState<List<Familia>?>>();

    container.read(responseProvider.notifier).state = TestResponse.text(
        '''[{ "id": "22", "surname": "Paez" }, { "id": "12", "surname": "Brunez" }]''');

    final notifier = container.familia.watchAllNotifier(syncLocal: true);

    dispose = notifier.addListener(listener);
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

  test('watchAllNotifier with multiple model updates', () async {
    final notifier = container.people.watchAllNotifier(remote: false);

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('Number') && p.age! < 19;
    });

    final count = 29;
    var i = 0;
    dispose = notifier.addListener(
      expectAsync1((state) {
        if (i == 0) {
          expect(state.model, isNull);
          expect(state.isLoading, isFalse);
        } else if (i <= count) {
          expect(state.model, List.generate(i, (_) => matcher));
          final adapter = container.people.remoteAdapter.localAdapter
              as HiveLocalAdapter<Person>;
          // check box has all the keys
          expect(adapter.box!.keys.length, i);
        } else {
          // one less because of emitting the deletion,
          // and one less because of the now missing model
          expect(state.model, hasLength(i - 2));
        }
        i++;
        // 1 extra count because of the initial `null` state
        // 1 extra count because of the deletion in the loop below
        // 1 extra count because of the self-ref due to the deletion
      }, count: count + 2),
    );

    // this emits `count` states
    Person person;
    for (var j = 0; j < count; j++) {
      await (() async {
        final id =
            Random().nextBool() ? Random().nextInt(999999999).toString() : null;
        person = Person.generate(withId: id).saveLocal();

        // in the last cycle, delete last Person too
        if (j == count - 1) {
          await oneMs();
          await person.delete();
        }
        await oneMs();
      })();
    }
  });

  test('watchAllNotifier updates, watchAll', () async {
    final listener = Listener<DataState<List<Person>?>>();

    final p1 = Person(id: '1', name: 'Zof', age: 23).saveLocal();
    final notifier = container.people.watchAllNotifier(remote: true);

    dispose = notifier.addListener(listener);

    verify(listener(DataState([p1], isLoading: true))).called(1);
    verifyNoMoreInteractions(listener);

    final p2 = Person(id: '1', name: 'Zofie', age: 23).saveLocal();
    await oneMs();

    verify(listener(DataState([p2], isLoading: false))).called(1);
    verifyNoMoreInteractions(listener);

    // since p3 is not saved it won't show up thru watchAllNotifier
    final p3 = Person(id: '1', name: 'Zofien', age: 23);
    await oneMs();

    verifyNever(listener(DataState([p3], isLoading: false)));
    verifyNoMoreInteractions(listener);

    expect(container.people.watchAll(), DataState<List<Person>?>([p3]));
  });

  test('watchAllNotifier with where/map', () async {
    final listener = Listener<DataState<List<Person>?>>();

    Person(id: '1', name: 'Zof', age: 23);
    Person(id: '2', name: 'Sarah', age: 50);
    Person(id: '3', name: 'Walter', age: 11);
    Person(id: '4', name: 'Koen', age: 92);

    final notifier = container.people
        .watchAllNotifier()
        .where((p) => p.age! < 40)
        .map((p) => Person(name: p.name, age: p.age! + 10));

    dispose = notifier.addListener(listener);

    verify(listener(DataState(
      [Person(name: 'Zof', age: 33), Person(name: 'Walter', age: 21)],
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier and watchOne', () async {
    final listener = Listener<DataState<Person?>?>();

    final notifier = container.people.watchOneNotifier('1');

    final matcher = (name) => isA<DataState>()
        .having((s) => s.model.id, 'id', '1')
        .having((s) => s.model.name, 'name', name);

    dispose = notifier.addListener(listener, fireImmediately: false);

    Person(id: '1', name: 'Frank', age: 30).saveLocal();
    await oneMs();

    verify(listener(argThat(matcher('Frank')))).called(1);
    verifyNoMoreInteractions(listener);

    await container.people.remoteAdapter
        .save(Person(id: '1', name: 'Steve-O', age: 34));
    await oneMs();

    verify(listener(argThat(matcher('Steve-O')))).called(1);
    verifyNoMoreInteractions(listener);

    await container.people.remoteAdapter
        .save(Person(id: '1', name: 'Liam', age: 36));
    await oneMs();

    verify(listener(argThat(matcher('Liam')))).called(1);
    verifyNoMoreInteractions(listener);

    // a different ID doesn't trigger
    await container.people.remoteAdapter
        .save(Person(id: '2', name: 'Jupiter', age: 3));
    await oneMs();

    verifyNever(listener(argThat(matcher('Jupiter'))));
    verifyNoMoreInteractions(listener);

    // also ensure watchers return expected state
    expect(container.people.watchOne('1'),
        DataState<Person?>(Person(id: '1', name: 'Liam', age: 36)));
  });

  test('watchOneNotifier reads latest version', () async {
    Person(id: '345', name: 'Frank', age: 30);
    Person(id: '345', name: 'Steve-O', age: 34);

    final notifier = container.people.watchOneNotifier('345');

    dispose = notifier.addListener(expectAsync1((state) {
      expect(state.model!.name, 'Steve-O');
    }));
  });

  test('watchOneNotifier with custom finder', () async {
    // initialize a book in local storage, so we can later link it to the author
    final author = BookAuthor(id: 1, name: 'Robert', books: HasMany());
    Book(
        id: 1,
        title: 'Choice',
        originalAuthor: author.asBelongsTo,
        ardentSupporters: HasMany());

    // update the author
    container.read(responseProvider.notifier).state = TestResponse.text('''
        { "id": 1, "name": "Frank" }
      ''');

    final listener = Listener<DataState<BookAuthor?>?>();

    final notifier =
        container.bookAuthors.watchOneNotifier(1, remote: true, finder: 'caps');

    dispose = notifier.addListener(listener);

    verify(listener(DataState(author, isLoading: true))).called(1);

    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model!.name, 'name', 'FRANK'),
    ))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier with alsoWatch relationships remote=false', () async {
    final f1 = Familia(
      id: '22',
      surname: 'Abagnale',
      persons: HasMany(),
      residence: BelongsTo(),
      cottage: BelongsTo(),
    );

    final listener = Listener<DataState<Familia?>?>();

    final notifier = container.familia.watchOneNotifier(
      '22',
      remote: false,
      alsoWatch: (familia) => {familia.persons, familia.residence},
    );

    dispose = notifier.addListener(listener);

    final p1 = Person(id: '1', name: 'Frank', age: 16);

    final matcher = isA<DataState>()
        .having((s) => s.model.persons!, 'persons', isEmpty)
        .having((s) => s.hasModel, 'hasModel', true)
        .having((s) => s.hasException, 'hasException', false)
        .having((s) => s.isLoading, 'isLoading', false);

    verify(listener(argThat(matcher))).called(1);

    p1.familia.value = f1;
    await oneMs();

    final matcher2 = isA<DataState>()
        .having((s) => s.model.persons!, 'persons', hasLength(1))
        .having((s) => s.hasModel, 'hasModel', true)
        .having((s) => s.hasException, 'hasException', false)
        .having((s) => s.isLoading, 'isLoading', false);

    verify(listener(argThat(matcher2))).called(1);

    f1.persons.add(Person(name: 'Martin', age: 44)); // this time without init
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model.persons!, 'persons', hasLength(2)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.residence.value = House(address: '123 Main St'); // no init
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having(
          (s) => s.model.residence!.value!.address, 'address', '123 Main St'),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    f1.persons.remove(p1);
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) => s.model.persons!, 'persons', hasLength(1)),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    // a non-watched relationship does not trigger
    f1.cottage.value = House(address: '7342 Mountain Rd');
    await oneMs();

    verifyNever(listener(any));
    verifyNoMoreInteractions(listener);

    await f1.delete();
    await oneMs();

    // 1 event for node removal
    // 1 event for persons relationship removed
    // 1 event for residence relationship removed
    // 1 event for cottage relationship removed
    // a few extra for?!
    verify(listener(argThat(
      isA<DataState>().having((s) => s.model, 'model', isNull),
    ))).called(7);
    verifyNoMoreInteractions(listener);
  });

  test('watchOneNotifier without ID and alsoWatch', () async {
    final frank = Person(name: 'Frank', age: 30).saveLocal();

    final notifier = container.people.watchOneNotifier(
      frank,
      // TODO alsoWatch: (p) => {p.familia.persons},
    );

    final listener = Listener<DataState<Person?>?>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    final matcher = isA<DataState>()
        .having((s) => s.model.name, 'name', 'Steve-O')
        .having((s) => s.hasException, 'exception', isFalse)
        .having((s) => s.isLoading, 'loading', isFalse);

    verifyNever(listener(argThat(matcher)));
    verifyNoMoreInteractions(listener);

    final steve = Person(name: 'Steve-O', age: 30).was(frank).saveLocal();
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    final cottage = House(id: '32769', address: '32769 Winding Road');

    final familia = Familia(
      surname: 'Marquez',
      cottage: cottage.asBelongsTo,
    ).saveLocal();
    steve.familia.value = familia;
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    Familia(surname: 'Thomson', cottage: cottage.asBelongsTo)
        .was(familia)
        .saveLocal();
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    House(id: '32769', address: '8 Hill St').saveLocal();
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);

    Familia(surname: 'Thomson', cottage: BelongsTo.remove())
        .was(familia)
        .saveLocal();
    await oneMs();

    verify(listener(argThat(matcher))).called(1);
    verifyNoMoreInteractions(listener);
  }, skip: true);

  test('watchOneNotifier with where/map', () async {
    final listener = Listener<DataState<Person?>>();

    Person(id: '1', name: 'Zof', age: 23).saveLocal();

    final notifier = container.people
        .watchOneNotifier('1')
        .map((p) => Person(name: p!.name, age: p.age! + 10))
        .where((p) => p!.age! < 40);

    dispose = notifier.addListener(listener);

    verify(listener(DataState(
      Person(name: 'Zof', age: 33),
    ))).called(1);
    verifyNoMoreInteractions(listener);

    Person(id: '1', name: 'Zof', age: 71).saveLocal();
    await oneMs();

    // since 71 + 10 > 40, the listener will receive a null
    verify(listener(DataState(null))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('should be able to watch, dispose and watch again', () async {
    final notifier = container.people.watchAllNotifier();
    dispose = notifier.addListener((_) {});
    dispose!();
    final notifier2 = container.people.watchAllNotifier();
    dispose = notifier2.addListener((_) {});
  });

  test('save with error', () async {
    container.read(responseProvider.notifier).state =
        TestResponse.text('@**&#*#&');

    // overrides error handling with notifier
    final listener = Listener<DataState<List<Familia>?>?>();
    final notifier = container.familia.watchAllNotifier(remote: false);

    dispose = notifier.addListener(listener);

    verify(listener(DataState(null, isLoading: false))).called(1);

    // ignore: missing_return
    await container.familia.save(
      Familia(id: '1', surname: 'Smith'),
      onError: (e, _, __) async {
        notifier.updateWith(exception: e);
        return null;
      },
    );
    await oneMs();

    verify(listener(argThat(
      isA<DataState>().having((s) {
        return s.exception!.error;
      }, 'exception', isA<FormatException>()),
    ))).called(1);
  });

  test('notifier equality', () async {
    final bookAuthor = BookAuthor(id: 1, name: 'Billy', books: HasMany());

    final defaultNotifier = container.bookAuthors.watchOneNotifier(1);

    final capsNotifier = container.read(container.bookAuthors
        .watchOneProvider(bookAuthor, finder: 'caps')
        .notifier);
    final capsNotifier2 =
        container.bookAuthors.watchOneNotifier(1, finder: 'caps');
    final capsNotifier3 =
        container.bookAuthors.watchOneNotifier(1, finder: 'caps');

    // calling it via watchOneProvider.notifier is equivalent to calling watchOneNotifier
    expect(capsNotifier, equals(capsNotifier2));

    // even if they share the ID, finder makes them different
    expect(defaultNotifier, isNot(capsNotifier2));

    // exact same request results in same notifier
    expect(capsNotifier2, equals(capsNotifier3));

    // similar tests without IDs
    final p = Person(name: 'Daniel');
    final p2 = Person(name: 'Bobby');
    final pn1 = container.read(container.people.watchOneProvider(p).notifier);
    final pn1b = container.people.watchOneNotifier(p);
    final pn2 = container.people.watchOneNotifier(p2);
    expect(pn1, equals(pn1b));
    expect(pn1, isNot(pn2));

    // unfortunately alsoWatch will return different notifiers (for now)
    // (we need to figure out the equality of closures like alsoWatch)
    // final pn3 =
    //     container.people.watchOneNotifier(p2, alsoWatch: (p) => [p.familia]);
    // final pn3b =
    //     container.people.watchOneNotifier(p2, alsoWatch: (p) => [p.familia]);
    // expect(pn3, isNot(pn3b));
    // expect(pn2, isNot(pn3));

    // all
    final apn1 = container.read(container.people.watchAllProvider().notifier);
    final apn2 = container.people.watchAllNotifier();
    expect(apn1, equals(apn2));

    final state = container.bookAuthors.watchOne(1);
    expect(state.model!, bookAuthor);

    final model = container.bookAuthors.watch(bookAuthor);
    expect(model, bookAuthor);
  });

  test('watchargs', () {
    // ignores alsoWatch for now
    final a1 = WatchArgs<Person>(
        key: 'e23f44', remote: false, alsoWatch: (p) => [], finder: 'finder');
    final a2 =
        WatchArgs<Person>(key: 'e23f44', remote: false, finder: 'finder');
    expect(a1, a2);

    // ?
    // final b1 = WatchArgs<Person>(key: 'b');
    // final b2 = WatchArgs<Person>(key: 'b', remote: false);
    // expect(b1, b2);
  });
}
