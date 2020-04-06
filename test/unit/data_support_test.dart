import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('throws if not initialized', () {
    expect(() {
      Family(surname: "Willis").dataId;
    }, throwsA(isA<AssertionError>()));
  });

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: "Frank", age: 20).init(repository);
    expect(repository.localAdapter.box.keys.length, 1);

    // person with new id, reusing existing key
    manager.dataId<Person>('221', key: p1.key);
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(p1.key, p2.key);

    expect(repository.localAdapter.box.keys.length, 1);

    // another person, without reusing key
    Person(id: '222', name: 'Frank3', age: 76).init(repository);
    expect(repository.localAdapter.box.keys.length, 2);
  });

  // misc compatibility tests

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: "Frank", age: 20).init(repository);
    expect(repository.localAdapter.box.keys.length, 1);

    // person with new id, reusing existing key
    manager.dataId<Person>('221', key: p1.key);
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(p1.key, p2.key);

    expect(repository.localAdapter.box.keys.length, 1);

    // another person, without reusing key
    Person(id: '222', name: 'Frank3', age: 76).init(repository);
    expect(repository.localAdapter.box.keys.length, 2);
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

    // (2) then load persons
    Person(id: '1', name: 'z1', age: 23).init(personRepo).save(remote: false);
    Person(id: '2', name: 'z2', age: 33).init(personRepo).save(remote: false);

    // (3) assert two first are linked, third one null, house is null
    expect(family.persons[0], isNotNull);
    expect(family.persons[1], isNotNull);
    expect(family.persons[2], isNull);
    expect(family.house.value, isNull);

    // (4) load the last person and assert it exists now
    Person(id: '3', name: 'z3', age: 3).init(personRepo).save(remote: false);
    var house = House(id: '98', address: "21 Coconut Trail").init(houseRepo);

    expect(family.persons[2].age, 3);
    expect(family.house.value.address, endsWith('Trail'));

    // (5) TO-DO
    expect(house.families.length, 0);
  });
}
