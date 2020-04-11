import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'models/pet.dart';
import 'setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('throws if not initialized', () {
    expect(() {
      return Family(surname: "Willis").save();
    }, throwsA(isA<AssertionError>()));
  });

  // misc compatibility tests

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: "Frank", age: 20).init(repository);
    expect(repository.localAdapter.box.keys, contains(p1.key));

    // person with new id, reusing existing key
    manager.dataId<Person>('221', key: p1.key);
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(p1.key, p2.key);

    expect(repository.localAdapter.box.keys, contains(p2.key));
  });

  test('should resolve to the same key', () {
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog('2', 'Walker').init(dogRepo);
    var dog2 = Dog('2', 'Walker').init(dogRepo);
    expect(dog.key, dog2.key);
  });

  test('should work with subclasses', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog('2', 'Walker').init(dogRepo);

    var f = Family(surname: 'Walker', dogs: [dog].asHasMany).init(familyRepo);
    expect(f.dogs.first.name, 'Walker');
  });

  test('relationship scenario #1', () {
    var personRepo = injection.locator<Repository<Person>>();
    var familyRepo = injection.locator<Repository<Family>>();
    var houseRepo = injection.locator<Repository<House>>();

    // (1) first load family (with relationships)
    var personDataIds = [
      personRepo.manager.dataId<Person>('1'),
      personRepo.manager.dataId<Person>('2'),
      personRepo.manager.dataId<Person>('3')
    ];
    var houseDataId = personRepo.manager.dataId<House>('98');
    var family = Family(
      id: "1",
      surname: "Jones",
      persons: HasMany.fromJson({
        '_': [personDataIds.map((d) => d.key).toList(), personRepo.manager]
      }),
      house: BelongsTo.fromJson({
        '_': [houseDataId.key, personRepo.manager]
      }),
    ).init(familyRepo);

    expect(family.house.dataId, isNotNull);
    expect(family.persons.dataIds, isNotEmpty);

    // (2) then load persons
    Person(id: '1', name: 'z1', age: 23).init(personRepo);
    Person(id: '2', name: 'z2', age: 33).init(personRepo);

    // (3) assert two first are linked, third one null, house is null
    expect(family.persons[0], isNotNull);
    expect(family.persons[1], isNotNull);
    expect(family.persons[2], isNull);
    expect(family.house.value, isNull);

    // (4) load the last person and assert it exists now
    Person(id: '3', name: 'z3', age: 3).init(personRepo);
    expect(family.persons[2].age, 3);

    // (5) load family and assert it exists now
    var house = House(id: '98', address: "21 Coconut Trail").init(houseRepo);
    // TODO should pass here too
    // expect(house.families, contains(family));
    expect(family.house.value.address, endsWith('Trail'));
    expect(house.families, contains(family));
  });

  test('relationship scenario #2', () {
    var repository = injection.locator<Repository<Family>>();

    var f1 = Family(
            surname: 'Kamchatka',
            persons: [Person(name: 'Igor', age: 33)].asHasMany)
        .init(repository);
    // if Igor's family is NULL there's no way we can expect anything else
    // this is why setting an empty default relationship is recommended
    expect(f1.persons.first.family, isNull);

    var f1b = Family(
            surname: 'Kamchatka',
            persons:
                [Person(name: 'Igor', age: 33, family: BelongsTo())].asHasMany)
        .init(repository);
    expect(f1b.persons.first.family.value.surname, 'Kamchatka');

    var f2 = Family(surname: 'Kamchatka', persons: HasMany()).init(repository);
    f2.persons.add(Person(name: 'Igor', age: 33, family: BelongsTo()));
    expect(f2.persons.first.family.value.surname, 'Kamchatka');

    var f3 = Family(
            surname: 'Kamchatka',
            house: House(address: "Sakharova Prospekt, 19").asBelongsTo)
        .init(repository);
    expect(f3.house.value.families.first.surname, 'Kamchatka');

    var f4 = Family(surname: 'Kamchatka', house: BelongsTo()).init(repository);
    f4.house.value = House(address: "Sakharova Prospekt, 19");
    expect(f4.house.value.families.first.surname, 'Kamchatka');
  });
}
