import 'package:flutter_data/flutter_data.dart';
import 'package:test/test.dart';

import '../../models/family.dart';
import '../../models/house.dart';
import '../../models/person.dart';
import '../../models/pet.dart';
import '../setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('throws if not initialized', () {
    expect(() {
      return Family(surname: 'Willis').save();
    }, throwsA(isA<AssertionError>()));
  });

  test('init', () async {
    var repo = injection.locator<Repository<Person>>();

    var family = Family(id: '55', surname: 'Kelley');
    var model =
        Person(id: '1', name: 'John', age: 27, family: family.asBelongsTo)
            .init(repo);

    // (1) it wires up the relationship (setOwnerInRelationship)
    expect(model.family.key, repo.manager.dataId<Family>('55').key);

    // (2) it saves the model locally
    expect(model, await repo.findOne(model.id));
  });

  // misc compatibility tests

  test('should reuse key', () {
    var manager = injection.locator<DataManager>();
    var repository = injection.locator<Repository<Person>>();

    // id-less person
    var p1 = Person(name: 'Frank', age: 20).init(repository);
    expect(repository.box.keys, contains(p1.key));

    // person with new id, reusing existing key
    manager.dataId<Person>('221', key: p1.key);
    var p2 = Person(id: '221', name: 'Frank2', age: 32).init(repository);
    expect(p1.key, p2.key);

    expect(repository.box.keys, contains(p2.key));
  });

  test('should resolve to the same key', () {
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);
    var dog2 = Dog(id: '2', name: 'Walker').init(dogRepo);
    expect(dog.key, dog2.key);
  });

  test('should work with subclasses', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var dogRepo = injection.locator<Repository<Dog>>();
    var dog = Dog(id: '2', name: 'Walker').init(dogRepo);

    var f = Family(surname: 'Walker', dogs: {dog}.asHasMany).init(familyRepo);
    expect(f.dogs.first.name, 'Walker');
  });

  test('data exception equality', () {
    expect(DataException(Exception('whatever'), 410),
        DataException(Exception('whatever'), 410));
    expect(DataException([Exception('whatever')], 410),
        isNot(DataException(Exception('whatever'), 410)));
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

    expect(family.house.dataId, isNotNull);
    expect(family.persons.dataIds, isNotEmpty);

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

// mutable id tests

// test('should remove "mutable" stray zebras', () async {
//   var manager = injection.locator<DataManager>();
//   var repository = injection.locator<Repository<Zebra>>();

//   // a reference for zebra id=772 has been created
//   var dataId = manager.dataId<Zebra>('772');

//   var taco = Zebra(id: null, name: 'Taco').init(repository);
//   // key(id=772) will be different to key(id=null)
//   expect(taco.key, isNot(dataId.key));
//   // zebra was saved with id=null
//   expect((await repository.findAll()).length, 1);

//   // if we assign an id=772 and re-initialize
//   taco.id = '772';
//   taco.init(repository);

//   // the original key (key(id=772)) will be found
//   expect(taco.key, dataId.key);
//   // and the stray zebra (id=null) will be removed
//   // so we only keep the record for id=772
//   expect((await repository.findAll()).length, 1);
//   expect(repository.localAdapter.findOne(taco.key), isNotNull);
// });

// test('re-save with mutable id', () async {
//   var repository = injection.locator<Repository<Zebra>>();
//   await repository.localAdapter.clear();
//   var z = Zebra(id: '779', name: 'Mercy').init(repository);
//   print(z.key);

//   // mimics what repository.deserialize() does internally
//   // deserialize with init (DataSupport) and immediately assign id
//   var _z = repository.localAdapter
//       .deserialize({'name': "Patsy"}).init(repository)
//         ..id = '779';
//   // then initialize again (z.key will be NEW, assigned to id=null)
//   z = _z.init(repository, key: z.key, save: true);

//   expect(repository.localAdapter.keys, [z.key]);
// });

// @DataRepository([])
// @JsonSerializable()
// class Zebra with DataSupportMixin<Zebra> {
//   String id;
//   String name;

//   Zebra({this.id, this.name});
//   factory Zebra.fromJson(Map<String, dynamic> json) => _$ZebraFromJson(json);
//   Map<String, dynamic> toJson() => _$ZebraToJson(this);
// }
