import 'package:flutter_data/flutter_data.dart';
import 'package:json_api/document.dart';
import 'package:test/test.dart';

import 'models/family.dart';
import 'models/house.dart';
import 'models/person.dart';
import 'setup.dart';

void main() async {
  setUpAll(setUpAllFn);
  tearDownAll(tearDownAllFn);

  test('constructor', () {
    var manager = injection.locator<DataManager>();
    var repo = injection.locator<Repository<Person>>();
    var person = Person(id: '1', name: "zzz", age: 7).init(repo);

    var rel = HasMany<Person>([], manager);
    expect(rel.length, 0);

    rel = HasMany<Person>([person], manager);
    expect(rel.first.dataId, manager.dataId<Person>('1'));
  });

  test('fromJson + equality', () {
    var manager = injection.locator<DataManager>();
    var person = Person(name: "Paul", age: 94);
    expect(
        HasMany<Person>.fromJson({
          'HasMany': HasMany<Person>([person], manager)
        }),
        HasMany<Person>([person], manager));
  });

  test('fromToMany with included', () async {
    var repo = injection.locator<Repository<Person>>();
    var manager = repo.manager;

    var sue =
        ResourceObject('people', '71', attributes: {'name': "Sue", 'age': 74});
    var helen = ResourceObject('people', '72',
        attributes: {'name': "Helen", 'age': 59});

    var rel = HasMany<Person>.fromToMany(
      ToMany([manager.dataId<Person>('72').identifierObject]),
      manager,
      included: [sue, helen],
    );

    expect(rel.first.dataId, manager.dataId<Person>('72'));

    // helen should be saved (cause it was in included)
    expect(await repo.findOne(helen.id, remote: false), isNotNull);

    // but sue shouldn't, as it wasn't referenced in any relationship
    expect(await repo.findOne(sue.id, remote: false), isNull);
  });

  test('fromKeys', () {
    var repo = injection.locator<Repository<Person>>();
    var manager = repo.manager;

    var rel =
        HasMany<Person>.fromKeys([manager.dataId<Person>('1').key], manager);
    var person = Person(id: '1', name: "zzz", age: 7).init(repo);

    expect(rel.first, person);
    expect(rel.first.dataId, manager.dataId<Person>('1'));
  });

  test('re-assign hasmany in mutable model', () {
    var familyRepo = injection.locator<Repository<Family>>();
    var personRepo = injection.locator<Repository<Person>>();

    var family = Family(surname: "Toraine").init(familyRepo);
    var person = Person(name: "Claire", age: 31).init(personRepo);
    family.persons = HasMany<Person>([person], personRepo.manager);

    expect(family.persons.first.dataId, person.dataId);
    expect(family.persons.debugOwner, isNull);
    family.init(familyRepo);
    expect(family.persons.debugOwner, isNotNull);
  });
}
