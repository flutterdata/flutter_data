import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  RemoteAdapter<Family> familyRepo;
  RemoteAdapter<Person> personRepo;
  RemoteAdapter<House> houseRepo;
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  setUp(() {
    familyRepo =
        injection.locator<Repository<Family>>() as RemoteAdapter<Family>;
    familyRepo.box.clear();
    expect(familyRepo.box.keys, isEmpty);
    personRepo =
        injection.locator<Repository<Person>>() as RemoteAdapter<Person>;
    personRepo.box.clear();
    expect(personRepo.box.keys, isEmpty);
    houseRepo = injection.locator<Repository<House>>() as RemoteAdapter<House>;
    houseRepo.box.clear();
    expect(houseRepo.box.keys, isEmpty);
    houseRepo.manager.graph.clear();
  });

  test('scenario #1', () {
    // house does not yet exist
    final residenceKey = manager.getKeyForId('houses', '1',
        keyIfAbsent: Repository.generateKey<House>());

    final f1 = familyRepo
        .deserialize({'id': '1', 'surname': 'Rose', 'residence': residenceKey});
    expect(f1.residence.value, isNull);
    expect(keyFor(f1), isNotNull);

    // once it does
    final house = House(id: '1', address: '123 Main St').init(manager);
    // it's automatically wired up
    expect(f1.residence.value, house);
    expect(f1.residence.value.owner.value, f1);
    expect(house.owner.value, f1);

    // residence is omitted, but persons is included (no people exist yet)
    final personKey =
        manager.getKeyForId('people', '1', keyIfAbsent: 'people#a1a1a1');
    final f1b = familyRepo.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [personKey]
    });
    // therefore
    // residence remains wired
    expect(f1b.residence.value, house);
    // persons is empty since no people exist yet (despite having keys)
    expect(f1b.persons, isEmpty);

    // once p1 exists
    final p1 = Person(id: '1', name: 'Axl', age: 58).init(manager);
    // it's automatically wired up
    expect(f1b.persons, {p1});

    // relationships are omitted - so they remain unchanged
    final f1c = familyRepo.deserialize({'id': '1', 'surname': 'Rose'});
    expect(f1c.persons, {p1});
    expect(f1c.residence.value, isNotNull);

    final p2 = Person(id: '2', name: 'Brian', age: 55).init(manager);

    // persons has changed from [1] to [2]
    final f1d = familyRepo.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': [keyFor(p2)]
    });
    // persons should be exactly equal to p2 (Brian)
    expect(f1d.persons, {p2});
    // without directly modifying p2, its family should be automatically updated
    expect(p2.family.value, f1d);
    // and by the same token, p1's family should now be null
    expect(p1.family.value, isNull);

    // relationships are explicitly set to null
    final f1e = familyRepo.deserialize(
        {'id': '1', 'surname': 'Rose', 'persons': null, 'residence': null});
    expect(f1e.persons, isEmpty);
    expect(f1e.residence.value, isNull);

    expect(keyFor(f1), equals(keyFor(f1e)));
  });

  test('scenario #1b (inverse)', () {
    final h1 = houseRepo.deserialize(
        {'id': '1', 'address': '123 Main St', 'owner': 'families#a1a1a1'});
    expect(h1.owner.value, isNull);
    expect(keyFor(h1), isNotNull);

    manager.getKeyForId('family', '1', keyIfAbsent: 'families#a1a1a1');

    // once it does
    final family =
        Family(id: '1', surname: 'Rose', residence: BelongsTo()).init(manager);
    // it's automatically wired up & inverses work correctly
    expect(h1.owner.value, family);
    expect(h1.owner.value.residence.value, h1);
  });

  test('scenario #2', () {
    final personRepo = injection.locator<Repository<Person>>();

    // (1) first load family (with relationships)
    final family = Family(
      id: '1',
      surname: 'Jones',
      persons: HasMany.fromJson({
        '_': [
          ['people#c1c1c1', 'people#c2c2c2', 'people#c3c3c3'],
          false,
          personRepo.manager
        ]
      }),
      residence: BelongsTo.fromJson({
        '_': ['houses#c98d1b', false, personRepo.manager]
      }),
    ).init(manager);

    expect(family.residence.key, isNotNull);
    expect(family.persons.keys.length, 3);

    // associate ids with keys
    manager.getKeyForId('people', '1', keyIfAbsent: 'people#c1c1c1');
    manager.getKeyForId('people', '2', keyIfAbsent: 'people#c2c2c2');
    manager.getKeyForId('people', '3', keyIfAbsent: 'people#c3c3c3');
    manager.getKeyForId('houses', '98', keyIfAbsent: 'houses#c98d1b');

    // (2) then load persons

    final p1 = Person(id: '1', name: 'z1', age: 23).init(manager);
    Person(id: '2', name: 'z2', age: 33).init(manager);

    // (3) assert two first are linked, third one null, residence is null
    expect(family.persons.lookup(p1), p1);
    expect(family.persons.elementAt(0), isNotNull);
    expect(family.persons.elementAt(1), isNotNull);
    expect(family.persons.length, 2);
    expect(family.residence.value, isNull);

    // (4) load the last person and assert it exists now
    final p3 = Person(id: '3', name: 'z3', age: 3).init(manager);
    expect(family.persons.lookup(p3), isNotNull);
    expect(p3.family.value, family);

    // (5) load family and assert it exists now
    final house = House(id: '98', address: '21 Coconut Trail').init(manager);
    expect(house.owner.value, family);
    expect(family.residence.value.address, endsWith('Trail'));
    expect(house.owner.value, family); // same, passes here again
  });

  test('scenario #3', () {
    final igor = Person(name: 'Igor', age: 33).init(manager);
    final f1 =
        Family(surname: 'Kamchatka', persons: {igor}.asHasMany).init(manager);
    expect(f1.persons.first.family.value, f1);

    final igor1b =
        Person(name: 'Igor', age: 33, family: BelongsTo()).init(manager);

    final f1b =
        Family(surname: 'Kamchatka', persons: {igor1b}.asHasMany).init(manager);
    expect(f1b.persons.first.family.value.surname, 'Kamchatka');

    final f2 = Family(surname: 'Kamchatka', persons: HasMany()).init(manager);
    final igor2 =
        Person(name: 'Igor', age: 33, family: BelongsTo()).init(manager);
    f2.persons.add(igor2);
    expect(f2.persons.first.family.value.surname, 'Kamchatka');

    f2.persons.remove(igor2);
    expect(f2.persons, isEmpty);

    final residence = House(address: 'Sakharova Prospekt, 19').init(manager);
    final f3 = Family(surname: 'Kamchatka', residence: residence.asBelongsTo)
        .init(manager);
    expect(f3.residence.value.owner.value.surname, 'Kamchatka');
    f3.residence.value = null;
    expect(f3.residence.value, isNull);

    final f4 =
        Family(surname: 'Kamchatka', residence: BelongsTo()).init(manager);
    f4.residence.value = House(address: 'Sakharova Prospekt, 19').init(manager);
    expect(f4.residence.value.owner.value.surname, 'Kamchatka');
  });

  test('one-way relationships', () {
    // relationships that don't have an inverse
    final jerry = Dog(name: 'Jerry').init(manager);
    final zoe = Dog(name: 'Zoe').init(manager);
    final f1 =
        Family(surname: 'Carlson', dogs: {jerry, zoe}.asHasMany).init(manager);
    expect(f1.dogs, {jerry, zoe});
  });
}
