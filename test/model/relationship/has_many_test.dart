import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../_support/book.dart';
import '../../_support/familia.dart';
import '../../_support/house.dart';
import '../../_support/person.dart';
import '../../_support/setup.dart';
import '../../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('ids + toString', () {
    final f1 = Familia(surname: 'Sanchez');
    final p1 = Person(name: 'Javier');
    f1.persons.add(p1);
    f1.persons.add(Person(id: '1', name: 'Manuel'));
    f1.persons.add(Person(id: '2', name: 'Carlos'));

    expect(f1.persons.ids, {'1', '2'});
    expect(f1.persons.toString(), 'HasMany<Person>(1, 2, [${keyFor(p1)}])');
  });

  test('behaves like a collection', () {
    final pete = Person(name: 'Pete', age: 29).saveLocal();
    final anne = Person(name: 'Anne', age: 59).saveLocal();
    final residence = House(address: '1322 Hill Rd').saveLocal();
    final f2 = Familia(
      surname: 'Sumberg',
      persons: {pete}.asHasMany,
      cottage: BelongsTo(),
      residence: residence.asBelongsTo,
    );

    f2.persons.add(pete);
    f2.persons.add(pete);
    expect(f2.persons.length, 1);

    f2.persons.add(anne);
    expect(f2.persons.length, 2);

    f2.persons.remove(anne);
    expect(f2.persons.toSet(), {pete});

    expect(DataModel.relationshipsFor(f2).values,
        unorderedEquals([f2.persons, f2.residence, f2.cottage]));
    expect(DataModel.relationshipsFor(f2).values.whereType<HasMany>(),
        [f2.persons]);
  });

  test('assignment with relationship initialized & uninitialized', () {
    final familia =
        Familia(id: '1', surname: 'Smith', persons: HasMany()).saveLocal();
    final person = Person(id: '1', name: 'Flavio', age: 12).saveLocal();

    familia.persons.add(person);
    expect(familia.persons.contains(person), isTrue);

    familia.persons.add(person);
    expect(familia.persons.contains(person), isTrue);
  });

  test('watch', () async {
    final familia = Familia(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).saveLocal();

    final notifier = container.watch(familia.persons.watchProvider.notifier);
    final listener = Listener<Set<Person>>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    final p1 = Person(name: 'a', age: 1).saveLocal();
    final p2 = Person(name: 'b', age: 2).saveLocal();

    familia.persons.add(p1);
    await oneMs();

    verify(listener({p1})).called(1);

    familia.persons.add(p2);
    await oneMs();

    verify(listener({p1, p2})).called(1);

    familia.persons.add(p2);
    await oneMs();

    // doesn't show up as p2 was already present!
    verifyNever(listener({p1, p2}));

    familia.persons.remove(p1);
    await oneMs();

    verify(listener({p2})).called(1);

    familia.persons.add(p1);
    await oneMs();

    verify(listener({p1, p2})).called(1);

    final p3 =
        Person(name: 'c', age: 3, familia: familia.asBelongsTo).saveLocal();
    await oneMs();

    verify(listener({p1, p2, p3})).called(1);
  });

  test('remove relationship', () async {
    final b1 = Book(id: 1, ardentSupporters: HasMany());
    await b1.save();

    final a1 = BookAuthor(id: 1, name: 'Walter', books: {b1}.asHasMany);
    await a1.save();

    final a2 = a1.copyWith(books: HasMany.remove());
    await a2.save();
    expect(a2.books.toSet(), <Book>{});
    expect(a1.books.toSet(), <Book>{});
  });
}
