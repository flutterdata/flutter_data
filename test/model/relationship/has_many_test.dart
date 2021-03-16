import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../_support/family.dart';
import '../../_support/person.dart';
import '../../_support/setup.dart';
import '../../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('behaves like a collection (without init/models)', () {
    final anne = Person(name: 'Anne', age: 59);
    final f1 = Family(surname: 'Mayer', persons: {anne}.asHasMany);

    f1.persons.add(anne);
    f1.persons.add(anne);
    expect(f1.persons.length, 1);

    final agnes = Person(name: 'Agnes', age: 29);
    f1.persons.add(agnes);
    expect(f1.persons.length, 2);

    f1.persons.remove(anne);
    expect(f1.persons.toSet(), {agnes});
    f1.persons.add(null);
    expect(f1.persons.toSet(), {agnes});
  });

  test('behaves like a collection (with init)', () {
    final pete = Person(name: 'Pete', age: 29);
    final anne = Person(name: 'Anne', age: 59);
    final f2 =
        Family(surname: 'Sumberg', persons: {pete}.asHasMany).init(container);

    f2.persons.add(pete);
    f2.persons.add(pete);
    expect(f2.persons.length, 1);

    f2.persons.add(anne);
    expect(f2.persons.length, 2);

    f2.persons.remove(anne);
    expect(f2.persons.toSet(), {pete});
    f2.persons.add(null);
    expect(f2.persons.toSet(), {pete});
  });

  test('assignment with relationship initialized & uninitialized', () {
    final family = Family(id: '1', surname: 'Smith', persons: HasMany());
    final person = Person(id: '1', name: 'Flavio', age: 12);

    family.persons.add(person);
    expect(family.persons.contains(person), isTrue);

    family.init(container);

    family.persons.add(person);
    expect(family.persons.contains(person), isTrue);
  });

  test('use fromJson constructor without initialization', () {
    // internal format
    final persons = HasMany<Person>.fromJson({
      '_': [
        ['k1', 'k2'],
        false,
      ]
    });
    expect(persons.keys, {'k1', 'k2'});
    expect(persons, isEmpty);
  });

  test('watch', () async {
    final family = Family(
      id: '1',
      surname: 'Smith',
      persons: HasMany<Person>(),
    ).init(container);

    final p1 = Person(name: 'a', age: 1);
    final p2 = Person(name: 'b', age: 2);
    final notifier = family.persons.watch();

    final listener = Listener<Set<Person>>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    family.persons.add(p1);
    await oneMs();

    verify(listener({p1})).called(1);

    family.persons.add(p2);
    await oneMs();

    verify(listener({p1, p2})).called(1);

    family.persons.add(p2);
    await oneMs();

    // doesn't show up as p2 was already present!
    verifyNever(listener({p1, p2}));

    family.persons.remove(p1);
    await oneMs();

    verify(listener({p2})).called(1);

    family.persons.add(p1);
    await oneMs();

    verify(listener({p1, p2})).called(1);
  });
}
