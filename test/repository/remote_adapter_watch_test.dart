import 'dart:math';

import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../_support/book.dart';
import '../_support/familia.dart';
import '../_support/house.dart';
import '../_support/person.dart';
import '../_support/setup.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('watchAll', () async {
    container.read(responseProvider.notifier).state = TestResponse.json('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');
    final notifier = container.familia.watchAllNotifier(remote: true);
    final tester = notifier.tester();

    final familias = [
      Familia(id: '1', surname: 'Corleone'),
      Familia(id: '2', surname: 'Soprano')
    ];

    await tester.expectDataState(familias);

    notifier.reload();

    await tester.expectDataState(familias);
  });

  test('watchAll with error', () async {
    container.read(responseProvider.notifier).state =
        TestResponse((_) => throw Exception('unreachable'));
    final notifier = container.familia.watchAllNotifier(remote: true);
    final tester = notifier.tester();

    await tester
        .expectDataState([], isLoading: false, exception: isA<Exception>());

    // now server will successfully respond with two familia
    container.read(responseProvider.notifier).state = TestResponse.json('''
        [{ "id": "1", "surname": "Corleone" }, { "id": "2", "surname": "Soprano" }]
      ''');

    // reload
    await notifier.reload();

    final familia = Familia(id: '1', surname: 'Corleone');
    final familia2 = Familia(id: '2', surname: 'Soprano');

    await tester.expectDataState([familia, familia2], isLoading: false);
  });

  test('watchOne with remote=true', () async {
    container.read(responseProvider.notifier).state = TestResponse.json(
      '''{ "_id": "1", "name": "Charlie", "age": 23 }''',
    );

    final notifier = container.people.watchOneNotifier('1', remote: true);
    final tester = notifier.tester();

    // await notifier.stream.expectDataState(isNull, isLoading: isTrue);
    await tester.expectDataState([((m) => m.age, 23), ((m) => m.id, '1')],
        isLoading: isFalse);

    final updated = Person(id: '1', name: 'Charlie', age: 24).saveLocal();
    // unrelated request should not affect the current listener
    await container.familia.findOne('234324', remote: false);

    await tester.expectDataState(updated);
  });

  test('watchOne with error', () async {
    container.read(responseProvider.notifier).state = TestResponse(
      (_) => throw Exception('whatever'),
    );
    final notifier = container.familia.watchOneNotifier('1', remote: true);
    final tester = notifier.tester();

    await tester.expectDataState(null,
        isLoading: isFalse,
        exception: isA<DataException>()
            .having((e) => e.error.toString(), 'e', contains('whatever')));

    container.read(responseProvider.notifier).state =
        TestResponse((_) => throw Exception('unreachable'));

    notifier.reload();

    // finished loading but found the network unreachable
    await tester.expectDataState(null,
        isLoading: isFalse,
        exception: isA<DataException>()
            .having((e) => e.error.toString(), 'e', contains('unreachable')));

    // now server will successfully respond with a familia
    final familia = Familia(id: '1', surname: 'Corleone');
    container.read(responseProvider.notifier).state = TestResponse.json('''
        { "id": "1", "surname": "Corleone" }
      ''');

    // reload
    notifier.reload();

    // now responds with model, loading done, and no exception
    await tester.expectDataState(familia, isLoading: false, exception: null);
  });

  test('watchOne with alsoWatch relationships', () async {
    final notifier =
        container.familia.watchOneNotifier('22', alsoWatch: (f) => {f.persons});
    final tester = notifier.tester();

    final familia =
        Familia(id: '22', surname: 'Paez', persons: HasMany()).saveLocal();

    await tester
        .expectDataState([((m) => m.persons, isEmpty)], isLoading: isFalse);

    // add a watched relationship
    var martin =
        Person(id: '1', name: 'Martin', age: 44, familia: familia.asBelongsTo)
            .saveLocal();

    await tester.expectDataState([
      ((m) => m.persons.toSet(), {martin})
    ]);

    // update person
    martin = Person(id: '1', name: 'Martin', age: 45).saveLocal();

    await tester.expectDataState([
      ((m) => m.persons.toSet(), {martin})
    ]);

    // update another person through deserialization
    container.read(responseProvider.notifier).state = TestResponse.json(
        '''{ "_id": "2", "name": "Eve", "age": 20, "familia": "22" }''');
    final eve = await container.people.findOne('2', remote: true);

    await tester.expectDataState([
      ((m) => m.persons.toSet(), {martin, eve})
    ]);

    // create another person
    final maria = Person(id: '3', name: 'Maria', familia: familia.asBelongsTo)
        .saveLocal();

    await tester.expectDataState([
      ((m) => m.persons.toSet(), {martin, eve, maria})
    ]);

    // remove person
    familia.persons.remove(martin);

    await tester.expectDataState([
      ((m) => m.persons.toSet(), {eve, maria})
    ]);
  });

  test('watchAllNotifier updates isLoading even in an empty response',
      () async {
    container.read(responseProvider.notifier).state = TestResponse.json('[]');
    final notifier = container.familia.watchAllNotifier(remote: true);
    final tester = notifier.tester();

    await tester.expectDataState(isEmpty, isLoading: isFalse);

    // reload and try again

    notifier.reload();

    await tester.expectDataState(isEmpty, isLoading: isFalse);
  });

  test('watchAllNotifier syncLocal', () async {
    container.read(responseProvider.notifier).state = TestResponse.json(
        '''[{ "id": "22", "surname": "Paez" }, { "id": "12", "surname": "Brunez" }]''');

    final notifier =
        container.familia.watchAllNotifier(syncLocal: true, remote: true);
    final tester = notifier.tester();

    await tester.expectDataState(
        unorderedEquals([
          Familia(id: '22', surname: 'Paez'),
          Familia(id: '12', surname: 'Brunez'),
        ]),
        isLoading: isFalse);

    container.read(responseProvider.notifier).state =
        TestResponse.json('''[{ "id": "22", "surname": "Paez" }]''');

    notifier.reload();

    await tester.expectDataState(
        unorderedEquals([Familia(id: '22', surname: 'Paez')]),
        isLoading: isFalse);
  });

  test('watchAllNotifier with multiple model updates', () async {
    final notifier = container.people.watchAllNotifier();
    final tester = notifier.tester();

    final matcher = predicate((p) {
      return p is Person && p.name.startsWith('Number') && p.age! < 19;
    });

    for (var j = 0; j < 100; j++) {
      final id =
          Random().nextBool() ? Random().nextInt(999999999).toString() : null;
      final person = Person.generate(withId: id).saveLocal();

      await tester.expectDataState(List.generate(j + 1, (_) => matcher));
      expect(container.people.countLocal, j + 1);

      // in the last cycle, delete last Person too
      if (j == 99) {
        person.deleteLocal();
        expect(container.people.countLocal, j);
      }
    }
  });

  test('watchAllNotifier and watchAll updates and removals', () async {
    final p1 = Person(id: '1', name: 'Zof', age: 23).saveLocal();
    final notifier = container.people.watchAllNotifier();
    final tester = notifier.tester(fireImmediately: true);

    await tester.expectDataState([p1]);

    final p2 = Person(id: '1', name: 'Zofie', age: 23).saveLocal();

    await tester.expectDataState([p2]);

    // non saved models won't show up thru watchAllNotifier
    Person(id: '1', name: 'Zofien', age: 23);

    expect(container.people.watchAll(), DataState<List<Person>>([p2]));

    await container.people.clearLocal();
    await tester.expectDataState(isEmpty);

    expect(container.people.watchAll(), DataState<List<Person>>([]));
  });

  test('watchAllNotifier with where/map', () async {
    Person(id: '1', name: 'Zof', age: 23).saveLocal();
    Person(id: '2', name: 'Sarah', age: 50).saveLocal();
    Person(id: '3', name: 'Walter', age: 11).saveLocal();
    Person(id: '4', name: 'Koen', age: 92).saveLocal();

    final notifier = container.people
        .watchAllNotifier()
        .where((p) => p.age! < 40)
        .map((p) => Person(name: p.name, age: p.age! + 10));
    final tester = notifier.tester(fireImmediately: true);

    await tester.expectDataState(unorderedEquals(
        [Person(name: 'Zof', age: 33), Person(name: 'Walter', age: 21)]));
  });

  test('watchAllNotifier with multiple models and logger',
      overridePrint(() async {
    final notifier = container.houses.watchAllNotifier();
    final tester = notifier.tester();

    container.houses.logLevel = 2;
    container.houses
        .saveManyLocal(List.generate(5, (i) => House(address: '$i Main St')));

    await tester.expectDataState(hasLength(5));

    var regexp =
        RegExp(r'^\d{2}:\d{3} \[watchAll\/houses@[0-9]{10}\] updated models');
    expect(logging.first, matches(regexp));
    container.houses.logLevel = 0;
  }));

  test('watchOneNotifier and watchOne', () async {
    final tester = container.people.watchOneNotifier('1').tester();

    Person(id: '1', name: 'Frank', age: 30).saveLocal();
    await tester.expectDataState([((m) => m.name, 'Frank')]);

    container.people.saveLocal(Person(id: '1', name: 'Steve-O', age: 34));
    await tester.expectDataState([((m) => m.name, 'Steve-O')]);

    container.people.saveLocal(Person(id: '1', name: 'Liam', age: 36));
    await tester.expectDataState([((m) => m.name, 'Liam')]);

    // a different ID doesn't trigger
    container.people.saveLocal(Person(id: '2', name: 'Jupiter', age: 3));

    expect(container.people.findOneLocalById('1'),
        Person(id: '1', name: 'Liam', age: 36));

    // if local storage is cleared then it should update to null
    container.people.clearLocal();
    await tester.expectDataState(null);

    expect(await container.people.findAll(remote: false), isEmpty);
  });

  test('watchOneNotifier reads latest version', () async {
    Person(id: '345', name: 'Frank', age: 30).saveLocal();
    Person(id: '345', name: 'Steve-O', age: 34).saveLocal();

    final notifier = container.people.watchOneNotifier('345');
    expect(notifier.state.model!.name, 'Steve-O');
  });

  test('watchOneNotifier with custom finder', () async {
    // save a book in local storage, so we can later link it to the author
    final author =
        BookAuthor(id: 1, name: 'Robert', books: HasMany()).saveLocal();
    Book(
            id: 1,
            title: 'Choice',
            originalAuthor: author.asBelongsTo,
            ardentSupporters: HasMany())
        .saveLocal();

    // update the author
    container.read(responseProvider.notifier).state = TestResponse.json('''
        { "id": 1, "name": "Frank" }
      ''');
    final tester = container.bookAuthors
        .watchOneNotifier(1, remote: true, finder: 'caps')
        .tester();
    await tester.expectDataState([((m) => m.name, 'FRANK')]);
  });

  test('watchOneNotifier with alsoWatch relationships remote=false', () async {
    final f1 = Familia(
      id: '22',
      surname: 'Abagnale',
      persons: HasMany(),
      residence: BelongsTo(),
      cottage: BelongsTo(),
    ).saveLocal();

    final notifier = container.familia.watchOneNotifier(
      '22',
      alsoWatch: (familia) => {familia.persons, familia.residence},
    );
    final tester = notifier.tester();

    final p1 = Person(id: '1', name: 'Frank', age: 16).saveLocal();
    p1.familia.value = f1;

    await tester.expectDataState([((m) => m.persons, hasLength(1))]);

    f1.persons.add(Person(name: 'Martin', age: 44).saveLocal());

    await tester.expectDataState([((m) => m.persons, hasLength(2))]);

    f1.residence.value = House(address: '123 Main St').saveLocal();

    await tester
        .expectDataState([((m) => m.residence!.value!.address, '123 Main St')]);

    f1.persons.remove(p1);

    await tester.expectDataState([((m) => m.persons, hasLength(1))]);

    // a non-watched relationship does not trigger
    f1.cottage.value = House(address: '7342 Mountain Rd').saveLocal();

    await f1.delete();

    await tester.expectDataState(null);
  });

  test('watchOneNotifier without ID and nested alsoWatch', () async {
    final peter = Person(name: 'Peter', age: 30).saveLocal();

    final notifier = container.people.watchOneNotifier(
      peter,
      alsoWatch: (p) => {
        p, // also tests self (`p`, which is ignored)
        p.familia,
        p.familia.cottage,
        p.familia.cottage.currentLibrary
            .ardentSupporters, // and arbitrary relationship paths
      },
    );
    final tester = notifier.tester(fireImmediately: true);

    await tester.expectDataState(peter);

    final cottage = House(
        id: '32769', address: '32769 Winding Road', currentLibrary: HasMany());

    final familia = Familia(
      surname: 'Marquez',
      cottage: cottage.asBelongsTo,
    ).saveLocal();
    peter.familia.value = familia;
    await tester.expectDataState(peter);

    Familia(id: 'f2', surname: 'Thomson', cottage: cottage.asBelongsTo)
        .saveLocal();

    await tester.expectDataState(peter);

    House(id: '32769', address: '8 Hill St').saveLocal();
    await tester.expectDataState(peter);

    Familia(id: 'f2', surname: 'Thomson', cottage: BelongsTo.remove())
        .saveLocal();
    await tester.expectDataState(peter);

    final book = Book(id: 2, ardentSupporters: HasMany());
    cottage
      ..currentLibrary!.add(book)
      ..saveLocal();
    await tester.expectDataState(peter);

    book.ardentSupporters.add(Person(name: 'Frank'));
    await tester.expectDataState(peter);
  });

  test('watchOneNotifier with where/map', () async {
    Person(id: '1', name: 'Zof', age: 23).saveLocal();

    final notifier = container.people
        .watchOneNotifier('1')
        .map((p) => Person(name: p!.name, age: p.age! + 10))
        .where((p) => p!.age! < 40);
    final tester = notifier.tester(fireImmediately: true);
    await tester.expectDataState(Person(name: 'Zof', age: 33));

    Person(id: '1', name: 'Zof', age: 71).saveLocal();

    // since 71 + 10 > 40, the listener will receive a null
    await tester.expectDataState(null);
  });

  test('should be able to watch, dispose and watch again', () async {
    final notifier = container.people.watchAllNotifier();
    var dispose = notifier.addListener((_) {});
    dispose();
    final notifier2 = container.people.watchAllNotifier();
    dispose = notifier2.addListener((_) {});
    dispose();
  });

  test('save with error', () async {
    container.read(responseProvider.notifier).state =
        TestResponse.json('@**&#*#&');

    // overrides error handling with notifier
    final notifier = container.familia.watchAllNotifier();
    final tester = notifier.tester(fireImmediately: true);
    await tester.expectDataState([], isLoading: false);

    await container.familia.save(
      Familia(id: '1', surname: 'Smith'),
      onError: (e, _, __) async {
        expect(e.error, isA<FormatException>());
        return null;
      },
    );
  });

  test('notifier equality', () async {
    final bookAuthor =
        BookAuthor(id: 1, name: 'Billy', books: HasMany()).saveLocal();

    final defaultNotifier = container.bookAuthors.watchOneNotifier(1);

    final capsNotifier = container.read(container.bookAuthors
        .watchOneProviderById(bookAuthor, finder: 'caps')
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
    final pn1 =
        container.read(container.people.watchOneProviderById(p).notifier);
    final pn1b = container.people.watchOneNotifier(p);
    final pn2 = container.people.watchOneNotifier(p2);
    expect(pn1, equals(pn1b));
    expect(pn1, isNot(pn2));

    // all
    final apn1 = container.read(container.people.watchAllProvider().notifier);
    final apn2 = container.people.watchAllNotifier();
    expect(apn1, equals(apn2));

    final state = container.bookAuthors.watchOne(1);
    expect(state.model!, bookAuthor);

    final model = container.bookAuthors.watch(bookAuthor);
    expect(model, bookAuthor);
  });

  test('notifier for', () async {
    // notifierFor (obtainer notifier for local watcher)
    final book = Book(id: 1, ardentSupporters: HasMany()).saveLocal();
    final notifier = container.books.notifierFor(book);
    // should be the same as calling watchOneNotifier(model, remote: false)
    expect(notifier, container.books.watchOneNotifier(book, remote: false));

    // try reloading, because why not
    await notifier.reload();
    expect(notifier.data.model, book.reloadLocal());
  });

  test('watchargs', () {
    final a1 = WatchArgs<Person>(
        key: 'e23f44',
        remote: false,
        alsoWatch: (p) => {p.familia}, // is ignored
        relationshipMetas: [],
        finder: 'finder');

    final a2 = WatchArgs<Person>(
      key: 'e23f44',
      remote: false,
      finder: 'finder',
      relationshipMetas: [],
    );
    expect(a1, a2);
  });
}
