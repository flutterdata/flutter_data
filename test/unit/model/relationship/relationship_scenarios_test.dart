import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../../models/family.dart';
import '../../../models/house.dart';
import '../../../models/person.dart';
import '../../../models/pet.dart';
import '../../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);
  setUp(setUpFn);

  test('scenario #1', () {
    // house does not yet exist
    final residenceKey = manager.getKeyForId('houses', '1',
        keyIfAbsent: Repository.generateKey<House>());

    final f1 = familyRepository.localDeserialize({
      'id': '1',
      'surname': 'Rose',
      'residence': residenceKey
    }).init(manager: manager);
    expect(f1.residence.value, isNull);
    expect(keyFor(f1), isNotNull);

    // once it does
    final house = House(id: '1', address: '123 Main St').init(manager: manager);
    // it's automatically wired up
    expect(f1.residence.value, house);
    expect(f1.residence.value.owner.value, f1);
    expect(house.owner.value, f1);

    // residence is omitted, but persons is included (no people exist yet)
    final personKey =
        manager.getKeyForId('people', '1', keyIfAbsent: 'people#a1a1a1');
    final f1b = familyRepository.localDeserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [personKey],
    }).init(manager: manager);
    // therefore
    // residence remains wired
    expect(f1b.residence.value, house);
    // persons is empty since no people exist yet (despite having keys)
    expect(f1b.persons, isEmpty);

    // once p1 exists
    final p1 = Person(id: '1', name: 'Axl', age: 58).init(manager: manager);
    // it's automatically wired up
    expect(f1b.persons, {p1});

    // relationships are omitted - so they remain unchanged
    final f1c = familyRepository.localDeserialize(
        {'id': '1', 'surname': 'Rose'}).init(manager: manager);
    expect(f1c.persons, {p1});
    expect(f1c.residence.value, isNotNull);

    final p2 = Person(id: '2', name: 'Brian', age: 55).init(manager: manager);

    // persons has changed from [1] to [2]
    final f1d = familyRepository.localDeserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [keyFor(p2)]
    }).init(manager: manager);
    // persons should be exactly equal to p2 (Brian)
    expect(f1d.persons, {p2});
    // without directly modifying p2, its family should be automatically updated
    expect(p2.family.value, f1d);
    // and by the same token, p1's family should now be null
    expect(p1.family.value, isNull);

    // relationships are explicitly set to null
    final f1e = familyRepository.localDeserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': null,
      'residence': null
    }).init(manager: manager);
    expect(f1e.persons, isEmpty);
    expect(f1e.residence.value, isNull);

    expect(keyFor(f1), equals(keyFor(f1e)));
  });

  test('scenario #1b (inverse)', () {
    final h1 = houseRepository.localDeserialize({
      'id': '1',
      'address': '123 Main St',
      'owner': 'families#a1a1a1'
    }).init(manager: manager);
    expect(h1.owner.value, isNull);
    expect(keyFor(h1), isNotNull);

    manager.getKeyForId('family', '1', keyIfAbsent: 'families#a1a1a1');

    // once it does
    final family = Family(id: '1', surname: 'Rose', residence: BelongsTo())
        .init(manager: manager);
    // it's automatically wired up & inverses work correctly
    expect(h1.owner.value, family);
    expect(h1.owner.value.residence.value, h1);
  });

  test('scenario #2', () {
    // (1) first load family (with relationships)
    final family = Family(
      id: '1',
      surname: 'Jones',
      persons: HasMany.fromJson({
        '_': [
          ['people#c1c1c1', 'people#c2c2c2', 'people#c3c3c3'],
          false,
          manager
        ]
      }),
      residence: BelongsTo.fromJson({
        '_': ['houses#c98d1b', false, manager]
      }),
    ).init(manager: manager);

    expect(family.residence.key, isNotNull);
    expect(family.persons.keys.length, 3);

    // associate ids with keys
    manager.getKeyForId('people', '1', keyIfAbsent: 'people#c1c1c1');
    manager.getKeyForId('people', '2', keyIfAbsent: 'people#c2c2c2');
    manager.getKeyForId('people', '3', keyIfAbsent: 'people#c3c3c3');
    manager.getKeyForId('houses', '98', keyIfAbsent: 'houses#c98d1b');

    // (2) then load persons

    final p1 = Person(id: '1', name: 'z1', age: 23).init(manager: manager);
    Person(id: '2', name: 'z2', age: 33).init(manager: manager);

    // (3) assert two first are linked, third one null, residence is null
    expect(family.persons.lookup(p1), p1);
    expect(family.persons.elementAt(0), isNotNull);
    expect(family.persons.elementAt(1), isNotNull);
    expect(family.persons.length, 2);
    expect(family.residence.value, isNull);

    // (4) load the last person and assert it exists now
    final p3 = Person(id: '3', name: 'z3', age: 3).init(manager: manager);
    expect(family.persons.lookup(p3), isNotNull);
    expect(p3.family.value, family);

    // (5) load family and assert it exists now
    final house =
        House(id: '98', address: '21 Coconut Trail').init(manager: manager);
    expect(house.owner.value, family);
    expect(family.residence.value.address, endsWith('Trail'));
    expect(house.owner.value, family); // same, passes here again
  });

  test('scenario #3', () {
    final igor = Person(name: 'Igor', age: 33).init(manager: manager);
    final f1 = Family(surname: 'Kamchatka', persons: {igor}.asHasMany)
        .init(manager: manager);
    expect(f1.persons.first.family.value, f1);

    final igor1b = Person(name: 'Igor', age: 33, family: BelongsTo())
        .init(manager: manager);

    final f1b = Family(surname: 'Kamchatka', persons: {igor1b}.asHasMany)
        .init(manager: manager);
    expect(f1b.persons.first.family.value.surname, 'Kamchatka');

    final f2 =
        Family(surname: 'Kamchatka', persons: HasMany()).init(manager: manager);
    final igor2 = Person(name: 'Igor', age: 33, family: BelongsTo())
        .init(manager: manager);
    f2.persons.add(igor2);
    expect(f2.persons.first.family.value.surname, 'Kamchatka');

    f2.persons.remove(igor2);
    expect(f2.persons, isEmpty);

    final residence =
        House(address: 'Sakharova Prospekt, 19').init(manager: manager);
    final f3 = Family(surname: 'Kamchatka', residence: residence.asBelongsTo)
        .init(manager: manager);
    expect(f3.residence.value.owner.value.surname, 'Kamchatka');
    f3.residence.value = null;
    expect(f3.residence.value, isNull);

    final f4 = Family(surname: 'Kamchatka', residence: BelongsTo())
        .init(manager: manager);
    f4.residence.value =
        House(address: 'Sakharova Prospekt, 19').init(manager: manager);
    expect(f4.residence.value.owner.value.surname, 'Kamchatka');
  });

  test('scenario #4: maintain relationship reference validity', () {
    final brian = Person(name: 'Brian', age: 52).init(manager: manager);
    final family =
        Family(id: '229', surname: 'Rose', persons: {brian}.asHasMany)
            .init(manager: manager);
    expect(family.persons.length, 1);

    // new family comes in locally with no persons relationship info
    final family2 = Family(id: '229', surname: 'Rose', persons: HasMany())
        .init(manager: manager);
    // it should keep the relationships unaltered
    expect(family2.persons.length, 1);

    // new family comes in from API (simulate) with no persons relationship info
    final family3 =
        familyRepository.deserialize({'id': '229', 'surname': 'Rose'}).model;
    // it should keep the relationships unaltered
    expect(family3.persons.length, 1);

    // new family comes in from API (simulate) with empty persons relationship
    final family4 = familyRepository
        .deserialize({'id': '229', 'surname': 'Rose', 'persons': []}).model;
    // it should keep the relationships unaltered
    expect(family4.persons.length, 0);

    final family5 = familyRepository.localDeserialize({
      'id': '229',
      'surname': 'Rose',
      'persons': ['people#231aaa']
    }).init(manager: manager);

    manager.getKeyForId('people', '231', keyIfAbsent: 'people#231aaa');
    final axl = Person(id: '231', name: 'Axl', age: 58).init(manager: manager);
    expect(family5.persons, {axl});
  });

  test('scenario #5: one-way relationships', () {
    // relationships that don't have an inverse
    final jerry = Dog(name: 'Jerry').init(manager: manager);
    final zoe = Dog(name: 'Zoe').init(manager: manager);
    final f1 = Family(surname: 'Carlson', dogs: {jerry, zoe}.asHasMany)
        .init(manager: manager);
    expect(f1.dogs, {jerry, zoe});
  });
}
