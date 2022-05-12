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

  test('id + toString', () {
    final person = Person(name: 'Test', familia: BelongsTo());
    person.familia.value = Familia(id: '1', surname: 'Sanchez');
    expect(person.familia.value!.id, person.familia.id);
    expect(person.familia.toString(), 'BelongsTo<Familia>(1)');
  });

  test('set owner in relationships (before & after init)', () {
    final person = Person(id: '1', name: 'John', age: 37);
    final house = House(id: '31', address: '123 Main St');
    final house2 = House(id: '2', address: '456 Main St');

    final familia = Familia(
        id: '1',
        surname: 'Smith',
        residence: BelongsTo<House>(house),
        persons: HasMany<Person>({person}));

    // values are there even if familia (and its relationships) are not init'd
    expect(familia.residence.value, house);
    expect(familia.persons.toSet(), {person});
    expect(familia.persons, equals(familia.persons));

    // after init, values remain the same
    expect(familia.residence.value, house);
    expect(familia.persons.toSet(), {person});
    expect(familia.persons, equals(familia.persons));

    // relationships are now associated to a key
    expect(familia.residence.key, isNotNull);
    expect(familia.residence.key, graph.getKeyForId('houses', '31'));
    expect(familia.residence.id, '31');
    expect(familia.persons.keys.first, isNotNull);
    expect(familia.persons.keys.first, graph.getKeyForId('people', '1'));

    // ensure there are not more than 1 key
    familia.residence.value = house2;
    expect(familia.residence.keys, hasLength(1));
    expect(familia.residence.id, '2');
  });

  test('assignment with relationship initialized & uninitialized', () {
    final familia =
        Familia(id: '1', surname: 'Smith', residence: BelongsTo<House>());
    final house = House(id: '1', address: '456 Lemon Rd');

    familia.residence.value = house;
    expect(familia.residence.value, house);

    familia.residence.value = house; // assigning again shouldn't affect
    expect(familia.residence.value, house);
  });

  test('watch', () async {
    final familia = Familia(
      id: '22',
      surname: 'Besson',
      residence: BelongsTo<House>(),
    );

    final notifier = familia.residence.watch();
    final listener = Listener<House?>();
    dispose = notifier.addListener(listener, fireImmediately: false);

    familia.residence.value = House(id: '2', address: '456 Main St');

    verify(listener(argThat(
      isA<House>().having((h) => h.address, 'address', startsWith('456')),
    ))).called(1);

    familia.residence.value = House(id: '1', address: '123 Main St');

    verify(listener(argThat(
      isA<House>().having((h) => h.address, 'address', startsWith('123')),
    ))).called(1);

    familia.residence.value = null;

    verify(listener(argThat(isNull))).called(1);
    verifyNoMoreInteractions(listener);
  });

  test('inverses work when reusing a relationship', () {
    final person = Person(name: 'Cecil', age: 2);
    final house = House(id: '1', address: '21 Coconut Trail');
    final familia = Familia(
      id: '2',
      surname: 'Raoult',
      residence: house.asBelongsTo,
      persons: {person}.asHasMany,
    );

    // adds the inverse relationship
    expect(familia.persons.length, 1);
    Person(name: 'Junior', age: 12, familia: house.owner.value!.asBelongsTo);
    expect(familia.persons.length, 2);

    // an empty reused relationship should not fail
    final house2 =
        House(id: '17', address: '798 Birkham Rd', owner: BelongsTo<Familia>());

    // trying to add walter to a null familia does nothing
    Person(name: 'Walter', age: 55, familia: house2.owner.value?.asBelongsTo);

    expect(familia.persons.length, 2);
  });

  test('remove relationship', () async {
    final a1 = BookAuthor(id: 1, name: 'Walter', books: HasMany());
    await a1.save();
    final b1 = Book(
        id: 1, originalAuthor: a1.asBelongsTo, ardentSupporters: HasMany());
    await b1.save();

    final b2 = b1.copyWith(originalAuthor: BelongsTo.remove());
    await b2.save();
    expect(b2.originalAuthor!.isPresent, isFalse);
    expect(b1.originalAuthor!.isPresent, isFalse);
  });

  test('self ref', () {
    final house = House(address: '22 Peak Rd');
    expect(house.house.value, house);
  });
}
