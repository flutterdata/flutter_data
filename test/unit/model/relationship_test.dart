import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
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
  });

  test('bt', () {
    // house does not yet exist
    final f1 =
        familyRepo.deserialize({'id': '1', 'surname': 'Rose', 'house': '1'});
    expect(f1.house.value, isNull);

    // once it does
    final house = House(id: '1', address: '123 Main St').init(houseRepo);
    // it's automatically wired up
    expect(f1.house.value, house);

    // house is omitted, but persons is included (no people exist yet)
    final f1b = familyRepo.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': ['1']
    });
    // house remains wired
    expect(f1b.house.value, house);

    // once p1 exists
    final p1 = Person(id: '1', name: 'Axl', age: 58).init(personRepo);
    // it's automatically wired up
    expect(f1b.persons, {p1});

    // relationships are omitted - so they remain unchanged
    final f1c = familyRepo.deserialize({'id': '1', 'surname': 'Rose'});
    expect(f1c.persons, {p1});
    expect(f1c.house.value, isNotNull);

    final p2 = Person(id: '2', name: 'Brian', age: 55).init(personRepo);

    // persons has changed from [1] to [2]
    final f1d = familyRepo.deserialize({
      'id': '1',
      'surname': 'Rose',
      'persons': ['2']
    });
    // persons should be exactly equal to p2 (Brian)
    expect(f1d.persons, {p2});
    // without directly modifying p2, its family should be automatically updated
    expect(p2.family.value, f1d);
    // and by the same token, p1's family should now be null
    expect(p1.family.value, isNull);

    // relationships are explicitly set to null
    final f1e = familyRepo.deserialize(
        {'id': '1', 'surname': 'Rose', 'persons': null, 'house': null});
    expect(f1e.persons, isEmpty);
    expect(f1e.house.value, isNull);
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
      id: '1',
      surname: 'Jones',
      persons: HasMany.fromJson({
        '_': [personDataIds.map((d) => d.key).toList(), personRepo.manager]
      }),
      house: BelongsTo.fromJson({
        '_': [houseDataId.key, personRepo.manager]
      }),
    ).init(familyRepo);

    expect(family.house.key, isNotNull);
    expect(family.persons.keys, isNotEmpty);

    // (2) then load persons
    final p1 = Person(id: '1', name: 'z1', age: 23).init(personRepo);
    Person(id: '2', name: 'z2', age: 33).init(personRepo);

    // (3) assert two first are linked, third one null, house is null
    expect(family.persons.lookup(p1), p1);
    expect(family.persons.elementAt(0), isNotNull);
    expect(family.persons.elementAt(1), isNotNull);
    expect(family.persons.length, 2);
    expect(family.house.value, isNull);

    // // (4) load the last person and assert it exists now
    Person(id: '3', name: 'z3', age: 3).init(personRepo);
    expect(family.persons.elementAt(2).age, 3);

    // (5) load family and assert it exists now
    var house = House(id: '98', address: '21 Coconut Trail').init(houseRepo);
    // TODO should pass here too
    // expect(house.families, contains(family));
    expect(family.house.value.address, endsWith('Trail'));
    expect(house.families, contains(family));
  });

  test('relationship scenario #2', () {
    var repository = injection.locator<Repository<Family>>();
    var repositoryPerson = injection.locator<Repository<Person>>();

    final igor = Person(name: 'Igor', age: 33).init(repositoryPerson);
    var f1 = Family(surname: 'Kamchatka', persons: {igor}.asHasMany)
        .init(repository);
    // if Igor's family is NULL there's no way we can expect anything else
    // this is why setting an empty default relationship is recommended
    expect(f1.persons.first.family, isNull);

    var f1b = Family(
            surname: 'Kamchatka',
            persons:
                {Person(name: 'Igor', age: 33, family: BelongsTo())}.asHasMany)
        .init(repository);
    expect(f1b.persons.first.family.value.surname, 'Kamchatka');

    var f2 = Family(surname: 'Kamchatka', persons: HasMany()).init(repository);
    f2.persons.add(Person(name: 'Igor', age: 33, family: BelongsTo()));
    expect(f2.persons.first.family.value.surname, 'Kamchatka');

    var f3 = Family(
            surname: 'Kamchatka',
            house: House(address: 'Sakharova Prospekt, 19').asBelongsTo)
        .init(repository);
    expect(f3.house.value.families.first.surname, 'Kamchatka');

    var f4 = Family(surname: 'Kamchatka', house: BelongsTo()).init(repository);
    f4.house.value = House(address: 'Sakharova Prospekt, 19');
    expect(f4.house.value.families.first.surname, 'Kamchatka');
  });
}
