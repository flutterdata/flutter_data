import 'package:flutter_data/flutter_data.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../_support/book.dart';
import '../../_support/family.dart';
import '../../_support/house.dart';
import '../../_support/person.dart';
import '../../_support/setup.dart';
import '../../mocks.dart';

void main() async {
  setUp(setUpFn);
  tearDown(tearDownFn);

  test('set owner in relationships (before & after init)', () {
    final person = Person(id: '1', name: 'John', age: 37);
    final house = House(id: '31', address: '123 Main St');
    final house2 = House(id: '2', address: '456 Main St');

    final family = Family(
        id: '1',
        surname: 'Smith',
        residence: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // values are there even if family (and its relationships) are not init'd
    expect(family.residence!.value, house);
    expect(family.persons.toSet(), {person});
    expect(family.persons, equals(family.persons));

    family.init(container.read);

    // after init, values remain the same
    expect(family.residence!.value, house);
    expect(family.persons.toSet(), {person});
    expect(family.persons, equals(family.persons));

    // relationships are now associated to a key
    expect(family.residence!.key, isNotNull);
    expect(family.residence!.key, graph.getKeyForId('houses', '31'));
    expect(family.residence!.id, '31');
    expect(family.persons.keys.first, isNotNull);
    expect(family.persons.keys.first, graph.getKeyForId('people', '1'));

    // ensure there are not more than 1 key
    family.residence!.value = house2;
    expect(family.residence!.keys, hasLength(1));
    expect(family.residence!.id, '2');
  });

  test('assignment with relationship initialized & uninitialized', () {
    final family =
        Family(id: '1', surname: 'Smith', residence: BelongsTo<House>());
    final house = House(id: '1', address: '456 Lemon Rd');

    family.residence!.value = house;
    expect(family.residence!.value, house);

    family.init(container.read);
    family.residence!.value = house; // assigning again shouldn't affect
    expect(family.residence!.value, house);
  });

  test('use fromJson constructor without initialization', () {
    // internal format
    final person = BelongsTo<Person>.fromJson({
      '_': [
        'k1',
        false,
      ]
    });
    expect(person.key, 'k1');
    expect(person.value, isNull);
  });

  test('watch', () async {
    final family = Family(
      id: '22',
      surname: 'Besson',
      residence: BelongsTo<House>(),
    ).init(container.read);

    final notifier = family.residence!.watch();
    final listener = Listener<House?>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    family.residence!.value = House(id: '2', address: '456 Main St');
    await oneMs();

    verify(listener(argThat(
      isA<House>().having((h) => h.address, 'address', startsWith('456')),
    ))).called(1);

    family.residence!.value = House(id: '1', address: '123 Main St');
    await oneMs();

    verify(listener(argThat(
      isA<House>().having((h) => h.address, 'address', startsWith('123')),
    ))).called(1);

    family.residence!.value = null;
    await oneMs();

    verify(listener(argThat(isNull))).called(1);
  });

  test('inverses work when reusing a relationship', () {
    final person = Person(name: 'Cecil', age: 2).init(container.read);
    final house =
        House(id: '1', address: '21 Coconut Trail').init(container.read);
    final family = Family(
            id: '2',
            surname: 'Raoult',
            residence: house.asBelongsTo,
            persons: {person}.asHasMany)
        .init(container.read);

    // reusing a BelongsTo<Family> (`house.owner`) to add a person
    // adds the inverse relationship
    expect(family.persons.length, 1);
    Person(name: 'Junior', age: 12, family: house.owner).init(container.read);
    expect(family.persons.length, 2);

    // an empty reused relationship should not fail
    final house2 =
        House(id: '17', address: '798 Birkham Rd', owner: BelongsTo<Family>())
            .init(container.read);

    // trying to add walter to a null family does nothing
    Person(name: 'Walter', age: 55, family: house2.owner).init(container.read);

    expect(family.persons.length, 2);
  });

  test('remove relationship', () async {
    final a1 = BookAuthor(id: 1, name: 'Walter').init(container.read);
    await a1.save();
    final b1 = Book(id: 1, originalAuthor: a1.asBelongsTo).init(container.read);
    await b1.save();

    final b2 = b1.copyWith(originalAuthor: BelongsTo.remove()).was(b1);
    await b2.save();
    expect(b2.originalAuthor!.value, isNull);
    expect(b1.originalAuthor!.value, isNull);
  });
}
